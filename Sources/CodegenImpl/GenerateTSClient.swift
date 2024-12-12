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
                    if let rawValueType = stype.asStruct?.rawValueType(requiresTransferringRawValueType: false) {
                        var transferringRawValue = false
                        if let comment = stype.asNominal?.nominalTypeDecl.comment,
                           let match = comment.firstMatch(of: /@CallableKit\((.+?)\)/) {
                            let options = extractOptions(match.output.1)
                            if options["transferringRawValue"] == "true" {
                                transferringRawValue = true
                            }
                        }

                        return try? FlatRawRepresentableConverter(
                            generator: generator,
                            swiftType: stype,
                            rawValueType: rawValueType,
                            transferringRawValue: transferringRawValue
                        )
                    }

                    return nil
                }),
                symbols: symbols,
                importFileExtension: nextjs ? .none : .js,
                outputDirectory: dstDirectory,
                typeScriptExtension: `extension`
            )
            package.didConvertSource = { [unowned package] (source, entry) in
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

// TS側で.rawValueを経由せず直接RawValueで扱えるようにするコンバータ
struct FlatRawRepresentableConverter: TypeConverter {
    init(
        generator: CodeGenerator,
        swiftType: any SType,
        rawValueType substituted: any SType,
        transferringRawValue: Bool
    ) throws {
        self.generator = generator
        self.swiftType = swiftType
        self.rawValueType = try generator.converter(for: substituted)
        self.isTransferringRawValueType = swiftType.asStruct?.rawValueType(requiresTransferringRawValueType: true) != nil
        || transferringRawValue
    }

    var generator: CodeGenerator
    var swiftType: any SType
    var rawValueType: any TypeConverter
    var isTransferringRawValueType: Bool

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
            if isTransferringRawValueType {
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

    func hasDecode() -> Bool {
        return !isTransferringRawValueType
    }

    func decodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try decodeSignature() else { return nil }
        assert(!isTransferringRawValueType)

        let value = try rawValueType.callDecode(json: TSMemberExpr(base: TSIdentExpr("json"), name: "rawValue"))
        let field = try rawValueType.valueToField(value: value, for: .entity)

        decl.body.elements.append(
            TSReturnStmt(TSAsExpr(field, try type(for: .entity)))
        )
        return decl
    }

    func hasEncode() -> Bool {
        return !isTransferringRawValueType
    }

    func encodeDecl() throws -> TSFunctionDecl? {
        guard let decl = try encodeSignature() else { return nil }
        assert(!isTransferringRawValueType)

        let field = try rawValueType.callEncodeField(entity: TSIdentExpr("entity"))
        let value = try rawValueType.fieldToValue(field: field, for: .json)
        decl.body.elements.append(
            TSReturnStmt(TSObjectExpr([
                .named(name: "rawValue", value: value),
            ]))
        )
        return decl
    }
}

fileprivate func extractOptions(_ parametersString: some StringProtocol) -> [Substring: Substring] {
    let keyAndValues = parametersString
        .split(separator: ",")
        .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        .compactMap({ $0.wholeMatch(of: /(\w+)\s*:\s*(.*)/) })
        .map({ ($0.output.1, $0.output.2) })
    return [Substring: Substring](uniqueKeysWithValues: keyAndValues)
}
