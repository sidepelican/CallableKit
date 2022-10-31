import CodableToTypeScript
import Foundation
import SwiftTypeReader
import TSCodeModule

class ImportMap {
    typealias Def = (typeName: TSIdentifier, fileName: String)
    init(defs: [Def]) {
        self.defs = defs
    }

    var defs: [Def] = []
    func insert(type: SType, file: String, generator: CodeGenerator) throws {
        let tsType = try generator.transpileTypeReference(type: type)
        defs.append((TSIdentifier(tsType.description), file))

        if try generator.hasTranspiledJSONType(type: type) {
            let tsJsonType = try generator.transpileTypeReferenceToJSON(type: type)
            defs.append((TSIdentifier(tsJsonType.description), file))

            if let tsDecodeFunc = try generator.generateDecodeFunction(type: type) {
                defs.append((TSIdentifier(tsDecodeFunc.name), file))
            }
        }
    }

    func file(for typeName: TSIdentifier) -> String? {
        defs.first(where: { $0.typeName == typeName })?.fileName
    }

    func typeNames(for file: String) -> [TSIdentifier] {
        defs.filter { $0.fileName == file }.map(\.typeName)
    }

    func importDecls(forTypes types: [TSIdentifier], for file: String) -> [String] {
        var filesTypesTable: [String: [TSIdentifier]] = [:]
        for type in types {
            guard let typefile = self.file(for: type), typefile != file else { continue }
            filesTypesTable[typefile, default: []].append(type)
        }

        return filesTypesTable.sorted(using: KeyPathComparator(\.key)).map { (file: String, types: [TSIdentifier]) in
            let file = file.replacingOccurrences(of: ".ts", with: "")
            let importSymbols = types
                .map(\.rawValue)
                .map { (s: String) in
                    // 名前空間つきの型名だった場合は名前空間の根本の単位でしかimportできないので調整する
                    if s.contains(".") {
                        return String(s.split(separator: ".")[0])
                    }
                    return s
                }
            return "import { \(Set(importSymbols).sorted().joined(separator: ", ")) } from \"./\(file).js\";"
        }
    }
}

struct GenerateNextClient {
    var srcDirectory: URL
    var dstDirectory: URL
    private let importMap = ImportMap(defs: [
        (TSIdentifier("IRawClient"), "common.gen.ts"),
        (TSIdentifier("identity"), "decode.gen.ts"),
        (TSIdentifier("OptionalField_decode"), "decode.gen.ts"),
        (TSIdentifier("Optional_decode"), "decode.gen.ts"),
        (TSIdentifier("Array_decode"), "decode.gen.ts"),
        (TSIdentifier("Dictionary_decode"), "decode.gen.ts"),
    ])

    private let typeMap: TypeMap = {
        var typeMapTable: [String: String] = TypeMap.defaultTable
        typeMapTable["URL"] = "string"
        typeMapTable["Date"] = "string"
        return TypeMap(table: typeMapTable) { typeSpecifier in
            if typeSpecifier.lastElement.name.hasSuffix("ID") {
                return "string"
            }
            return nil
        }
    }()

    private func generateCommon() -> String {
        """
export interface IRawClient {
  fetch(request: unknown, servicePath: string): Promise<unknown>
}
"""
    }

