import CallableKit
import Vapor

public struct VaporTransport<Service>: ServiceTransport {
    public init(router: any RoutesBuilder, serviceBuilder: @escaping @Sendable (Request) async throws -> Service) {
        self.router = router
        self.serviceBuilder = serviceBuilder
    }
    
    public var router: any RoutesBuilder
    public var serviceBuilder: @Sendable (Request) async throws -> Service

    public func register<Request: Decodable, Response: Encodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Response
    ) {
        router.post(path.pathComponents) { [serviceBuilder] request in
            guard let body = request.body.data else {
                throw Abort(.badRequest, reason: "no body")
            }
            let serviceRequest = try makeDecoder().decode(Request.self, from: body)
            let service = try await serviceBuilder(request)
            let serviceResponse = try await methodSelector(Service.self)(service)(serviceRequest)

            var headers = HTTPHeaders()
            headers.cacheControl = .init(noStore: true)
            var buffer = request.byteBufferAllocator.buffer(capacity: 0)
            try makeEncoder().encode(serviceResponse, to: &buffer, headers: &headers, userInfo: [:])

            return Vapor.Response(status: .ok, headers: headers, body: .init(buffer: buffer, byteBufferAllocator: request.byteBufferAllocator))
        }
    }
}

private func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    return decoder
}

private func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    return encoder
}
