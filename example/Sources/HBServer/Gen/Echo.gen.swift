import APIDefinition
import Hummingbird

func configureEchoService(
    bridge: some HBToServiceBridgeProtocol = .default,
    builder serviceBuilder: @escaping @Sendable (Request) async throws -> some EchoServiceProtocol,
    router: some RouterMethods
) {
    router.post("Echo/hello", use: bridge.makeHandler(serviceBuilder, { $0.hello }))
    router.post("Echo/tommorow", use: bridge.makeHandler(serviceBuilder, { $0.tommorow }))
    router.post("Echo/testTypicalEntity", use: bridge.makeHandler(serviceBuilder, { $0.testTypicalEntity }))
    router.post("Echo/testComplexType", use: bridge.makeHandler(serviceBuilder, { $0.testComplexType }))
    router.post("Echo/emptyRequestAndResponse", use: bridge.makeHandler(serviceBuilder, { $0.emptyRequestAndResponse }))
    router.post("Echo/testTypeAliasToRawRepr", use: bridge.makeHandler(serviceBuilder, { $0.testTypeAliasToRawRepr }))
    router.post("Echo/testRawRepr", use: bridge.makeHandler(serviceBuilder, { $0.testRawRepr }))
    router.post("Echo/testRawRepr2", use: bridge.makeHandler(serviceBuilder, { $0.testRawRepr2 }))
    router.post("Echo/testRawRepr3", use: bridge.makeHandler(serviceBuilder, { $0.testRawRepr3 }))
    router.post("Echo/testRawRepr4", use: bridge.makeHandler(serviceBuilder, { $0.testRawRepr4 }))

    router.post(RouterPath.init(stringLiteral: "foo")) { (request: Request, context) in
        return ""
    }
}


protocol ServiceTransport<Service> {
    associatedtype Service
    func register<Request: Decodable, Response: Encodable>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Response
    )
}

func configureEcho<Echo: EchoServiceProtocol>(
    transport: some ServiceTransport<Echo>
) {
    transport.register(path: "Echo/hello", methodSelector: { $0.hello })
    transport.register(path: "Echo/tommorow", methodSelector: { $0.tommorow })
}

import Service
import Foundation

func main() async throws {
    let router = Router()

    configureEcho(transport: HummingbirdTransport(router: router) { _, _ in
        makeEchoService()
    })


    let app = Application(router: router)
    try await app.run()
}

struct HummingbirdTransport<Router: RouterMethods, Service>: ServiceTransport {
    var router: Router
    var serviceBuilder: @Sendable (Request, Router.Context) -> Service

    func register<Request: Decodable, Response: Encodable>(
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
