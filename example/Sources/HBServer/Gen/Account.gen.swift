import APIDefinition
import Hummingbird

func configureAccountService(
    bridge: some HBToServiceBridgeProtocol = .default,
    builder serviceBuilder: @escaping @Sendable (Request) async throws -> some AccountServiceProtocol,
    router: some RouterMethods
) {
    router.post("Account/signin", use: bridge.makeHandler(serviceBuilder, { $0.signin }))
}
