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
    var `extension`: String = "gen.ts"

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
        let string = TSIdentType.string
        var elements: [any ASTNode] = [
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
                .field(TSFieldDecl(name: "headers", isOptional: true, type: TSFunctionType(params: [], result: TSUnionType([
                    TSIdentType("Headers"),
                    TSIdentType("Promise", genericArgs: [TSIdentType("Headers")]),
                ])))),
                .field(TSFieldDecl(name: "mapResponseError", isOptional: true, type: TSFunctionType(params: [.init(name: "e", type: TSIdentType("FetchHTTPStubResponseError"))], result: TSIdentType.error))),
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
        ]

        elements += [
            DateConvertDecls.encodeDecl(),
            DateConvertDecls.decodeDecl()
        ]

        return TSSourceFile(elements)
    }

    private func processFile(
        generator: CodeGenerator,
        swift: SourceFile,
        ts: PackageEntry
    ) throws {
        var insertionIndex: Int = ts.source.elements.lastIndex(where: { $0 is TSImportDecl }) ?? 0

        for stype in swift.types.compactMap(ServiceProtocolScanner.scan) {
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
            ts.source.elements.insert(clientInterface, at: insertionIndex)
            insertionIndex += 1

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

            let bindDecl = TSVarDecl(
                modifiers: [.export],
                kind: .const, name: "bind\(stype.serviceName)",
                initializer: TSClosureExpr(
                    params: [.init(name: "stub", type: TSIdentType("IStubClient"))],
                    result: TSIdentType(clientInterface.name),
                    body: TSBlockStmt([
                        TSReturnStmt(TSObjectExpr(functionsDecls.map(TSObjectExpr.Field.method)))
                    ])
                )
            )

            ts.source.elements.insert(bindDecl, at: insertionIndex)
            insertionIndex += 1
        }
    }

    func run() throws {
        let g = Generator(
            definitionModule: definitionModule,
            srcDirectory: srcDirectory,
            dstDirectory: dstDirectory,
            dependencies: dependencies,
            isOutputFileName: { [ext = self.extension] (name) in
                name.hasSuffix(ext)
            }
        )

        try g.run { input, write in
            var symbols = SymbolTable(
                standardLibrarySymbols: SymbolTable.standardLibrarySymbols.union([
                    "Response",
                    "Object",
                    "JSON",
                    "URL",
                    "fetch",
                ])
            )

            let commonLib = PackageEntry(
                file: dstDirectory.appendingPathComponent("CallableKit.\(`extension`)"),
                source: generateCommon()
            )

            symbols.add(source: commonLib.source, file: commonLib.file)

            let package = PackageGenerator(
                context: input.context,
                typeConverterProvider: TypeConverterProvider(typeMap: typeMap),
                symbols: symbols,
                importFileExtension: nextjs ? .none : .js,
                outputDirectory: dstDirectory,
                typeScriptExtension: `extension`
            )
            package.didGenerateEntry = { [unowned package] (source, entry) in
                try self.processFile(
                    generator: package.codeGenerator,
                    swift: source,
                    ts: entry
                )
            }

            var modules = input.context.modules
            modules.removeAll { $0 === input.context.swiftModule }
            var entries = try package.generate(modules: modules)
            entries.append(commonLib)

            for entry in entries {
                try write(file: toOutputFile(entry: entry))
            }
        }
    }

    private func toOutputFile(entry: PackageEntry) -> Generator.OutputFile {
        return Generator.OutputFile(
            name: entry.file.relativePath(from: dstDirectory).relativePath,
            content: entry.source.print()
        )
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
