import Foundation
import TypeScriptAST

extension GenerateTSClient {
    func generateCommon() -> TSSourceFile {
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
            DateConvertDecls.decodeDecl(),
        ]

        return TSSourceFile(elements)
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
