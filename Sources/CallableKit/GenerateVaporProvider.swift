import Foundation
import SwiftTypeReader

struct GenerateVaporProvider {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]

    private func generateVaporToServiceBridgeProtocol() -> String {
        """
import Vapor

protocol VaporToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (Request) async throws -> Response
    where Req: Decodable & Sendable, Res: Encodable & Sendable

    func makeHandler<Service, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Res
    ) -> (Request) async throws -> Response
    where Res: Encodable & Sendable

    func makeHandler<Service, Req>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Void
    ) -> (Request) async throws -> Response
    where Req: Decodable & Sendable

    func makeHandler<Service>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Void
    ) -> (Request) async throws -> Response
}

private struct _Empty: Codable, Sendable {}

extension VaporToServiceBridgeProtocol {
    func makeHandler<Service, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Res
    ) -> (Request) async throws -> Response
    where Res: Encodable & Sendable
    {
        makeHandler(serviceBuilder) { (serviceType: Service.Type) in
            { (service: Service) in
                { (_: _Empty) -> Res in
                    try await methodSelector(serviceType)(service)()
                }
            }
        }
    }

    func makeHandler<Service, Req>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Void
    ) -> (Request) async throws -> Response
    where Req: Decodable & Sendable
    {
        makeHandler(serviceBuilder) { (serviceType: Service.Type) in
            { (service: Service) in
                { (req: Req) -> _Empty in
                    try await methodSelector(serviceType)(service)(req)
                    return _Empty()
                }
            }
        }
    }

    func makeHandler<Service>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Void
    ) -> (Request) async throws -> Response
    {
        makeHandler(serviceBuilder) { (serviceType: Service.Type) in
            { (service: Service) in
                { (_: _Empty) -> _Empty in
                    try await methodSelector(serviceType)(service)()
                    return _Empty()
                }
            }
        }
    }
}

"""
    }

    private func generateVaporJSONServiceBridge() -> String {
"""
import Foundation
import Vapor

extension VaporToServiceBridgeProtocol where Self == VaporJSONServiceBridge {
    static var `default`: VaporJSONServiceBridge { VaporJSONServiceBridge() }
}

struct VaporJSONServiceBridge: VaporToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (Request) async throws -> Response
    where Req: Decodable & Sendable, Res: Encodable & Sendable
    {
        VaporJSONServiceHandler(serviceBuilder: serviceBuilder, methodSelector: methodSelector)
            .callAsFunction(request:)
    }
}

private struct VaporJSONServiceHandler<Service, Req, Res> where Req: Decodable & Sendable, Res: Encodable & Sendable {
    var serviceBuilder: @Sendable (Request) async throws -> Service
    var methodSelector: (Service.Type) -> (Service) -> (Req) async throws -> Res

    func callAsFunction(request: Request) async throws -> Response {
        let service = try await serviceBuilder(request)
        guard let body = request.body.data else {
            throw Abort(.badRequest, reason: "no body")
        }
        let rpcRequest = try makeDecoder().decode(Req.self, from: body)
        let rpcResponse = try await methodSelector(Service.self)(service)(rpcRequest)
        return try makeResponse(status: .ok, body: rpcResponse)
    }

    private func makeResponse<R: Encodable>(status: HTTPResponseStatus, body: R) throws -> Response {
        let body = try makeEncoder().encode(body)
        var headers = HTTPHeaders()
        headers.contentType = .json
        headers.cacheControl = .init(noStore: true)
        return Response(status: status, headers: headers, body: .init(data: body))
    }
}

private func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    return decoder
}

private func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    return encoder
}

"""
    }

    private func processFile(file: Generator.InputFile) throws -> String? {
        var providers: [String] = []
        for stype in file.types.compactMap(ServiceProtocolScanner.scan) {
            providers.append("""
struct \(stype.serviceName)ServiceProvider<Bridge: VaporToServiceBridgeProtocol, Service: \(stype.name)>: RouteCollection {
    var bridge: Bridge
    var serviceBuilder: @Sendable (Request) async throws -> Service
    init(bridge: Bridge = .default, builder: @Sendable @escaping (Request) async throws -> Service) {
        self.bridge = bridge
        self.serviceBuilder = builder
    }

    func boot(routes: RoutesBuilder) throws {
        routes.group("\(stype.serviceName)") { group in
\(stype.functions.map { """
            group.post("\($0.name)", use: bridge.makeHandler(serviceBuilder, { $0.\($0.name) }))
""" }.joined(separator: "\n"))
        }
    }
}

""")
        }
        if providers.isEmpty { return nil }

        return """
import \(definitionModule)
import Vapor

\(providers.joined())
"""
    }

    func run() throws {
        var g = Generator(definitionModule: definitionModule, srcDirectory: srcDirectory, dstDirectory: dstDirectory, dependencies: dependencies)
        g.isOutputFileName = { $0.hasSuffix(".gen.swift") }

        try g.run { input, write in
            let common = Generator.OutputFile(
                name: "VaporToServiceBridgeProtocol.gen.swift",
                content: generateVaporToServiceBridgeProtocol()
            )
            try write(file: common)
            let common2 = Generator.OutputFile(
                name: "VaporJSONServiceBridge.gen.swift",
                content: generateVaporJSONServiceBridge()
            )
            try write(file: common2)

            for inputFile in input.files {
                guard let generated = try processFile(file: inputFile) else { continue }
                let outputFile = URL(fileURLWithPath: inputFile.file.lastPathComponent.replacingOccurrences(of: ".swift", with: ".gen.swift")).lastPathComponent
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}