    private func processFile(
        generator: CodeGenerator,
        file: Generator.InputFile
    ) throws -> String? {
        let outputFile = Self.outputFilename(for: file.name)

        var codes: [String] = []
        var usedTypes: Set<TSIdentifier> = []

        for stype in file.module.types.compactMap(ServiceProtocolScanner.scan) {
            codes.append("""
export interface I\(stype.serviceName)Client {
\(try stype.functions.map { f in
    let res = try f.response.map { try generator.tsName(stype: $0.raw) } ?? .void
    return """
  \(f.name)(\(try f.request.map { "\($0.argName): \(try generator.tsJsonName(stype: $0.raw))" } ?? "")): Promise<\(res)>
""" }.joined(separator: "\n"))
}
""")

            let functionsDecls = try stype.functions.map { f in
                let res = try f.response.map { try generator.tsName(stype: $0.raw) } ?? .void

                let fetchExpr = "this.rawClient.fetch(\(f.request?.argName ?? "{}"), \"\(stype.serviceName)/\(f.name)\")"

                let blockBody: String
                if let sRes = f.response?.raw,
                   let decodeFunc = try generator.generateDecodeFunction(type: sRes)
                {
                    let jsonTsType = try generator.transpileTypeReferenceToJSON(type: sRes)
                    let decodeExpr = try generator.generateDecodeValueExpression(type: sRes, expr: .identifier("json"))

                    blockBody = """
    const json = await \(fetchExpr) as \(jsonTsType)
    return \(decodeExpr)
"""
                    // 使用した関数を記録
                    usedTypes.insert(TSIdentifier(decodeFunc.name))
                    usedTypes.formUnion(unwrapGenerics(typeName: TSIdentifier(jsonTsType.description)))
                    if case .call(let tsCallExpr) = decodeExpr {
                        usedTypes.formUnion(
                            tsCallExpr.arguments
                                .filter { $0.expr.description != "json" }
                                .map { $0.description }
                                .map { TSIdentifier($0) }
                        )
                    }
                } else {
                    blockBody = """
    return await \(fetchExpr) as \(res)
"""
                }

                return """
              async \(f.name)(\(try f.request.map { "\($0.argName): \(try generator.tsJsonName(stype: $0.raw))" } ?? "")): Promise<\(res)> {
            \(blockBody)
              }
            """ }.joined(separator: "\n")

            codes.append("""
class \(stype.serviceName)Client implements I\(stype.serviceName)Client {
  rawClient: IRawClient;

  constructor(rawClient: IRawClient) {
    this.rawClient = rawClient;
  }

\(functionsDecls)
}
""")
            codes.append("""
export const build\(stype.serviceName)Client = (raw: IRawClient): I\(stype.serviceName)Client => new \(stype.serviceName)Client(raw);
""")

            // 使用したっぽい型を記録
            usedTypes.formUnion(try stype.functions.flatMap({ f in
                [
                    TSIdentifier("IRawClient"),
                    try f.request.map { try generator.tsName(stype: $0.raw) },
                    try f.response.map { try generator.tsName(stype: $0.raw) },
                ].compactMap { $0 }.flatMap(unwrapGenerics(typeName:))
            }))
        }

        // Request・Response型定義の出力
        for stype in file.module.types {
            guard stype.struct != nil
                    || (stype.enum != nil && !stype.enum!.caseElements.isEmpty)
                    || stype.regular?.types.isEmpty == false
            else {
                continue
            }

            let tsCode = try generator.generateTypeDeclarationFile(type: stype)

            let dependencyScanner = DependencyScanner(
                knownNames: CodeGenerator.defaultKnownNames
                    .union(importMap.typeNames(for: outputFile).map(\.rawValue))
            )

            // 使用したっぽい型を記録
            usedTypes.formUnion(
                dependencyScanner.scan(code: tsCode).map { TSIdentifier($0) }
            )

            // 型定義とjson変換関数だけを抜き出し
            let tsDecls = tsCode.items
                .compactMap { item -> TSBlockItem? in
                    if case .import = item.decl {
                        return nil
                    }
                    return item
                }
                .map { $0.description.trimmingCharacters(in: .whitespacesAndNewlines) }
            codes.append(contentsOf: tsDecls)
        }

        if codes.isEmpty { return nil }

        // importが必要そうな型を調べてimport文を生成する
        let importNeededTypeNames = importMap.defs.map(\.typeName).filter { typeName in
            usedTypes.contains(where: { $0 == typeName })
        }
        if !importNeededTypeNames.isEmpty {
            let importDecls = importMap.importDecls(forTypes: importNeededTypeNames, for: outputFile)
            if !importDecls.isEmpty {
                codes.insert(importDecls.joined(separator: "\n"), at: 0)
            }
        }

        return codes.joined(separator: "\n\n") + "\n"
    }

    static func outputFilename(for file: String) -> String {
        URL(fileURLWithPath: file.replacingOccurrences(of: ".swift", with: ".gen.ts")).lastPathComponent
    }

    func run() throws {
        var g = Generator(srcDirectory: srcDirectory, dstDirectory: dstDirectory)
        g.isOutputFileName = { $0.hasSuffix(".gen.ts") }

        let generator = CodeGenerator(typeMap: typeMap)

        try g.run { input, write in
            let common = Generator.OutputFile(
                name: "common.gen.ts",
                content: generateCommon()
            )
            try write(file: common)

            let decoderHelper = Generator.OutputFile(
                name: "decode.gen.ts",
                content: generator.generateHelperLibrary().description
            )
            try write(file: decoderHelper)

            // 1st pass
            for inputFile in input.files {
                let outputFile = Self.outputFilename(for: inputFile.name)

                func walk(stype: SType) throws {
                    try importMap.insert(type: stype, file: outputFile, generator: generator)
                    for stype in stype.regular?.types ?? [] {
                        try walk(stype: stype)
                    }
                }

                for stype in inputFile.module.types {
                    try walk(stype: stype)
                }
            }

            // 2nd pass
            for inputFile in input.files {
                guard let generated = try processFile(generator: generator, file: inputFile) else { continue }
                let outputFile = Self.outputFilename(for: inputFile.name)
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}

extension CodeGenerator {
    fileprivate func tsName(stype: SType) throws -> TSIdentifier {
        let tsType = try transpileTypeReference(type: stype)
        return .init(tsType.description)
    }

    fileprivate func tsJsonName(stype: SType) throws -> TSIdentifier {
        let tsType = try transpileTypeReferenceToJSON(type: stype)
        return .init(tsType.description)
    }
}

fileprivate func unwrapGenerics(typeName: TSIdentifier) -> [TSIdentifier] {
    return typeName.rawValue
        .components(separatedBy: .whitespaces.union(.init(charactersIn: "<>,")))
        .filter { !$0.isEmpty }
        .map { TSIdentifier($0) }
}

enum _TSIdentifier {}
typealias TSIdentifier = UnitStringType<_TSIdentifier>

extension TSIdentifier {
    static var void: Self { .init("void") }
}
