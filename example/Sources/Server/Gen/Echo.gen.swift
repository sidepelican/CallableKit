import APIDefinition
import Vapor

struct EchoServiceProvider<Bridge: VaporToServiceBridgeProtocol, Service: EchoServiceProtocol>: RouteCollection {
    var bridge: Bridge
    var serviceBuilder: @Sendable (Request) async throws -> Service
    init(bridge: Bridge, builder: @Sendable @escaping (Request) async throws -> Service) {
        self.bridge = bridge
        self.serviceBuilder = builder
    }

    func boot(routes: RoutesBuilder) throws {
        routes.group("Echo") { group in
            group.post("hello", use: bridge.makeHandler(serviceBuilder, { $0.hello }))
            group.post("testTypicalEntity", use: bridge.makeHandler(serviceBuilder, { $0.testTypicalEntity }))
            group.post("testComplexType", use: bridge.makeHandler(serviceBuilder, { $0.testComplexType }))
            group.post("emptyRequestAndResponse", use: bridge.makeHandler(serviceBuilder, { $0.emptyRequestAndResponse }))
        }
    }
}
