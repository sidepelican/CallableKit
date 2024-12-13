public protocol ServiceTransport<Service> {
    associatedtype Service

    func register<Request: Decodable & Sendable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Void
    )

    func register<Response: Encodable & Sendable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> () async throws -> Response
    )

    func register(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> () async throws -> Void
    )

    func register<Request: Decodable & Sendable, Response: Encodable & Sendable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Response
    )
}

extension ServiceTransport {
    @inlinable public func register<Request: Decodable & Sendable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Void
    ) {
        register(path: path) { (serviceType) in
            { (service: Service) in
                { (request: Request) -> CallableKitEmpty in
                    try await methodSelector(serviceType)(service)(request)
                    return CallableKitEmpty()
                }
            }
        }
    }

    @inlinable public func register<Response: Encodable & Sendable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> () async throws -> Response
    ) {
        register(path: path) { (serviceType) in
            { (service: Service) in
                { (_: CallableKitEmpty) -> Response in
                    return try await methodSelector(serviceType)(service)()
                }
            }
        }
    }

    @inlinable public func register(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> () async throws -> Void
    ) {
        register(path: path) { (serviceType) in
            { (service: Service) in
                { (_: CallableKitEmpty) -> CallableKitEmpty  in
                    try await methodSelector(serviceType)(service)()
                    return CallableKitEmpty()
                }
            }
        }
    }
}
