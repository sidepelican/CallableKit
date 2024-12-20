import APIDefinition
import CallableKitHummingbirdTransport
import Foundation
import Logging
import Hummingbird
import Service

struct ErrorFrame: Encodable {
    var errorMessage: String
}

struct ErrorMiddleware<Context: RequestContext>: MiddlewareProtocol {
    func handle(_ input: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        do {
            return try await next(input, context)
        } catch {
            context.logger.error("\(error)")
            let errorFrame = ErrorFrame(errorMessage: "\(error)")
            var response = try JSONEncoder().encode(errorFrame, from: input, context: context)
            response.headers[.cacheControl] = "no-store"
            return response
        }
    }
}

@main struct HBMain {
    static func main() async throws {
        let router = Router()
        router.add(middleware: ErrorMiddleware())

        configureAccountServiceProtocol(transport: HummingbirdTransport(router: router) { _, _ in
            try await makeAccountService()
        })
        configureEchoServiceProtocol(transport: HummingbirdTransport(router: router) { _, _ in
            makeEchoService()
        })

        var logger = Logger(label: "Hummingbird")
        logger.logLevel = .error
        let app = Application(
            router: router,
            configuration: .init(
                address: .hostname("127.0.0.1", port: 8080)
            ),
            logger: logger
        )

        try await app.runService()
    }
}
