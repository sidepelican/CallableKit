import APIDefinition

public struct EchoServiceStub: EchoServiceProtocol, Sendable {
    private let client: StubClientProtocol
    public init(client: StubClientProtocol) {
        self.client = client
    }

    public func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse {
        return try await client.send(path: "Echo/hello", request: request)
    }
}
