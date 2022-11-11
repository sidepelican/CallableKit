import Foundation

@main struct Main {
    static func main() async throws {
        let client = RawStubClient(baseURL: URL(string: "http://127.0.0.1:8080")!)

        let res = try await client.echo.hello(request: .init(name: "Bob"))
        print(res.message)
    }
}
