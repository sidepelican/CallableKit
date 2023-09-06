import Vapor
import Service

let app = Application()
defer { app.shutdown() }

app.logger.logLevel = .error
let logger = app.logger

let myErrorMiddleware = ErrorMiddleware { _, error in
    logger.error("\(error)")
    struct ErrorFrame: Encodable {
        var errorMessage: String
    }
    let errorFrame = ErrorFrame(errorMessage: "\(error)")
    var headers = HTTPHeaders()
    headers.contentType = .json
    headers.cacheControl = .init(noStore: true)
    let body = (try? JSONEncoder().encode(errorFrame)) ?? .init()
    return Response(status: .internalServerError, headers: headers, body: .init(data: body))
}

try app.group(myErrorMiddleware) { routes in
    let echoProvider = EchoServiceProvider { req in
        makeEchoService()
    }
    let accountProvider = AccountServiceProvider { req in
        makeAccountService()
    }
    try routes.register(collection: echoProvider)
    try routes.register(collection: accountProvider)
}

try app.run()
