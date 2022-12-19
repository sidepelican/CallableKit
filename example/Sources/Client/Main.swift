import Foundation
import APIDefinition

struct ErrorFrame: Decodable, CustomStringConvertible, LocalizedError {
    var errorMessage: String

    var description: String { errorMessage }
    var errorDescription: String? { description }
}

@main struct Main {
    static func main() async throws {
        let client: some StubClientProtocol = FoundationHTTPStubClient(
            baseURL: URL(string: "http://127.0.0.1:8080")!,
            onWillSendRequest: { request in
                request.addValue("Bearer xxxxxxxxxxxx", forHTTPHeaderField: "Authorization")
            },
            mapResponseError: { error in
                throw try JSONDecoder().decode(ErrorFrame.self, from: error.body)
            }
        )

        do {
            let res = try await client.echo.hello(request: .init(name: "Swift"))
            print(res.message)
        }

        do {
            let res = try await client.echo.tommorow(now: Date())
            print(res)
        }

        do {
            let res = try await client.echo.testTypicalEntity(request: .init(id: .init(rawValue: "id"), name: "name"))
            dump(res)
        }

        do {
            let res = try await client.echo.testComplexType(request: .init(a: .some(.init(x: [
                .k(.init(x: .init(x: "hello"))),
                .i(100),
                .n,
                nil,
            ]))))
            dump(res)
        }

        do {
            try await client.echo.emptyRequestAndResponse()
        }

        do {
            let student: Student = .init(
                id: Student.IDz(rawValue: "0001"),
                name: "taro"
            )
            let res = try await client.echo.testTypeAliasToRawRepr(request: student)
            dump(res)
        }

        do {
            let res = try await client.account.signin(request: .init(
                email: "example@example.com",
                password: "password"
            ))
            dump(res)
        }
    }
}
