import Foundation

public protocol EchoServiceProtocol {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse

    func tommorow(now: Date) async throws -> Date

    func testTypicalEntity(request: User) async throws -> User

    func testComplexType(request: TestComplexType.Request) async throws -> TestComplexType.Response

    func emptyRequestAndResponse() async throws

    func testTypeAliasToRawRepr(request: Student) async throws -> Student
    func testRawRepr(request: Student2) async throws -> Student2
    func testRawRepr2(request: Student3) async throws -> Student3
    func testRawRepr3(request: Student4) async throws -> Student4
}

public struct EchoHelloRequest: Codable, Sendable {
    public init(name: String) {
        self.name = name
    }

    public var name: String
}

public struct EchoHelloResponse: Codable, Sendable {
    public init(message: String) {
        self.message = message
    }

    public var message: String
}

public enum TestComplexType {
    public struct K<T>: Codable & Sendable where T: Codable & Sendable {
        public var x: T

        public init(x: T) {
            self.x = x
        }
    }

    public enum E<T>: Codable & Sendable where T: Codable & Sendable {
        case k(K<T>)
        case i(Int)
        case n
    }

    public struct L: Codable & Sendable {
        public var x: String

        public init(x: String) {
            self.x = x
        }
    }

    public struct Request: Codable & Sendable {
        public var a: K<[E<L>?]>?

        public init(a: K<[E<L>?]>?) {
            self.a = a
        }
    }

    public struct Response: Codable & Sendable {
        public var a: K<[E<L>?]>?

        public init(a: K<[E<L>?]>?) {
            self.a = a
        }
    }
}
