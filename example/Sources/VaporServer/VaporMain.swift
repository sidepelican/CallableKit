import APIDefinition
import CallableKitVaporTransport
import Vapor
import Service

@main struct VaporMain {
    static func main() async throws {
        let app = try await Application.make()

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

        app.group(myErrorMiddleware) { routes in
            configureAccountServiceProtocol(transport: VaporTransport(router: routes) { _ in
                makeAccountService()
            })
            configureEchoServiceProtocol(transport: VaporTransport(router: routes) { _ in
                makeEchoService()
            })
        }

        try await app.execute()
        try await app.asyncShutdown()
    }
}
