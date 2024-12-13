import CallableKit
import Foundation
import Hummingbird

public struct HummingbirdTransport<Router: RouterMethods, Service>: ServiceTransport {
    public init(router: Router, serviceBuilder: @escaping @Sendable (Request, Router.Context) async throws -> Service) {
        self.router = router
        self.serviceBuilder = serviceBuilder
    }
    
    public var router: Router
    public var serviceBuilder: @Sendable (Request, Router.Context) async throws -> Service

    public func register<Request: Decodable, Response: Encodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Response
    ) {
        router.post(RouterPath(path)) { [serviceBuilder] request, context in
            let serviceRequest = try await makeDecoder().decode(Request.self, from: request, context: context)
            let service = try await serviceBuilder(request, context)
            let serviceResponse = try await methodSelector(Service.self)(service)(serviceRequest)
            var response = try makeEncoder().encode(serviceResponse, from: request, context: context)
            response.headers[.cacheControl] = "no-store"
            return response
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
