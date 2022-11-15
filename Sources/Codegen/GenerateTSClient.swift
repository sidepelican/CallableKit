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
}

struct GenerateTSClient {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]
    var nextjs: Bool

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
        var codes: [TSDecl] = []

        for stype in file.types.compactMap(ServiceProtocolScanner.scan) {
            let clientInterface = TSInterfaceDecl(
                name: "I\(stype.serviceName)Client",
                decls: try stype.functions.map { (f) in
                    let res: TSType = try f.response.map { try generator.transpileTypeReference(type: $0.raw) } ?? .named("void")
                    let method = TSMethodDecl(
                        name: f.name,
                        parameters: try f.request.map {
                            [.init(name: $0.argName, type: try generator.transpileTypeReferenceToJSON(type: $0.raw))]
                        } ?? [],
                        returnType: .named("Promise", genericArguments: [.init(res)]),
                        items: nil
                    )
                    return .method(method)
                }
            )
            codes.append(.interface(clientInterface))

            let functionsDecls: [TSMethodDecl] = try stype.functions.map { f in
                let res: TSType = try f.response.map { try generator.transpileTypeReference(type: $0.raw) } ?? .named("void")

                let fetchExpr: TSExpr = .call(
                    callee: .memberAccess(
                        base: .memberAccess(
                            base: .identifier("this"),
                            name: "rawClient"
                        ),
                        name: "fetch"
                    ),
                    arguments: [
                        .init(f.request.map { .identifier($0.argName) } ?? .object([])),
                        .init(.stringLiteral("\(stype.serviceName)/\(f.name)"))
                    ]
                )

                let blockBody: [TSBlockItem]
                if let sRes = f.response?.raw,
                   try generator.hasTranspiledJSONType(type: sRes)
                {
                    let jsonTsType = try generator.transpileTypeReferenceToJSON(type: sRes)
                    let decodeExpr = try generator.generateDecodeValueExpression(type: sRes, expr: .identifier("json"))

                    blockBody = [
                        .decl(.var(
                            kind: "const", name: "json",
                            initializer: .prefixOperator(
                                "await",
                                .infixOperator(fetchExpr, "as", .type(jsonTsType))
                            )
                        )),
                        .stmt(.return(decodeExpr))
                    ]
                } else {
                    blockBody = [
                        .stmt(.return(
                            .prefixOperator(
                                "await",
                                .infixOperator(fetchExpr, "as", .type(res))
                            )
                        ))
                    ]
                }

                return TSMethodDecl(
                    modifiers: ["async"],
                    name: f.name,
                    parameters: try f.request.map {
                        [.init(
                            name: $0.argName,
                            type: try generator.transpileTypeReferenceToJSON(type: $0.raw)
                        ) ]
                    } ?? [],
                    returnType: .named("Promise", genericArguments: [.init(res)]),
                    items: blockBody
                )
            }

            let clientClass = TSClassDecl(
                export: false,
                name: "\(stype.serviceName)Client",
                implements: [.named(clientInterface.name)],
                items: [
                    .decl(.field(TSFieldDecl(
                        name: "rawClient", type: .named("IRawClient"))
                    )),
                    .decl(.method(TSMethodDecl(
                        name: "constructor",
                        parameters: [.init(name: "rawClient", type: .named("IRawClient"))],
                        returnType: nil,
                        items: [
                            .expr(.infixOperator(
                                .memberAccess(base: .identifier("this"), name: "rawClient"),
                                "=", .identifier("rawClient")
                            ))
                        ]
                    )))
                ] + functionsDecls.map { .decl(.method($0)) }
            )
            codes.append(.class(clientClass))

            codes.append(.var(
                export: true,
                kind: "const", name: "build\(stype.serviceName)Client",
                initializer: .closure(
                    parameters: [.init(name: "raw", type: .named("IRawClient"))],
                    returnType: .named(clientInterface.name),
                    body: .expr(.new(
                        callee: .identifier("\(stype.serviceName)Client"),
                        arguments: [.init(.identifier("raw"))]
                    ))
                )
            ))
        }

        // Request・Response型定義の出力
        for stype in file.types {
            guard stype.struct != nil
                    || (stype.enum != nil && !stype.enum!.caseElements.isEmpty)
                    || stype.regular?.types.isEmpty == false
            else {
                continue
            }

            // 型定義とjson変換関数だけを抜き出し
            func walk(stype: SType) throws {
                codes += try generator.generateTypeOwnDeclarations(type: stype).decls
                for stype in stype.regular?.types ?? [] {
                    try walk(stype: stype)
                }
            }
            try walk(stype: stype)
        }

        if codes.isEmpty { return nil }

        var code = TSCode(codes.map { .decl($0) })

        let deps = DependencyScanner().scan(code: code)

        var nameMap: [String: [String]] = [:]
        for dep in deps {
            if let file = importMap.file(for: .init(dep)) {
                nameMap[file, default: []].append(dep)
            }
        }

        let files = nameMap.keys.sorted()

        let importDecls: [TSImportDecl] = files.map { (file) in
            let names = nameMap[file] ?? []
            var file = file
            if file.hasSuffix(".ts") {
                if nextjs {
                    file = "./" + (file as NSString).deletingPathExtension
                } else {
                    file = "./" + (file as NSString).deletingPathExtension + ".js"
                }
            }
            return TSImportDecl(names: names, from: file)
        }

        code.items.insert(contentsOf: importDecls.map { .decl(.import($0)) }, at: 0)

        return code.description
    }

    static func outputFilename(for file: URL) -> String {
        URL(fileURLWithPath: file.lastPathComponent.replacingOccurrences(of: ".swift", with: ".gen.ts")).lastPathComponent
    }

    func run() throws {
        var g = Generator(definitionModule: definitionModule, srcDirectory: srcDirectory, dstDirectory: dstDirectory, dependencies: dependencies)
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

                for stype in inputFile.types {
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
