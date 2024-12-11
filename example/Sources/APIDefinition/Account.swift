import CallableKit
import Foundation
import OtherDependency

@Callable
public protocol AccountServiceProtocol {
    func signin(request: AccountSignin.Request) async throws -> CodableResult<AccountSignin.Response, SubmitError<AccountSignin.Error>>
}

public enum AccountSignin {
    public struct Request: Codable, Sendable {
        public init(email: String, password: String) {
            self.email = email
            self.password = password
        }

        public var email: String
        public var password: String
    }

    public struct Response: Codable, Sendable {
        public init(userName: String) {
            self.userName = userName
        }
        public var userName: String
    }

    public enum Error: String, Codable, Swift.Error {
        case email
        case password
        case emailOrPassword
    }
}
