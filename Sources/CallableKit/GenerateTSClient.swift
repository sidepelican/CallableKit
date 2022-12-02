import CodableToTypeScript
import Foundation
import SwiftTypeReader
import TypeScriptAST

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

fileprivate struct SourceEntry {
    var file: String
    var source: TSSourceFile
}

struct GenerateTSClient {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]
    var nextjs: Bool

    private let typeMap: TypeMap = {
        var typeMapTable: [String: TypeMap.Entry] = TypeMap.defaultTable
        typeMapTable["URL"] = .init(name: "string")
//        typeMapTable["Date"] = .init(name: "string", decode: "Date_decode", encode: "Date_encode")
        return TypeMap(table: typeMapTable) { type in
            let typeRepr = type.toTypeRepr(containsModule: false)
            if let typeRepr = typeRepr as? IdentTypeRepr,
               let lastElement = typeRepr.elements.last,
               lastElement.name.hasSuffix("ID")
            {
                return .init(name: "string")
            }
            return nil
        }
    }()

    private func generateCommon() -> TSSourceFile {
        return TSSourceFile([
            TSInterfaceDecl(modifiers: [.export], name: "IRawClient", body: TSBlockStmt([
                TSMethodDecl(
                    name: "fetch", params: [
                        .init(name: "request", type: TSIdentType.unknown),
                        .init(name: "servicePath", type: TSIdentType.string)
                    ],
                    result: TSIdentType.promise(TSIdentType.unknown)
                )
            ]))
        ])
    }

    private func processFile(
        generator: CodeGenerator,
        file: Generator.InputFile
    ) throws -> TSSourceFile? {
        var codes: [TSDecl] = []

        for stype in file.types.compactMap(ServiceProtocolScanner.scan) {
            let clientInterface = TSInterfaceDecl(
                modifiers: [.export],
                name: "I\(stype.serviceName)Client",
                body: TSBlockStmt(try stype.functions.map { (f) in
                    let res: any TSType = try f.response.map { try generator.converter(for: $0.raw).type(for: .entity) } ?? TSIdentType.void
                    let method = TSMethodDecl(
                        name: f.name,
                        params: try f.request.map {
                            [.init(name: $0.argName, type: try generator.converter(for: $0.raw).type(for: .entity))]
                        } ?? [],
                        result: TSIdentType.promise(res)
                    )
                    return method
                })
            )
            codes.append(clientInterface)

            let functionsDecls: [TSMethodDecl] = try stype.functions.map { f in
                let res: TSType = try f.response.map { try generator.converter(for: $0.raw).type(for: .entity) } ?? TSIdentType.void

                let reqExpr: any TSExpr
                if let sReq = f.request?.raw,
                   try generator.converter(for: sReq).hasJSONType() {
                    let encodeExpr = try generator.converter(for: sReq).callEncode(entity: TSIdentExpr(f.request!.argName))
                    reqExpr = encodeExpr
                } else {
                    reqExpr = f.request.map { TSIdentExpr($0.argName) } ?? TSObjectExpr([])
                }

                let fetchExpr: any TSExpr = TSCallExpr(
                    callee: TSMemberExpr(
                        base: TSIdentExpr("raw"),
                        name: TSIdentExpr("fetch")
                    ),
                    args: [
                        reqExpr,
                        TSStringLiteralExpr("\(stype.serviceName)/\(f.name)")
                    ]
                )

                let blockBody: [any ASTNode]
                if let sRes = f.response?.raw,
                   try generator.converter(for: sRes).hasJSONType()
                {
                    let jsonTsType = try generator.converter(for: sRes).type(for: .json)
                    let decodeExpr = try generator.converter(for: sRes).callDecode(json: TSIdentExpr("json"))

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
                            type: try generator.converter(for: $0.raw).type(for: .entity)
                        )]
                    } ?? [],
                    result: TSIdentType.promise(res),
                    body: TSBlockStmt(blockBody)
                )
            }

            codes.append(TSVarDecl(
                modifiers: [.export],
                kind: .const, name: "build\(stype.serviceName)Client",
                initializer: TSClosureExpr(
                    params: [.init(name: "raw", type: TSIdentType("IRawClient"))],
                    result: TSIdentType(clientInterface.name),
                    body: TSBlockStmt([
                        TSReturnStmt(TSObjectExpr(functionsDecls.map(TSObjectExpr.Field.method)))
                    ])
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
                codes += try generator.converter(for: stype).ownDecls().decls
            }
        }

        if codes.isEmpty { return nil }

        return TSSourceFile(codes)
    }

    private func outputFilename(for file: Generator.InputFile) -> String {
        let name = URL(fileURLWithPath: file.file.lastPathComponent.replacingOccurrences(of: ".swift", with: ".gen.ts")).lastPathComponent
        if file.module.name != definitionModule {
            return "\(file.module.name)/\(name)"
        } else {
            return name
        }
    }

    private func fixImport(decl: TSImportDecl) {
        var file = decl.from
        if file.hasSuffix(".ts") {
            if nextjs {
                file = "./" + (file as NSString).deletingPathExtension
            } else {
                file = "./" + (file as NSString).deletingPathExtension + ".js"
            }
        }
        decl.from = file
    }

    func run() throws {
        var g = Generator(definitionModule: definitionModule, srcDirectory: srcDirectory, dstDirectory: dstDirectory, dependencies: dependencies)
        g.isOutputFileName = { $0.hasSuffix(".gen.ts") }

        var sources: [SourceEntry] = []

        try g.run { input, write in
            let generator = CodeGenerator(
                context: input.context,
                typeConverterProvider: TypeConverterProvider(typeMap: typeMap) { (generator, stype) in
                    let repr = stype.toTypeRepr(containsModule: false)
                    if let ident = repr.asIdent,
                       let element = ident.elements.last,
                       element.name == "Date"
                    {
                        return DateConverter(generator: generator, swiftType: stype)
                    }
                    return nil
                }
            )

            // generate all ts codes
            sources.append(.init(
                file: "common.gen.ts",
                source: generateCommon()
            ))
            let decodeLib = generator.generateHelperLibrary()
            decodeLib.elements += try [DateConverter.encodeDecl(), DateConverter.decodeDecl()].compactMap({ $0 })
            sources.append(.init(
                file: "decode.gen.ts",
                source: decodeLib
            ))
            for inputFile in input.files {
                guard let generated = try processFile(generator: generator, file: inputFile) else { continue }
                let outputFile = outputFilename(for: inputFile)
                sources.append(
                    .init(
                        file: outputFile,
                        source: generated
                    )
                )
            }

            // collect all symbols
            var symbolTable = SymbolTable()
            for source in sources {
                for symbol in source.source.memberDeclaredNames {
                    if let _ = symbolTable.find(symbol){
                        throw MessageError("Duplicated symbol: \(symbol). Using the same name in multiple modules is not supported.")
                    }
                    symbolTable.add(symbol: symbol, file: .file(source.file))
                }
            }

            // generate imports
            for source in sources {
                let imports = try source.source.buildAutoImportDecls(symbolTable: symbolTable)
                for `import` in imports {
                    fixImport(decl: `import`)
                }
                source.source.replaceImportDecls(imports)
            }

            // write
            for source in sources {
                try write(file: .init(
                    name: source.file,
                    content: source.source.print()
                ))
            }
        }
    }
}

