import Vapor
import Service

let app = Application()
defer { app.shutdown() }

let echoProvider = EchoServiceProvider(bridge: .default) { req in
    makeEchoService()
}
let accountProvider = AccountServiceProvider(bridge: .default) { req in
    makeAccountService()
}
try app.register(collection: echoProvider)
try app.register(collection: accountProvider)

try app.run()
