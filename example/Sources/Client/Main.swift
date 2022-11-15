import Foundation

@main struct Main {
    static func main() async throws {
        let client = RawStubClient(baseURL: URL(string: "http://127.0.0.1:8080")!)

        do {
            let res = try await client.echo.hello(request: .init(name: "Swift"))
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
            let res = try await client.account.signin(request: .init(
                email: "example@example.com",
                password: "password"
            ))
            dump(res)
        }
    }
}
