import APIDefinition
import Foundation

public struct EchoServiceStub<C: StubClientProtocol>: EchoServiceProtocol, Sendable {
    private let client: C
    public init(client: C) {
        self.client = client
    }

    public func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse {
        return try await client.send(path: "Echo/hello", request: request)
    }
    public func tommorow(now: Date) async throws -> Date {
        return try await client.send(path: "Echo/tommorow", request: now)
    }
    public func testTypicalEntity(request: User) async throws -> User {
        return try await client.send(path: "Echo/testTypicalEntity", request: request)
    }
    public func testComplexType(request: TestComplexType.Request) async throws -> TestComplexType.Response {
        return try await client.send(path: "Echo/testComplexType", request: request)
    }
    public func emptyRequestAndResponse() async throws {
        return try await client.send(path: "Echo/emptyRequestAndResponse")
    }
}

extension StubClientProtocol {
    public var echo: EchoServiceStub<Self> {
        EchoServiceStub(client: self)
    }
}
