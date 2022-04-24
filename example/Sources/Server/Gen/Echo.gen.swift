import APIDefinition
import Vapor

struct EchoServiceProvider<RequestHandler: RawRequestHandler, Service: EchoServiceProtocol>: RouteCollection {
    var requestHandler: RequestHandler
    var serviceBuilder: (Request) -> Service
    init(handler: RequestHandler, builder: @escaping (Request) -> Service) {
        self.requestHandler = handler
        self.serviceBuilder = builder
    }

    func boot(routes: RoutesBuilder) throws {
        routes.group("Echo") { group in
            group.post("hello", use: requestHandler.makeHandler(serviceBuilder) { s, r in
                try await s.hello(request: r)
            })
        }
    }
}
