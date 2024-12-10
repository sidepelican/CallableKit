import CallableKit
import Vapor

public struct VaporTransport<Router: RoutesBuilder, Service>: ServiceTransport {
    public init(router: Router, serviceBuilder: @escaping @Sendable (Request) -> Service) {
        self.router = router
        self.serviceBuilder = serviceBuilder
    }
    
    public var router: Router
    public var serviceBuilder: @Sendable (Request) -> Service

    public func register<Request: Decodable, Response: Encodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Response
    ) {
        router.post(PathComponent(stringLiteral: path)) { [serviceBuilder] request in
            let serviceRequest = try request.content.decode(Request.self)
            let service = serviceBuilder(request)
            let serviceResponse = try await methodSelector(Service.self)(service)(serviceRequest)

            var buffer = request.byteBufferAllocator.buffer(capacity: 0)
            var headers = HTTPHeaders()
            let encoder = try ContentConfiguration.global.requireEncoder(for: .json)
            try encoder.encode(serviceResponse, to: &buffer, headers: &headers)

            return Vapor.Response(status: .ok, headers: headers, body: .init(buffer: buffer))
        }
    }
}