fileprivate struct DateConverter: TypeConverter {
    var generator: CodeGenerator
    var swiftType: any SType

    func name(for target: GenerationTarget) throws -> String {
        switch target {
        case .entity: return "Date"
        case .json: return "string"
        }
    }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        return nil
    }

    func hasDecode() throws -> Bool {
        return true
    }

    static func decodeName() throws -> String {
        return "Date_decode"
    }
    func decodeName() throws -> String { try Self.decodeName() }

    static func decodeDecl() throws -> TSFunctionDecl? {
        return TSFunctionDecl(
            modifiers: [.export],
            name: try decodeName(),
            params: [ .init(name: "iso", type: TSIdentType("string"))],
            body: TSBlockStmt([
                TSReturnStmt(TSNewExpr(callee: TSIdentType("Date"), args: [TSIdentExpr("iso")]))
            ])
        )
    }
    func decodeDecl() throws -> TSFunctionDecl? { try Self.decodeDecl() }

    func hasEncode() throws -> Bool {
        return true
    }

    static func encodeName() throws -> String {
        return "Date_encode"
    }
    func encodeName() throws -> String { try Self.encodeName() }

    static func encodeDecl() throws -> TSFunctionDecl? {
        return TSFunctionDecl(
            modifiers: [.export],
            name: try encodeName(),
            params: [.init(name: "d", type: TSIdentType("Date"))],
            body: TSBlockStmt([
                TSReturnStmt(TSCallExpr(callee: TSMemberExpr(base: TSIdentExpr("d"), name: TSIdentExpr("toISOString")), args: []))
            ])
        )
    }
    func encodeDecl() throws -> TSFunctionDecl? { try Self.encodeDecl() }
}
