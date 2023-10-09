import Foundation
import SwiftTypeReader

struct GenerateHBProvider {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]

    private func generateHBToServiceBridgeProtocol() -> String {
        """
import Hummingbird

protocol HBToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (HBRequest) async throws -> HBResponse
    where Req: Decodable & Sendable, Res: Encodable & Sendable

    func makeHandler<Service, Res>(
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Res
    ) -> (HBRequest) async throws -> HBResponse
    where Res: Encodable & Sendable

    func makeHandler<Service, Req>(
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Void
    ) -> (HBRequest) async throws -> HBResponse
    where Req: Decodable & Sendable

    func makeHandler<Service>(
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Void
    ) -> (HBRequest) async throws -> HBResponse
}

private struct _Empty: Codable, Sendable {}

extension HBToServiceBridgeProtocol {
    func makeHandler<Service, Res>(
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Res
    ) -> (HBRequest) async throws -> HBResponse
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
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Void
    ) -> (HBRequest) async throws -> HBResponse
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
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Void
    ) -> (HBRequest) async throws -> HBResponse
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

    private func generateHBJSONServiceBridge() -> String {
"""
import Foundation
import Hummingbird

extension HBToServiceBridgeProtocol where Self == HBJSONServiceBridge {
    static var `default`: HBJSONServiceBridge { HBJSONServiceBridge() }
}

struct HBJSONServiceBridge: HBToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (HBRequest) async throws -> HBResponse
    where Req: Decodable & Sendable, Res: Encodable & Sendable
    {
        HBJSONServiceHandler(serviceBuilder: serviceBuilder, methodSelector: methodSelector)
            .callAsFunction(request:)
    }
}

private struct HBJSONServiceHandler<Service, Req, Res> where Req: Decodable & Sendable, Res: Encodable & Sendable {
    var serviceBuilder: @Sendable (HBRequest) async throws -> Service
    var methodSelector: (Service.Type) -> (Service) -> (Req) async throws -> Res

    func callAsFunction(request: HBRequest) async throws -> HBResponse {
        let service = try await serviceBuilder(request)
        guard let body = request.body.buffer else {
            throw HBHTTPError(.badRequest, message: "no body")
        }
        let rpcRequest = try makeDecoder().decode(Req.self, from: body)
        let rpcResponse = try await methodSelector(Service.self)(service)(rpcRequest)
        return try makeResponse(status: .ok, body: rpcResponse)
    }

    private func makeResponse<R: Encodable>(status: HTTPResponseStatus, body: R) throws -> HBResponse {
        let body = try makeEncoder().encodeAsByteBuffer(body, allocator: .init())
        let headers = HTTPHeaders([
            ("Content-Type", "application/json"),
            ("Cache-Control", "no-store"),
        ])
        return HBResponse(status: status, headers: headers, body: .byteBuffer(body))
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
func configure\(stype.serviceName)Service(
    bridge: some HBToServiceBridgeProtocol = .default,
    builder serviceBuilder: @escaping @Sendable (HBRequest) async throws -> some \(stype.name),
    router: some HBRouterMethods
) {
\(stype.functions.map { """
    router.post("\(stype.serviceName)/\($0.name)", use: bridge.makeHandler(serviceBuilder, { $0.\($0.name) }))
""" }.joined(separator: "\n"))
}

""")
        }
        if providers.isEmpty { return nil }

        return """
import \(definitionModule)
import Hummingbird

\(providers.joined())
"""
    }

    func run() throws {
        var g = Generator(definitionModule: definitionModule, srcDirectory: srcDirectory, dstDirectory: dstDirectory, dependencies: dependencies)
        g.isOutputFileName = { $0.hasSuffix(".gen.swift") }

        try g.run { input, write in
            try write(file: .init(
                name: "HBToServiceBridgeProtocol.gen.swift",
                content: generateHBToServiceBridgeProtocol()
            ))
            try write(file: .init(
                name: "HBJSONServiceBridge.gen.swift",
                content: generateHBJSONServiceBridge()
            ))

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
