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
    public func tommorow(from now: Date) async throws -> Date {
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
    public func testTypeAliasToRawRepr(request: Student) async throws -> Student {
        return try await client.send(path: "Echo/testTypeAliasToRawRepr", request: request)
    }
    public func testRawRepr(request: Student2) async throws -> Student2 {
        return try await client.send(path: "Echo/testRawRepr", request: request)
    }
    public func testRawRepr2(request: Student3) async throws -> Student3 {
        return try await client.send(path: "Echo/testRawRepr2", request: request)
    }
    public func testRawRepr3(request: Student4) async throws -> Student4 {
        return try await client.send(path: "Echo/testRawRepr3", request: request)
    }
    public func testRawRepr4(request: Student5) async throws -> Student5 {
        return try await client.send(path: "Echo/testRawRepr4", request: request)
    }
}

extension StubClientProtocol {
    public var echo: EchoServiceStub<Self> {
        EchoServiceStub(client: self)
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

struct URLSessionTransport<Service>: ServiceTransport {
    func register<Request, Response>(
        path: String,
        methodSelector: @escaping @Sendable (Service.Type) -> (Service) -> (Request) async throws -> Response
    ) where Request : Decodable, Response : Encodable {
        
    }
}
