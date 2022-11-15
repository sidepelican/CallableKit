import APIDefinition
import Foundation
import OtherDependency

public struct AccountServiceStub<C: StubClientProtocol>: AccountServiceProtocol, Sendable {
    private let client: C
    public init(client: C) {
        self.client = client
    }

    public func signin(request: AccountSignin.Request) async throws -> CodableResult<AccountSignin.Response, SubmitError<AccountSignin.Error>> {
        return try await client.send(path: "Account/signin", request: request)
    }
}

extension StubClientProtocol {
    public var account: AccountServiceStub<Self> {
        AccountServiceStub(client: self)
    }
}
