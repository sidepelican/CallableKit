import CallableKitMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class CallableTests: XCTestCase {
    let macros: [String: any Macro.Type] = [
        "Callable": CallableMacro.self,
    ]

    func testBasic() {
        assertMacroExpansion("""
@Callable
public protocol EchoServiceProtocol {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse
    func testComplexType(request: TestComplexType.Request) async throws -> TestComplexType.Response
    func emptyRequestAndResponse() async throws
}
""", expandedSource: """
public protocol EchoServiceProtocol {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse
    func testComplexType(request: TestComplexType.Request) async throws -> TestComplexType.Response
    func emptyRequestAndResponse() async throws
}

public func configureEchoServiceProtocol<Echo: EchoServiceProtocol>(
    transport: some ServiceTransport<Echo>
) {
    transport.register(path: "Echo/hello") {
        $0.hello
    }
    transport.register(path: "Echo/testComplexType") {
        $0.testComplexType
    }
    transport.register(path: "Echo/emptyRequestAndResponse") {
        $0.emptyRequestAndResponse
    }
}

public struct EchoServiceProtocolStub<C: StubClientProtocol>: EchoServiceProtocol, Sendable {
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
    public func emptyRequestAndResponse() async throws {
        return try await client.send(path: "Echo/emptyRequestAndResponse")
    }
}
""", macros: macros
        )
    }

    func testServiceNameSuffixTrimmed() {
        assertMacroExpansion("""
@Callable
public protocol GreetingService {
    func hello() async throws -> String
}
""", expandedSource: """
public protocol GreetingService {
    func hello() async throws -> String
}

public func configureGreetingService<Greeting: GreetingService>(
    transport: some ServiceTransport<Greeting>
) {
    transport.register(path: "Greeting/hello") {
        $0.hello
    }
}

public struct GreetingServiceStub<C: StubClientProtocol>: GreetingService, Sendable {
    private let client: C
    public init(client: C) {
        self.client = client
    }
    public func hello() async throws -> String {
        return try await client.send(path: "Greeting/hello")
    }
}
""", macros: macros
        )
    }
}
