import Foundation
import SwiftTypeReader

struct GenerateSwiftClient {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]
    
    private func generateStubClient() -> String {
        """
public protocol StubClientProtocol: Sendable {
    func send<Req: Encodable & Sendable, Res: Decodable & Sendable>(
        path: String,
        request: Req,
        responseType: Res.Type
    ) async throws -> Res
}

private struct _Empty: Codable {}

extension StubClientProtocol {
    public func send<Req: Encodable & Sendable, Res: Decodable & Sendable>(
        path: String,
        request: Req
    ) async throws -> Res {
        try await send(path: path, request: request, responseType: Res.self)
    }

    public func send<Req: Encodable & Sendable>(
        path: String,
        request: Req
    ) async throws {
        _ = try await send(path: path, request: request, responseType: _Empty.self)
    }

    public func send<Res: Decodable & Sendable>(
        path: String
    ) async throws -> Res {
        try await send(path: path, request: _Empty(), responseType: Res.self)
    }

    public func send(
        path: String
    ) async throws {
        _ = try await send(path: path, request: _Empty(), responseType: _Empty.self)
    }
}

"""
    }

    private func processFile(file: Generator.InputFile) throws -> String? {
        var stubs: [String] = []
        for stype in file.types.compactMap(ServiceProtocolScanner.scan) {
            let stubTypeName = "\(stype.serviceName)ServiceStub"
            stubs.append("""
public struct \(stubTypeName)<C: StubClientProtocol>: \(stype.name), Sendable {
    private let client: C
    public init(client: C) {
        self.client = client
    }

\(stype.functions.map { f in
    let retVal = f.response.map { " -> \($0.typeName)" } ?? ""
    return """
    public func \(f.name)(\(f.request.map { "\($0.argName): \($0.typeName)" } ?? "")) async throws\(retVal) {
        return try await client.send(path: "\(stype.serviceName)/\(f.name)"\(f.request.map { ", request: \($0.argName)" } ??  ""))
    }
""" }.joined(separator: "\n"))
}

extension StubClientProtocol {
    public var \(stype.serviceName.lowercased()): \(stubTypeName)<Self> {
        \(stubTypeName)(client: self)
    }
}

""")
        }
        if stubs.isEmpty { return nil }

        let imports: String = Set([definitionModule] + file.imports.map(\.name))
            .sorted()
            .map({ "import \($0)" })
            .joined(separator: "\n")

        return """
\(imports)

\(stubs.joined())
"""
    }

    func run() throws {
        var g = Generator(definitionModule: definitionModule, srcDirectory: srcDirectory, dstDirectory: dstDirectory, dependencies: dependencies)
        g.isOutputFileName = { $0.hasSuffix(".gen.swift") }

        try g.run { input, write in
            try write(file: .init(
                name: "StubClientProtocol.gen.swift",
                content: generateStubClient()
            ))

            for inputFile in input.files {
                guard let generated = try processFile(file: inputFile) else { continue }
                let outputFile = URL(fileURLWithPath: inputFile.path.lastPathComponent.replacingOccurrences(of: ".swift", with: ".gen.swift")).lastPathComponent
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}
