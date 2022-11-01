import APIDefinition

public func makeEchoService() -> some EchoServiceProtocol {
    EchoService()
}

struct EchoService: EchoServiceProtocol {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse {
        .init(
            message: "Hello, \(request.name)!"
        )
    }

    func testComplexType(request: TestComplexType.Request) async throws -> TestComplexType.Response {
        .init(a: request.a)
    }
}
