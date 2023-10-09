import Foundation
import Hummingbird
import Service

struct ErrorMiddleware: HBMiddleware {
    func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        next.respond(to: request).flatMapErrorThrowing { error in
            request.logger.error("\(error)")
            struct ErrorFrame: Encodable {
                var errorMessage: String
            }
            let errorFrame = ErrorFrame(errorMessage: "\(error)")
            var headers = HTTPHeaders()
            headers.add(name: "Content-Type", value: "application/json")
            headers.add(name: "Cache-Control", value: "no-store")
            let body = (try? JSONEncoder().encode(errorFrame)) ?? .init()
            return HBResponse(status: .internalServerError, headers: headers, body: .byteBuffer(.init(data: body)))
        }
    }
}

@main struct Main {
    static func main() async throws {
        let app = HBApplication(
            configuration: .init(
                address: .hostname("127.0.0.1", port: 8080),
                tlsOptions: .none
            )
        )
        defer { app.stop() }
        app.logger.logLevel = .error

        let router = app.router.group().add(middleware: ErrorMiddleware())

        configureAccountService(builder: { req in
            makeAccountService()
        }, router: router)

        configureEchoService(builder: { req in
            makeEchoService()
        }, router: router)

        try await app.asyncRun()
    }
}
