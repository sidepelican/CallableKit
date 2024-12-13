import APIDefinition
import CallableKit
import Foundation
import OtherDependency

public struct AccountServiceProtocolStub<C: StubClientProtocol>: AccountServiceProtocol, Sendable {
    private let client: C
    public init(client: C) {
        self.client = client
    }

    public func signin(request: AccountSignin.Request) async throws -> CodableResult<AccountSignin.Response, SubmitError<AccountSignin.Error>> {
        return try await client.send(path: "Account/signin", request: request)
    }
}

