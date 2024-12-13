public protocol StubClientProtocol: Sendable {
    func send<Request: Encodable & Sendable, Response: Decodable & Sendable>(
        path: String,
        request: Request
    ) async throws -> Response

    func send<Request: Encodable & Sendable>(
        path: String,
        request: Request
    ) async throws

    func send<Response: Decodable & Sendable>(
        path: String
    ) async throws -> Response

    func send(
        path: String
    ) async throws
}

extension StubClientProtocol {
    public func send<Request: Encodable & Sendable, Response: Decodable & Sendable>(
        path: String,
        request: Request
    ) async throws -> Response {
        try await send(path: path, request: request)
    }

    public func send<Request: Encodable & Sendable>(
        path: String,
        request: Request
    ) async throws {
        _ = try await send(path: path, request: request) as CallableKitEmpty
    }

    public func send<Response: Decodable & Sendable>(
        path: String
    ) async throws -> Response {
        try await send(path: path, request: CallableKitEmpty())
    }

    public func send(
        path: String
    ) async throws {
        _ = try await send(path: path, request: CallableKitEmpty())
    }
}
