import CodableToTypeScript
import Foundation
import SwiftTypeReader
import TypeScriptAST

fileprivate class ImportMap {
    typealias Def = (typeName: TSIdentifier, fileName: String)
    init(defs: [Def]) {
        self.defs = defs
    }

    var defs: [Def] = []
    func insert(type: any SType, file: String, generator: CodeGenerator) throws {
        guard let tsType = try generator.transpileTypeReference(type: type) as? TSIdentType else {
            return
        }

        let tsTypeName = TSIdentifier(tsType.name)
        if self.file(for: tsTypeName) != nil {
            throw MessageError("Duplicated type: \(tsTypeName). Using the same type name in multiple modules is not supported.")
        }

        defs.append((tsTypeName, file))

        if try generator.hasTranspiledJSONType(type: type) {
            if let tsJsonType = try generator.transpileTypeReferenceToJSON(type: type) as? TSIdentType {
                defs.append((TSIdentifier(tsJsonType.name), file))
            }

            if let type = type as? any NominalType,
               let tsDecodeFunc = try generator.generateDecodeFunction(type: type.nominalTypeDecl)
            {
                defs.append((TSIdentifier(tsDecodeFunc.name), file))
            }
        }
    }

    func file(for typeName: TSIdentifier) -> String? {
        defs.first(where: { $0.typeName == typeName })?.fileName
    }
}

