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
