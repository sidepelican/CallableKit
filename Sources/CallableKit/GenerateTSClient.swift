import CodableToTypeScript
import Foundation
import SwiftTypeReader
import TypeScriptAST

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
        typeMapTable["URL"] = .identity(name: "string")
        typeMapTable["Date"] = .coding(entityType: "Date", jsonType: "number", decode: "Date_decode", encode: "Date_encode")
        return TypeMap(table: typeMapTable) { type -> TypeMap.Entry? in
            if let type = type.asNominal,
               let _ = type.nominalTypeDecl.rawValueType()
            {
                return nil
            }

            let typeRepr = type.toTypeRepr(containsModule: false)
            if let typeRepr = typeRepr as? IdentTypeRepr,
               let lastElement = typeRepr.elements.last,
               lastElement.name.hasSuffix("ID")
            {
                return .identity(name: "string")
            }
            return nil
        }
    }()

    private func generateCommon() -> TSSourceFile {
        let string = TSIdentType("string")
        return TSSourceFile([
            TSInterfaceDecl(modifiers: [.export], name: "IStubClient", body: TSBlockStmt([
                TSMethodDecl(
                    name: "send", params: [
                        .init(name: "request", type: TSIdentType.unknown),
                        .init(name: "servicePath", type: TSIdentType.string)
                    ],
                    result: TSIdentType.promise(TSIdentType.unknown)
                )
            ])),
            TSTypeDecl(modifiers: [.export], name: "Headers", type: TSIdentType("Record", genericArgs: [string, string])),
            TSTypeDecl(modifiers: [.export], name: "StubClientOptions", type: TSObjectType([
                .init(name: "headers", isOptional: true, type: TSFunctionType(params: [], result: TSUnionType([
                    TSIdentType("Headers"),
                    TSIdentType("Promise", genericArgs: [TSIdentType("Headers")]),
                ]))),
                .init(name: "mapResponseError", isOptional: true, type: TSFunctionType(params: [.init(name: "e", type: TSIdentType("FetchHTTPStubResponseError"))], result: TSIdentType.error)),
            ])),
            TSClassDecl(modifiers: [.export], name: "FetchHTTPStubResponseError", extends: TSIdentType("Error"), body: TSBlockStmt([
                TSFieldDecl(modifiers: [.readonly], name: "path", type: string),
                TSFieldDecl(modifiers: [.readonly], name: "response", type: TSIdentType("Response")),
                TSMethodDecl(name: "constructor", params: [.init(name: "path", type: string), .init(name: "response", type: TSIdentType("Response"))], body: TSBlockStmt([
                    TSCallExpr(callee: TSIdentExpr("super"), args: [TSTemplateLiteralExpr("ResponseError. path=\(ident: "path"), status=\(TSMemberExpr(base: TSIdentExpr("response"), name: "status"))")]),
                    TSAssignExpr(TSMemberExpr(base: TSIdentExpr.this, name: "path"), TSIdentExpr("path")),
                    TSAssignExpr(TSMemberExpr(base: TSIdentExpr.this, name: "response"), TSIdentExpr("response")),
                ])),
            ])),
            TSVarDecl(
                modifiers: [.export],
                kind: .const,
                name: "createStubClient",
                initializer: TSClosureExpr(
                    params: [
                        .init(name: "baseURL", type: string),
                        .init(name: "options", isOptional: true, type: TSIdentType("StubClientOptions")),
                    ],
                    result: TSIdentType("IStubClient"),
                    body: TSBlockStmt([
                        TSReturnStmt(TSObjectExpr([
                            .method(TSMethodDecl(modifiers: [.async], name: "send", params: [.init(name: "request"), .init(name: "servicePath")], body: TSBlockStmt([
                                TSVarDecl(kind: .let, name: "optionHeaders", type: TSIdentType("Headers"), initializer: TSObjectExpr([])),
                                TSIfStmt(condition: TSMemberExpr(base: TSIdentExpr("options"), isOptional: true, name: "headers"), then: TSBlockStmt([
                                    TSAssignExpr(
                                        TSIdentExpr("optionHeaders"),
                                        TSAwaitExpr(TSCallExpr(callee: TSMemberExpr(base: TSIdentExpr("options"), name: "headers"), args: []))
                                    ),
                                ])),

                                TSVarDecl(kind: .const, name: "res", initializer: TSAwaitExpr(TSCallExpr(callee: TSIdentExpr("fetch"), args: [
                                    TSCallExpr(callee: TSMemberExpr(
                                        base: TSNewExpr(callee: TSIdentType("URL"), args: [
                                            TSIdentExpr("servicePath"),
                                            TSIdentExpr("baseURL"),
                                        ]),
                                        name: "toString"
                                    ), args: []),
                                    TSObjectExpr([
                                        .named(name: "method", value: TSStringLiteralExpr("POST")),
                                        .named(name: "headers", value: TSObjectExpr([
                                            .named(name: "Content-Type", value: TSStringLiteralExpr("application/json")),
                                            .destructuring(value: TSIdentExpr("optionHeaders")),
                                        ])),
                                        .named(name: "body", value: TSCallExpr(callee: TSMemberExpr(base: TSIdentExpr("JSON"), name: "stringify"), args: [TSIdentExpr("request")])),
                                    ]),
                                ]))),
                                TSIfStmt(condition: TSPrefixOperatorExpr("!", TSMemberExpr(base: TSIdentExpr("res"), name: "ok")), then: TSBlockStmt([
                                    TSVarDecl(kind: .const, name: "e", initializer: TSNewExpr(callee: TSIdentType("FetchHTTPStubResponseError"), args: [
                                        TSIdentExpr("servicePath"),
                                        TSIdentExpr("res"),
                                    ])),
                                    TSIfStmt(
                                        condition: TSMemberExpr(base: TSIdentExpr("options"), isOptional: true, name: "mapResponseError"),
                                        then: TSBlockStmt([
                                            TSThrowStmt(TSCallExpr(callee: TSMemberExpr(base: TSIdentExpr("options"), name: "mapResponseError"), args: [TSIdentExpr("e")])),
                                        ]),
                                        else: TSBlockStmt([
                                            TSThrowStmt(TSIdentExpr("e")),
                                        ])
                                    ),
                                ])),
                                TSReturnStmt(TSAwaitExpr(TSCallExpr(callee: TSMemberExpr(base: TSIdentExpr("res"), name: "json"), args: []))),
                            ])))
                        ]))
                    ])
                )
            )
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
                   try generator.converter(for: sReq).hasEncode() {
                    let encodeExpr = try generator.converter(for: sReq).callEncode(entity: TSIdentExpr(f.request!.argName))
                    reqExpr = encodeExpr
                } else {
                    reqExpr = f.request.map { TSIdentExpr($0.argName) } ?? TSObjectExpr([])
                }

                let fetchExpr: any TSExpr = TSCallExpr(
                    callee: TSMemberExpr(
                        base: TSIdentExpr("stub"),
                        name: "send"
                    ),
                    args: [
                        reqExpr,
                        TSStringLiteralExpr("\(stype.serviceName)/\(f.name)")
                    ]
                )

                let blockBody: [any ASTNode]
                if let sRes = f.response?.raw,
                   try generator.converter(for: sRes).hasDecode()
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
                kind: .const, name: "bind\(stype.serviceName)",
                initializer: TSClosureExpr(
                    params: [.init(name: "stub", type: TSIdentType("IStubClient"))],
                    result: TSIdentType(clientInterface.name),
                    body: TSBlockStmt([
                        TSReturnStmt(TSObjectExpr(functionsDecls.map(TSObjectExpr.Field.method)))
                    ])
                )
            ))
        }

        // Request・Response型定義の出力

        for stype in file.types {
            // 型定義とjson変換関数だけを抜き出し
            try stype.walkTypeDecls { (stype) in
                guard stype is StructDecl
                        || stype is EnumDecl
                        || stype is TypeAliasDecl
                else {
                    return false
                }

                let converter = try generator.converter(for: stype.declaredInterfaceType)
                codes += try converter.ownDecls().decls
                return true
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
                typeConverterProvider: TypeConverterProvider(typeMap: typeMap)
            )

            // generate all ts codes
            sources.append(.init(
                file: "common.gen.ts",
                source: generateCommon()
            ))
            let decodeLib = generator.generateHelperLibrary()
            decodeLib.elements.append(DateConvertDecls.encodeDecl())
            decodeLib.elements.append(DateConvertDecls.decodeDecl())
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
            var symbolTable = SymbolTable(
                standardLibrarySymbols: SymbolTable.standardLibrarySymbols.union([
                    "Response",
                    "Object",
                    "JSON",
                    "URL",
                    "fetch",
                ])
            )
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

fileprivate enum DateConvertDecls {
    static func decodeDecl() -> TSFunctionDecl {
        TSFunctionDecl(
            modifiers: [.export],
            name: "Date_decode",
            params: [ .init(name: "unixMilli", type: TSIdentType("number"))],
            body: TSBlockStmt([
                TSReturnStmt(TSNewExpr(callee: TSIdentType("Date"), args: [TSIdentExpr("unixMilli")]))
            ])
        )
    }

    static func encodeDecl() -> TSFunctionDecl {
        TSFunctionDecl(
            modifiers: [.export],
            name: "Date_encode",
            params: [.init(name: "d", type: TSIdentType("Date"))],
            body: TSBlockStmt([
                TSReturnStmt(TSCallExpr(callee: TSMemberExpr(base: TSIdentExpr("d"), name: "getTime"), args: []))
            ])
        )
    }
}
