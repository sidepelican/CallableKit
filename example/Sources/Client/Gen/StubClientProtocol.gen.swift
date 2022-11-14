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
