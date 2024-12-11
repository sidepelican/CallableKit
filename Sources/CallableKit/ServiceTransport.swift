public protocol ServiceTransport<Service> {
    associatedtype Service

    func register<Request: Decodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Void
    )

    func register<Response: Encodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> () async throws -> Response
    )

    func register(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> () async throws -> Void
    )

    func register<Request: Decodable, Response: Encodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Response
    )
}

fileprivate struct _Empty: Codable, Sendable {
}

extension ServiceTransport {
    public func register<Request: Decodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Void
    ) {
        register(path: path) { (serviceType) in
            { (service: Service) in
                { (request: Request) -> _Empty in
                    try await methodSelector(serviceType)(service)(request)
                    return _Empty()
                }
            }
        }
    }

    public func register<Response: Encodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> () async throws -> Response
    ) {
        register(path: path) { (serviceType) in
            { (service: Service) in
                { () -> Response in
                    return try await methodSelector(serviceType)(service)()
                }
            }
        }
    }

    public func register(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> () async throws -> Void
    ) {
        register(path: path) { (serviceType) in
            { (service: Service) in
                { () -> Void in
                    try await methodSelector(serviceType)(service)()
                }
            }
        }
    }
}
