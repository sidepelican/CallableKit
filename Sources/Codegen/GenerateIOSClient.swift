import Foundation
import SwiftTypeReader

struct GenerateIOSClient {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL

    private func generateStubClient() -> String {
        """
public protocol StubClientProtocol: Sendable {
    func send<Req: Encodable, Res: Decodable>(
        path: String,
        request: Req,
        responseType: Res.Type
    ) async throws -> Res

    func send<Req: Encodable>(
        path: String,
        request: Req
    ) async throws
}

fileprivate struct Empty: Codable {}

extension StubClientProtocol {
    public func send<Req: Encodable, Res: Decodable>(
        path: String,
        request: Req
    ) async throws -> Res {
        try await send(path: path, request: request, responseType: Res.self)
    }

    public func send<Res: Decodable>(
        path: String
    ) async throws -> Res {
        try await send(path: path, request: Empty(), responseType: Res.self)
    }

    public func send<Req: Encodable>(
        path: String,
        request: Req
    ) async throws {
        _ = try await send(path: path, request: request, responseType: Empty.self)
    }

    public func send(
        path: String
    ) async throws {
        _ = try await send(path: path, request: Empty(), responseType: Empty.self)
    }
}

"""
    }

    private func processFile(module: Module) throws -> String? {
        var stubs: [String] = []
        for stype in module.types.compactMap(ServiceProtocolScanner.scan) {
            stubs.append("""
public struct \(stype.serviceName)ServiceStub: \(stype.name), Sendable {
    private let client: StubClientProtocol
    public init(client: StubClientProtocol) {
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

""")
        }
        if stubs.isEmpty { return nil }

        return """
import \(definitionModule)

\(stubs.joined())
"""
    }

    func run() throws {
        var g = Generator(srcDirectory: srcDirectory, dstDirectory: dstDirectory)
        g.isOutputFileName = { $0.hasSuffix(".gen.swift") }

        try g.run { input, write in
            try write(file: .init(
                name: "StubClientProtocol.gen.swift",
                content: generateStubClient()
            ))

            for inputFile in input.files {
                guard let generated = try processFile(module: inputFile.module) else { continue }
                let outputFile = URL(fileURLWithPath: inputFile.name.replacingOccurrences(of: ".swift", with: ".gen.swift")).lastPathComponent
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}
