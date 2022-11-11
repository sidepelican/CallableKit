import APIDefinition

public struct EchoServiceStub<C: StubClientProtocol>: EchoServiceProtocol, Sendable {
    private let client: C
    public init(client: C) {
        self.client = client
    }

    public func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse {
        return try await client.send(path: "Echo/hello", request: request)
    }
    public func testComplexType(request: TestComplexType.Request) async throws -> TestComplexType.Response {
        return try await client.send(path: "Echo/testComplexType", request: request)
    }
}

extension StubClientProtocol {
    public var echo: EchoServiceStub<Self> {
        EchoServiceStub(client: self)
    }
}
