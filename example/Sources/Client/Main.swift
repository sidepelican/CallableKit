import Foundation

@main struct Main {
    static func main() async throws {
        let rawClient = RawStubClient(baseURL: URL(string: "http://127.0.0.1:8080")!)
        let echoClient = EchoServiceStub(client: rawClient)

        let res = try await echoClient.hello(request: .init(name: "Bob"))
        print(res.message)
    }
}
