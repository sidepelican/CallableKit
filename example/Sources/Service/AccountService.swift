import APIDefinition
import OtherDependency

public func makeAccountService() -> some AccountServiceProtocol {
    AccountService()
}

struct AccountService: AccountServiceProtocol {
    func signin(request: AccountSignin.Request) async throws -> CodableResult<AccountSignin.Response, SubmitError<AccountSignin.Error>> {
        let inputErrors = validateFields(request: request)
        guard inputErrors.isEmpty else {
            return .failure(.init(errors: inputErrors))
        }

        guard request.email == "example@example.com",
              request.password == "password" else {
            return .failure(.init(errors: [
                .init(name: .emailOrPassword, message: "email or password wrong")
            ]))
        }

        return .success(.init(userName: "ExampleName"))
    }

    private func validateFields(request: AccountSignin.Request) -> [InputFieldError<AccountSignin.Error>] {
        var inputErrors: [InputFieldError<AccountSignin.Error>] = []
        if request.email.isEmpty {
            inputErrors.append(.init(name: .email, message: "email is empty"))
        }
        if request.password.isEmpty {
            inputErrors.append(.init(name: .password, message: "password is empty"))
        }
        return inputErrors
    }
}
