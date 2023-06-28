import APIDefinition
import Vapor

struct AccountServiceProvider<Bridge: VaporToServiceBridgeProtocol, Service: AccountServiceProtocol>: RouteCollection {
    var bridge: Bridge
    var serviceBuilder: @Sendable (Request) async throws -> Service
    init(bridge: Bridge = .default, builder: @Sendable @escaping (Request) async throws -> Service) {
        self.bridge = bridge
        self.serviceBuilder = builder
    }

    func boot(routes: any RoutesBuilder) throws {
        routes.group("Account") { group in
            group.post("signin", use: bridge.makeHandler(serviceBuilder, { $0.signin }))
        }
    }
}
