import Foundation

public protocol EchoServiceProtocol {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse
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
