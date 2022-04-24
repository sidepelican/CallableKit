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
