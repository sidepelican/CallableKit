import APIDefinition

public struct EchoServiceStub: EchoServiceProtocol, Sendable {
    private let client: StubClientProtocol
    public init(client: StubClientProtocol) {
        self.client = client
    }

    public func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse {
        return try await client.send(path: "Echo/hello", request: request)
    }
    public func testComplexType(request: TestComplexType.Request) async throws -> Response {
        return try await client.send(path: "Echo/testComplexType", request: request)
    }
}
