import APIDefinition
import Foundation

public func makeEchoService() -> some EchoServiceProtocol {
    EchoService()
}

struct EchoService: EchoServiceProtocol {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse {
        .init(
            message: "Hello, \(request.name)!"
        )
    }

    func tommorow(now: Date) async throws -> Date {
        now.addingTimeInterval(60 * 60 * 24 * 1)
    }

    func testTypicalEntity(request: User) async throws -> User {
        request
    }

    func testComplexType(request: TestComplexType.Request) async throws -> TestComplexType.Response {
        .init(a: request.a)
    }

    func emptyRequestAndResponse() async throws {
    }

    func testTypeAliasToRawRepr(request: Student) async throws -> Student {
        return request
    }
}
