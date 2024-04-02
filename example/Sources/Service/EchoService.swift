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

    func tommorow(from now: Date) async throws -> Date {
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

    func testRawRepr(request: Student2) async throws -> Student2 {
        return request
    }

    func testRawRepr2(request: Student3) async throws -> Student3 {
        return request
    }

    func testRawRepr3(request: Student4) async throws -> Student4 {
        return request
    }

    func testRawRepr4(request: Student5) async throws -> Student5 {
        return request
    }
}
