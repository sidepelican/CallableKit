import APIDefinition
import Hummingbird

func configureEchoService(
    bridge: some HBToServiceBridgeProtocol = .default,
    builder serviceBuilder: @escaping @Sendable (HBRequest) async throws -> some EchoServiceProtocol,
    router: some HBRouterMethods
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
}
