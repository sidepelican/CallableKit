import Vapor

protocol RawRequestHandler {
    func makeHandler<Req: Decodable & Sendable, Res: Encodable & Sendable, Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service, Req) async throws -> (Res)
    ) -> (Request) async -> Response
}

private struct Empty: Codable, Sendable {}

extension RawRequestHandler {
    func makeHandler<Res: Encodable & Sendable, Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service) async throws -> (Res)
    ) -> (Request) async -> Response {
        makeHandler(makeService, { (s: Service, r: Empty) in
            try await callMethod(s)
        })
    }

    func makeHandler<Req: Decodable & Sendable, Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service, Req) async throws -> Void
    ) -> (Request) async -> Response {
        makeHandler(makeService, { (s: Service, r: Req) -> Empty in
            try await callMethod(s, r)
            return Empty()
        })
    }

    func makeHandler<Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service) async throws -> Void
    ) -> (Request) async -> Response {
        makeHandler(makeService, { (s: Service, r: Empty) -> Empty in
            try await callMethod(s)
            return Empty()
        })
    }
}
