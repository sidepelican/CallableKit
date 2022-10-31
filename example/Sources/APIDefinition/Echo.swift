import Foundation

public protocol EchoServiceProtocol {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse

    func testComplexType(request: TestComplexType.Request) async throws -> TestComplexType.Response
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
    }

    public enum E<T>: Codable & Sendable where T: Codable & Sendable {
        case k(K<T>)
        case i(Int)
        case n
    }

    public struct L: Codable & Sendable {
        public var x: String
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
