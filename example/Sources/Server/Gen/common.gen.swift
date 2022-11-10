import Vapor

protocol VaporToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (Request) async -> Response
    where Req: Decodable & Sendable, Res: Encodable & Sendable
}

private struct _Empty: Codable, Sendable {}

extension VaporToServiceBridgeProtocol {
    func makeHandler<Service, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Res
    ) -> (Request) async -> Response
    where Res: Encodable & Sendable
    {
        makeHandler(serviceBuilder) { (serviceType: Service.Type) in
            { (service: Service) in
                { (_: _Empty) -> Res in
                    try await methodSelector(serviceType)(service)()
                }
            }
        }
    }

    func makeHandler<Service, Req>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Void
    ) -> (Request) async -> Response
    where Req: Decodable & Sendable
    {
        makeHandler(serviceBuilder) { (serviceType: Service.Type) in
            { (service: Service) in
                { (req: Req) -> _Empty in
                    try await methodSelector(serviceType)(service)(req)
                    return _Empty()
                }
            }
        }
    }

    func makeHandler<Service>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Void
    ) -> (Request) async -> Response
    {
        makeHandler(serviceBuilder) { (serviceType: Service.Type) in
            { (service: Service) in
                { (_: _Empty) -> _Empty in
                    try await methodSelector(serviceType)(service)()
                    return _Empty()
                }
            }
        }
    }
}
