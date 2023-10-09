import APIDefinition
import Hummingbird

func configureAccountService(
    bridge: some HBToServiceBridgeProtocol = .default,
    builder serviceBuilder: @escaping @Sendable (HBRequest) async throws -> some AccountServiceProtocol,
    router: some HBRouterMethods
) {
    router.post("Account/signin", use: bridge.makeHandler(serviceBuilder, { $0.signin }))
}
