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
    func insert(type: SType, file: String, typeMap: TypeMap) throws {
        let name = try typeMap.tsName(stype: type)
        // enumの場合は特別にDecode用関数も追加
        if type.enum != nil {
            defs.append((TSIdentifier(name.rawValue + "Decode"), file))
        }
        defs.append((name, file))
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
            return "import { \(Set(importSymbols).sorted().joined(separator: ", ")) } from \"./\(file)\";"
        }
    }
}

struct GenerateNextClient {
    var srcDirectory: URL
    var dstDirectory: URL
    private let importMap = ImportMap(defs: [
        (TSIdentifier("IRawClient"), "common.gen.ts"),
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

    private func processFile(file: Generator.InputFile) throws -> String? {
        let outputFile = Self.outputFilename(for: file.name)

        var codes: [String] = []
        var usedTypes: Set<TSIdentifier> = []

        for stype in file.module.types.compactMap(ServiceProtocolScanner.scan) {
            codes.append("""
export interface I\(stype.serviceName)Client {
\(try stype.functions.map { f in
    let res = try f.response.map { try typeMap.tsName(stype: $0.raw) } ?? .void
    return """
  \(f.name)(\(try f.request.map { "\($0.argName): \(try typeMap.tsName(stype: $0.raw))" } ?? "")): Promise<\(res)>
""" }.joined(separator: "\n"))
}
""")

            let functionsDecls = try stype.functions.map { f in
                let outputType = try f.raw.outputType()
                let res = try f.response.map { try typeMap.tsName(stype: $0.raw) } ?? .void

                if outputType?.enum != nil {
                    usedTypes.insert(TSIdentifier("\(outputType!.name)Decode")) // 使用したっぽい関数を記録
                }

                return """
              async \(f.name)(\(try f.request.map { "\($0.argName): \(try typeMap.tsName(stype: $0.raw))" } ?? "")): Promise<\(res)> {
            \(outputType?.enum != nil
              ? """
                const json = await this.rawClient.fetch(\(f.request?.argName ?? "{}"), "\(stype.serviceName)/\(f.name)") as \(res)
                return \(outputType!.name)Decode(json)
            """
              : """
                return await this.rawClient.fetch(\(f.request?.argName ?? "{}"), "\(stype.serviceName)/\(f.name)") as \(res)
            """)
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
                    try f.request.map { try typeMap.tsName(stype: $0.raw) },
                    try f.response.map { try typeMap.tsName(stype: $0.raw) },
                ].compactMap { $0 }.flatMap(unwrapGenerics(typeName:))
            }))
        }

        for stype in file.module.types {
            guard stype.struct != nil
                    || (stype.enum != nil && !stype.enum!.caseElements.isEmpty)
                    || stype.regular?.types.isEmpty == false
            else {
                continue
            }

            let tsCode = try CodeGenerator(
                typeMap: typeMap,
                standardTypes: CodeGenerator.defaultStandardTypes
                    .union(importMap.typeNames(for: outputFile).map(\.rawValue))
            ).generateTypeDeclarationFile(type: stype)

            // 使用したっぽい型を記録
            usedTypes.formUnion(
                tsCode.decls.compactMap {
                    if case .typeDecl(let v) = $0 { return v } else { return nil }
                }
                    .flatMap { (tsTypeDecl: TSTypeDecl) in
                        findTypes(in: tsTypeDecl.type)
                    }
            )

            // 型定義とjson変換関数だけを抜き出し
            let tsDecls = tsCode.decls.filter {
                if case .importDecl = $0 { return false } else { return true }
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

        try g.run { input, write in
            let common = Generator.OutputFile(
                name: "common.gen.ts",
                content: generateCommon()
            )
            try write(file: common)

            // 1st pass
            for inputFile in input.files {
                let outputFile = Self.outputFilename(for: inputFile.name)
                for stype in inputFile.module.types.flatMap({ [$0] + ($0.regular?.types ?? []) }) {
                    try importMap.insert(type: stype, file: outputFile, typeMap: typeMap)
                }
            }

            // 2nd pass
            for inputFile in input.files {
                guard let generated = try processFile(file: inputFile) else { continue }
                let outputFile = Self.outputFilename(for: inputFile.name)
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}

extension TypeMap {
    fileprivate func tsName(stype: SType) throws -> TSIdentifier {
        let tsType = try CodeGenerator(typeMap: self).transpileTypeReference(type: stype)
        var name = tsType.description
        if name.hasSuffix("JSON") {
            name = String(name.dropLast(4))
        } else if name.hasSuffix(">") {
            name = name.replacingOccurrences(of: "JSON", with: "") // CodableResultJSON<foo, bar> など、Genericな場合はJSONがまちまちに出現しうるので雑に消す
        }
        return TSIdentifier(name)
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

fileprivate func findTypes(in tsType: TSType) -> [TSIdentifier] {
    let typenames: [TSIdentifier]
    switch tsType {
    case .array(let array):
        typenames = findTypes(in: array.element)
    case .dictionary(let dictionary):
        typenames = findTypes(in: dictionary.element)
    case .named(let named):
        typenames = [TSIdentifier(named.description)]
    case .nested(let nested):
        typenames = [TSIdentifier(nested.description)]
    case .record(let record):
        typenames = record.fields.flatMap { findTypes(in: $0.type) }
    case .stringLiteral:
        typenames = []
    case .union(let union):
        typenames = union.items.flatMap { findTypes(in: $0) }
    }
    return typenames.flatMap(unwrapGenerics(typeName:))
}