extension GenericTypeDecl {
    func walk(body: (any GenericTypeDecl) throws -> Void) rethrows {
        try body(self)

        if let self = self as? any NominalTypeDecl {
            for type in self.types {
                try type.walk(body: body)
            }
        }
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
        return TypeMap(table: typeMapTable) { typeRepr in
            if let typeRepr = typeRepr as? IdentTypeRepr,
               let lastElement = typeRepr.elements.last,
               lastElement.name.hasSuffix("ID")
            {
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
                modifiers: [.export],
                name: "I\(stype.serviceName)Client",
                body: TSBlockStmt(try stype.functions.map { (f) in
                    let res: any TSType = try f.response.map { try generator.transpileTypeReference(type: $0.raw) } ?? TSIdentType.void
                    let method = TSMethodDecl(
                        name: f.name,
                        params: try f.request.map {
                            [.init(name: $0.argName, type: try generator.transpileTypeReferenceToJSON(type: $0.raw))]
                        } ?? [],
                        result: TSIdentType.promise(res)
                    )
                    return method
                })
            )
            codes.append(clientInterface)

            let functionsDecls: [TSMethodDecl] = try stype.functions.map { f in
                let res: TSType = try f.response.map { try generator.transpileTypeReference(type: $0.raw) } ?? TSIdentType.void

                let fetchExpr: any TSExpr = TSCallExpr(
                    callee: TSMemberExpr(
                        base: TSMemberExpr(
                            base: TSIdentExpr.this,
                            name: TSIdentExpr("rawClient")
                        ),
                        name: TSIdentExpr("fetch")
                    ),
                    args: [
                        f.request.map { TSIdentExpr($0.argName) } ?? TSObjectExpr([]),
                        TSStringLiteralExpr("\(stype.serviceName)/\(f.name)")
                    ]
                )

                let blockBody: [any ASTNode]
                if let sRes = f.response?.raw,
                   try generator.hasTranspiledJSONType(type: sRes)
                {
                    let jsonTsType = try generator.transpileTypeReferenceToJSON(type: sRes)
                    let decodeExpr = try generator.generateDecodeValueExpression(type: sRes, expr: TSIdentExpr("json"))

                    blockBody = [
                        TSVarDecl(
                            kind: .const, name: "json",
                            initializer: TSAwaitExpr(
                                TSAsExpr(fetchExpr, jsonTsType)
                            )
                        ),
                        TSReturnStmt(decodeExpr)
                    ]
                } else {
                    blockBody = [
                        TSReturnStmt(
                            TSAwaitExpr(
                                TSAsExpr(fetchExpr, res)
                            )
                        )
                    ]
                }

                return TSMethodDecl(
                    modifiers: [.async],
                    name: f.name,
                    params: try f.request.map {
                        [.init(
                            name: $0.argName,
                            type: try generator.transpileTypeReferenceToJSON(type: $0.raw)
                        )]
                    } ?? [],
                    result: TSIdentType.promise(res),
                    body: TSBlockStmt(blockBody)
                )
            }

            let clientClass = TSClassDecl(
                name: "\(stype.serviceName)Client",
                implements: [TSIdentType(clientInterface.name)],
                body: TSBlockStmt([
                    TSFieldDecl(
                        name: "rawClient", type: TSIdentType("IRawClient")
                    ),
                    TSMethodDecl(
                        name: "constructor",
                        params: [.init(name: "rawClient", type: TSIdentType("IRawClient"))],
                        result: nil,
                        body: TSBlockStmt([
                            TSAssignExpr(
                                TSMemberExpr(base: TSIdentExpr.this, name: TSIdentExpr("rawClient")),
                                TSIdentExpr("rawClient")
                            )
                        ])
                    )
                ] + functionsDecls)
            )
            codes.append(clientClass)

            codes.append(TSVarDecl(
                modifiers: [.export],
                kind: .const, name: "build\(stype.serviceName)Client",
                initializer: TSClosureExpr(
                    params: [.init(name: "raw", type: TSIdentType("IRawClient"))],
                    result: TSIdentType(clientInterface.name),
                    body: TSNewExpr(
                        callee: TSIdentType("\(stype.serviceName)Client"),
                        args: [TSIdentExpr("raw")]
                    )
                )
            ))
        }

        // Request・Response型定義の出力
        for stype in file.types {
            guard stype is StructDecl
                    || ((stype as? EnumDecl)?.caseElements.isEmpty ?? true) == false
                    || stype.types.isEmpty == false
            else {
                continue
            }

            // 型定義とjson変換関数だけを抜き出し
            try stype.walk { (stype) in
                codes += try generator.generateTypeOwnDeclarations(type: stype).decls
            }
        }

        if codes.isEmpty { return nil }

        let code = TSSourceFile(codes)

        let deps = code.scanDependency().map { TSIdentifier($0) }

        var nameMap: [String: [TSIdentifier]] = [:]
        for dep in deps {
            if let file = importMap.file(for: dep) {
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
            return TSImportDecl(names: names.map(\.rawValue), from: file)
        }

        code.elements.insert(contentsOf: importDecls, at: 0)

        return code.print()
    }

    private func outputFilename(for file: Generator.InputFile) -> String {
        let name = URL(fileURLWithPath: file.file.lastPathComponent.replacingOccurrences(of: ".swift", with: ".gen.ts")).lastPathComponent
        if file.module.name != definitionModule {
            return "\(file.module.name)/\(name)"
        } else {
            return name
        }
    }

    func run() throws {
        var g = Generator(definitionModule: definitionModule, srcDirectory: srcDirectory, dstDirectory: dstDirectory, dependencies: dependencies)
        g.isOutputFileName = { $0.hasSuffix(".gen.ts") }

        try g.run { input, write in
            let generator = CodeGenerator(context: input.context, typeMap: typeMap)

            let common = Generator.OutputFile(
                name: "common.gen.ts",
                content: generateCommon()
            )
            try write(file: common)

            let decoderHelper = Generator.OutputFile(
                name: "decode.gen.ts",
                content: generator.generateHelperLibrary().print()
            )
            try write(file: decoderHelper)

            // 1st pass
            for inputFile in input.files {
                let outputFile = outputFilename(for: inputFile)

                for stype in inputFile.types {
                    try stype.walk { (stype) in
                        try importMap.insert(type: stype.declaredInterfaceType, file: outputFile, generator: generator)
                    }
                }
            }

            // 2nd pass
            for inputFile in input.files {
                guard let generated = try processFile(generator: generator, file: inputFile) else { continue }
                let outputFile = outputFilename(for: inputFile)
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}

extension CodeGenerator {
    fileprivate func tsName(stype: any SType) throws -> TSIdentifier {
        let tsType = try transpileTypeReference(type: stype)
        return .init(tsType.print())
    }

    fileprivate func tsJsonName(stype: any SType) throws -> TSIdentifier {
        let tsType = try transpileTypeReferenceToJSON(type: stype)
        return .init(tsType.print())
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
