# CallableKit

CallableKit provides typesafe rpc with Swift server

### Supported clients

- Swift (with Foundation)
- TypeScript (with fetch)

# Example

- Define interface protocol and share this module for server and client.

```swift
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
```

- Run code generation

- Server implements thet protocol and register to routes.

```swift
import Vapor

struct EchoService: EchoServiceProtocol {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse {
        return .init(message: "Hello, \(request.name)!")
    }
}

let app = Application()
defer { app.shutdown() }
let echoProvider = EchoServiceProvider { _ in // EchoServiceProvider is generated type
    EchoService()
}
try app.register(collection: echoProvider)
try app.run()
```

- Client can call the functions through stub client. Using the same protocol.

```swift
let client: some StubClientProtocol = FoundationHTTPStubClient(
    baseURL: URL(string: "http://127.0.0.1:8080")!,
)
// .echo.hello is generated extension
let res = try await client.echo.hello(request: .init(name: "Swift"))
print(res.message) // Hello, Swift!
```

- TypeScript client also supported! 

```ts
const stub = createStubClient("http://127.0.0.1:8080");
const echoClient = bindEcho(stub);
const res = await echoClient.hello({ name: "TypeScript" });
console.log(res.message); // Hello, TypeScript!
//           ^? res: { message: string }
```

Swift types are coverted to TS types powered by [CodableToTypeScript](https://github.com/omochi/CodableToTypeScript)

# Run code generation

- Checkout this repo and simply run executable command

```sh
$ swift run codegen Sources/APIDefinition \
    --client_out Sources/Client/Gen \
    --vapor_out Sources/Server/Gen \
    --ts_out TSClient/src/Gen \
```

  [Mint](https://github.com/yonaskolb/Mint) is useful to checkout and run.

or 

- Use from package plugin (see [example](https://github.com/sidepelican/CallableKit/tree/main/example))
  
  Add plugin target in your Package.swift (or add dedicated Package.swift for independency)

```swift
    dependencies: [
        ...
        .package(url: "https://github.com/sidepelican/CallableKit", from: "1.0.0"),
    ],
    targets: [
        ...
        .plugin(
            name: "CodegenPlugin",
            capability: .command(
                intent: .custom(verb: "codegen", description: "Generate codes from Sources/APIDefinition"),
                permissions: [.writeToPackageDirectory(reason: "Place generated code")]
            ),
            dependencies: [
                .product(name: "codegen", package: "CallableKit"),
            ]
        )
    ]
```

```sh
$ swift run codegen
```
