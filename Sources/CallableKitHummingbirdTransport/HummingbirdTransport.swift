import CallableKit
import Hummingbird

public struct HummingbirdTransport<Router: RouterMethods, Service>: ServiceTransport {
    public init(router: Router, serviceBuilder: @escaping @Sendable (Request, Router.Context) -> Service) {
        self.router = router
        self.serviceBuilder = serviceBuilder
    }
    
    public var router: Router
    public var serviceBuilder: @Sendable (Request, Router.Context) -> Service

    public func register<Request: Decodable, Response: Encodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Response
    ) {
        router.post(RouterPath(path)) { [serviceBuilder] request, context in
            let serviceRequest = try await context.requestDecoder.decode(Request.self, from: request, context: context)
            let service = serviceBuilder(request, context)
            let serviceResponse = try await methodSelector(Service.self)(service)(serviceRequest)
            return try context.responseEncoder.encode(serviceResponse, from: request, context: context)
        }
    }
}
