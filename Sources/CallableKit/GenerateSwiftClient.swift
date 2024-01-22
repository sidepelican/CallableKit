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
        request: Req
    ) async throws -> Res

    func send<Req: Encodable & Sendable>(
        path: String,
        request: Req
    ) async throws

    func send<Res: Decodable & Sendable>(
        path: String
    ) async throws -> Res

    func send(
        path: String
    ) async throws
}

private struct _Empty: Codable {}

extension StubClientProtocol {
    public func send<Req: Encodable & Sendable, Res: Decodable & Sendable>(
        path: String,
        request: Req
    ) async throws -> Res {
        try await send(path: path, request: request)
    }

    public func send<Req: Encodable & Sendable>(
        path: String,
        request: Req
    ) async throws {
        _ = try await send(path: path, request: request) as _Empty
    }

    public func send<Res: Decodable & Sendable>(
        path: String
    ) async throws -> Res {
        try await send(path: path, request: _Empty())
    }

    public func send(
        path: String
    ) async throws {
        _ = try await send(path: path, request: _Empty())
    }
}

"""
    }

    private func generateFoundationHTTPStubClient() -> String {
#"""
#if !DISABLE_FOUNDATION_NETWORKING
import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

enum FoundationHTTPStubClientError: Error {
    case unexpectedState
    case unexpectedStatusCode(_ code: Int)
}

struct FoundationHTTPStubResponseError: Error, CustomStringConvertible {
    var path: String
    var body: Data
    var request: URLRequest
    var response: HTTPURLResponse
    var description: String {
        "ResponseError. path=\(path), status=\(response.statusCode)"
    }
}

final class FoundationHTTPStubClient: StubClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let onWillSendRequest: (@Sendable (inout URLRequest) async throws -> Void)?
    private let mapResponseError: (@Sendable (FoundationHTTPStubResponseError) throws -> Never)?

    init(
        baseURL: URL,
        onWillSendRequest: (@Sendable (inout URLRequest) async throws -> Void)? = nil,
        mapResponseError: (@Sendable (FoundationHTTPStubResponseError) throws -> Never)? = nil
    ) {
        self.baseURL = baseURL
        session = .init(configuration: .ephemeral)
        self.onWillSendRequest = onWillSendRequest
        self.mapResponseError = mapResponseError
    }

    func send<Req: Encodable, Res: Decodable>(
        path: String,
        request: Req
    ) async throws -> Res {
        var q = URLRequest(url: baseURL.appendingPathComponent(path))
        q.httpMethod = "POST"

        q.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try makeEncoder().encode(request)
        q.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        q.httpBody = body

        if let onWillSendRequest = onWillSendRequest {
            try await onWillSendRequest(&q)
        }
        let (data, urlResponse) = try await session.data(for: q)
        return try handleResponse(data: data, response: urlResponse, path: path, request: q)
    }

    private func handleResponse<Res: Decodable>(
        data: Data,
        response: URLResponse,
        path: String,
        request: URLRequest
    ) throws -> Res {
        guard let urlResponse = response as? HTTPURLResponse else {
            throw FoundationHTTPStubClientError.unexpectedState
        }

        if 200...299 ~= urlResponse.statusCode {
            return try makeDecoder().decode(Res.self, from: data)
        } else if 400...599 ~= urlResponse.statusCode {
            let error = FoundationHTTPStubResponseError(
                path: path,
                body: data,
                request: request,
                response: urlResponse
            )
            if let mapResponseError = mapResponseError {
                try mapResponseError(error)
            } else {
                throw error
            }
        } else {
            throw FoundationHTTPStubClientError.unexpectedStatusCode(urlResponse.statusCode)
        }
    }
}

private func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    return decoder
}

private func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    return encoder
}

#if canImport(FoundationNetworking)
private class TaskBox: @unchecked Sendable {
    var task: URLSessionTask?
}

extension URLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let taskBox = TaskBox()
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                let task = dataTask(with: request) { data, response, error in
                    guard let data, let response else {
                        return continuation.resume(
                            throwing: error ?? URLError(.badServerResponse)
                        )
                    }
                    return continuation.resume(returning: (data, response))
                }
                taskBox.task = task
                task.resume()
            }
        }, onCancel: {
            taskBox.task?.cancel()
        })
    }
}
#endif
#endif

"""#
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
    public func \(f.name)(\(f.request.map { "\($0.argOuterName.map({ "\($0) " }) ?? "")\($0.argName): \($0.typeName)" } ?? "")) async throws\(retVal) {
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

        let imports: String = Set([definitionModule] + file.imports.map(\.moduleName))
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
            try write(file: .init(
                name: "FoundationHTTPStubClient.gen.swift",
                content: generateFoundationHTTPStubClient()
            ))

            for inputFile in input.files {
                guard let generated = try processFile(file: inputFile) else { continue }
                let outputFile = URL(fileURLWithPath: inputFile.file.lastPathComponent.replacingOccurrences(of: ".swift", with: ".gen.swift")).lastPathComponent
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}
