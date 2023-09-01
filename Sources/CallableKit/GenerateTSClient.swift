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
        typeMapTable["UUID"] = .identity(name: "string")
        return TypeMap(table: typeMapTable)
    }()

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
                typeConverterProvider: TypeConverterProvider(typeMap: typeMap, customProvider: { (generator, stype) in
                    if let `struct` = stype.asStruct?.decl {
                        guard `struct`.inheritedTypes.contains(where: { (t) in t.asProtocol?.name == "RawRepresentable" }) else {
                            return nil
                        }

                        let rawValueType: (any SType)?
                        if let alias = `struct`.findType(name: "RawValue")?.asTypeAlias {
                            rawValueType = alias.underlyingType
                        } else if let property = `struct`.find(name: "rawValue")?.asVar {
                            rawValueType = property.interfaceType
                        } else {
                            rawValueType = nil
                        }
                        guard let rawValueType else { return nil }
                        return try? FlatRawRepresentableConverter(generator: generator, swiftType: stype, rawValueType: rawValueType)
                    }

                    return nil
                }),
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
            var entries = try package.generate(modules: modules).entries
            entries.removeAll(where: { $0.source.elements.isEmpty })
            entries.append(commonLib)

            for entry in entries {
                try write(file: toOutputFile(entry: entry))
            }
        }
    }

    private func toOutputFile(entry: PackageEntry) -> Generator.OutputFile {
        return Generator.OutputFile(
            name: URLs.relativePath(to: entry.file, from: dstDirectory).relativePath,
            content: entry.print()
        )
    }
}

struct FlatRawRepresentableConverter: TypeConverter {
    init(
        generator: CodeGenerator,
        swiftType: any SType,
        rawValueType raw: any SType
    ) throws {
        let map = swiftType.contextSubstitutionMap()
        let substituted = raw.subst(map: map)

        self.generator = generator
        self.swiftType = swiftType
        self.rawValueType = try generator.converter(for: substituted)

        self.doesRawRepresentableCoding = substituted.isRawRepresentableCodingType()
        let rawValueIsArchetype = raw.asGenericParam.map {
            map.signature.params.contains($0)
        } ?? false
        self.needsSpecialize = rawValueIsArchetype
    }

    var generator: CodeGenerator
    var swiftType: any SType
    var rawValueType: any TypeConverter
    var doesRawRepresentableCoding: Bool
    var needsSpecialize: Bool

//    func type(for target: GenerationTarget) throws -> any TSType {
//        if case .json = target, needsSpecialize {
//            return TSUnionType([
////                try generator.converter(for: rawValueType.swiftType).type(for: target),
//                try `default`.type(for: target),
////                TSCustomType(text: "never /*  */"),
//            ])
//        }
//
//        return try `default`.type(for: target)
//    }

    func typeDecl(for target: GenerationTarget) throws -> TSTypeDecl? {
        let name = try self.name(for: target)
        let genericParams: [TSTypeParameterNode] = try self.genericParams().map {
            .init(try $0.name(for: target))
        }
        let type = try rawValueType.type(for: target)
        switch target {
        case .entity:
            let tag = try generator.tagRecord(
                name: name,
                genericArgs: try self.genericParams().map { (param) in
                    TSIdentType(try param.name(for: .entity))
                }
            )

            return TSTypeDecl(
                modifiers: [.export],
                name: name,
                genericParams: genericParams,
                type: TSIntersectionType([type, tag])
            )
        case .json:
            if doesRawRepresentableCoding {
                return nil
            }
            return TSTypeDecl(
                modifiers: [.export],
                name: name,
                genericParams: genericParams,
                type: TSObjectType([
                    .field(.init(name: "rawValue", type: type))
                ])
            )
        }
    }

    func decodePresence() throws -> CodecPresence {
        return doesRawRepresentableCoding ? .identity : .required
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try decodeSignature() else { return nil }
        assert(!doesRawRepresentableCoding)

        let value = try rawValueType.callDecode(json: TSMemberExpr(base: TSIdentExpr("json"), name: "rawValue"))
        let field = try rawValueType.valueToField(value: value, for: .entity)

        decl.body.elements.append(
            TSReturnStmt(TSAsExpr(field, try type(for: .entity)))
        )
        return decl
    }

    func callDecode(json: any TSExpr) throws -> any TSExpr {
        if needsSpecialize {
            let rawValue = doesRawRepresentableCoding ? json : TSMemberExpr(base: json, name: "rawValue")
            let value = try rawValueType.callDecodeField(json: rawValue)
            let field = try rawValueType.valueToField(value: value, for: .entity)
            return TSAsExpr(field, try type(for: .entity))
        }
        return try `default`.callDecode(json: json)
    }

    func encodePresence() throws -> CodecPresence {
        return doesRawRepresentableCoding ? .identity : .required
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try encodeSignature() else { return nil }
        assert(!doesRawRepresentableCoding)

        let field = try rawValueType.callEncodeField(entity: TSIdentExpr("entity"))
        let value = try rawValueType.fieldToValue(field: field, for: .json)
        decl.body.elements.append(
            TSReturnStmt(TSObjectExpr([
                .named(name: "rawValue", value: value),
            ]))
        )
        return decl
    }

    func callEncode(entity: any TSExpr) throws -> TSExpr {
        if needsSpecialize {
            let field = try rawValueType.callEncodeField(entity: entity)
            let value = try rawValueType.fieldToValue(field: field, for: .json)
            if doesRawRepresentableCoding {
                return value
            } else {
                return TSObjectExpr([
                    .named(name: "rawValue", value: value),
                ])
            }
        }
        return try `default`.callEncode(entity: entity)
    }
}
