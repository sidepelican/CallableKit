import APIDefinition
import Vapor

struct EchoServiceProvider<Bridge: VaporToServiceBridgeProtocol, Service: EchoServiceProtocol>: RouteCollection {
    var bridge: Bridge
    var serviceBuilder: @Sendable (Request) async throws -> Service
    init(bridge: Bridge = .default, builder: @Sendable @escaping (Request) async throws -> Service) {
        self.bridge = bridge
        self.serviceBuilder = builder
    }

    func boot(routes: any RoutesBuilder) throws {
        routes.group("Echo") { group in
            group.post("hello", use: bridge.makeHandler(serviceBuilder, { $0.hello }))
            group.post("tommorow", use: bridge.makeHandler(serviceBuilder, { $0.tommorow }))
            group.post("testTypicalEntity", use: bridge.makeHandler(serviceBuilder, { $0.testTypicalEntity }))
            group.post("testComplexType", use: bridge.makeHandler(serviceBuilder, { $0.testComplexType }))
            group.post("emptyRequestAndResponse", use: bridge.makeHandler(serviceBuilder, { $0.emptyRequestAndResponse }))
            group.post("testTypeAliasToRawRepr", use: bridge.makeHandler(serviceBuilder, { $0.testTypeAliasToRawRepr }))
            group.post("testRawRepr", use: bridge.makeHandler(serviceBuilder, { $0.testRawRepr }))
            group.post("testRawRepr2", use: bridge.makeHandler(serviceBuilder, { $0.testRawRepr2 }))
            group.post("testRawRepr3", use: bridge.makeHandler(serviceBuilder, { $0.testRawRepr3 }))
            group.post("testRawRepr4", use: bridge.makeHandler(serviceBuilder, { $0.testRawRepr4 }))
        }
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

extension ServiceTransport {
    
}

import Service
import Foundation

func main() async throws {
    let app = try await Application.make()

    configureEcho(transport: VaporTransport(router: app.routes) { _ in
        makeEchoService()
    })

    try await app.execute()
}

struct VaporTransport<Router: RoutesBuilder, Service>: ServiceTransport {
    var router: Router
    var serviceBuilder: @Sendable (Request) -> Service

    func register<Request: Decodable, Response: Encodable>(
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
