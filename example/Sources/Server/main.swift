import Vapor
import Service

let app = Application()
defer { app.shutdown() }

let echoProvider = EchoServiceProvider(handler: .default) { req in
    makeEchoService()
}
try app.register(collection: echoProvider)

try app.run()
