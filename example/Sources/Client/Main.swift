import APIDefinition
import CallableKit
import CallableKitURLSessionStub
import Foundation

struct ErrorFrame: Decodable, CustomStringConvertible, LocalizedError {
    var errorMessage: String

    var description: String { errorMessage }
    var errorDescription: String? { description }
}

@main struct Main {
    static func main() async throws {
        let client: some StubClientProtocol = URLSessionStubClient(
            baseURL: URL(string: "http://127.0.0.1:8080")!,
            onWillSendRequest: { request in
                request.addValue("Bearer xxxxxxxxxxxx", forHTTPHeaderField: "Authorization")
            },
            mapResponseError: { error in
                do {
                    throw try JSONDecoder().decode(ErrorFrame.self, from: error.body)
                } catch let decodingError {
                    throw ErrorFrame(errorMessage: "\(decodingError), body=\(String(data: error.body, encoding: .utf8) ?? "")")
                }
            }
        )
        let echoClient = EchoServiceProtocolStub(client: client)
        let accountClient = AccountServiceProtocolStub(client: client)

        do {
            let res = try await echoClient.hello(request: .init(name: "Swift"))
            print(res.message)
        }

        do {
            let res = try await echoClient.tommorow(from: Date())
            print(res)
        }

        do {
            let res = try await echoClient.testTypicalEntity(request: .init(id: .init(rawValue: "id"), name: "name"))
            dump(res)
        }

        do {
            let res = try await echoClient.testComplexType(request: .init(a: .some(.init(x: [
                .k(.init(x: .init(x: "hello"))),
                .i(100),
                .n,
                nil,
            ]))))
            dump(res)
        }

        do {
            try await echoClient.emptyRequestAndResponse()
        }

        do {
            let student: Student = .init(
                id: Student.ID(rawValue: "0001"),
                name: "taro"
            )
            let res = try await echoClient.testTypeAliasToRawRepr(request: student)
            dump(res)
        }

        do {
            let student: Student2 = .init(
                id: Student2.ID(rawValue: "0002"),
                name: "taro"
            )
            let res = try await echoClient.testRawRepr(request: student)
            dump(res)
        }

        do {
            let student: Student3 = .init(
                id: Student3.ID(rawValue: .id("0003")),
                name: "taro"
            )
            let res = try await echoClient.testRawRepr2(request: student)
            dump(res)
        }

        do {
            let student: Student4 = .init(
                id: Student4.ID(rawValue: .init(rawValue: .id("0004"))),
                name: "taro"
            )
            let res = try await echoClient.testRawRepr3(request: student)
            dump(res)
        }

        do {
            let student: Student5 = .init(
                id: Student5.ID(rawValue: "0005"),
                name: "taro"
            )
            let res = try await echoClient.testRawRepr4(request: student)
            dump(res)
        }

        do {
            let res = try await accountClient.signin(request: .init(
                email: "example@example.com",
                password: "password"
            ))
            dump(res)
        }
    }
}
