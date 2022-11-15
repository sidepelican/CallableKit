import Foundation
import SwiftTypeReader

struct GenerateVaporProvider {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]

    private func generateCommon() -> String {
        """
import Vapor

protocol VaporToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (Request) async -> Response
    where Req: Decodable & Sendable, Res: Encodable & Sendable
}

private struct _Empty: Codable, Sendable {}

extension VaporToServiceBridgeProtocol {
    func makeHandler<Service, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> () async throws -> Res
    ) -> (Request) async -> Response
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
    ) -> (Request) async -> Response
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
    ) -> (Request) async -> Response
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

    private func processFile(file: Generator.InputFile) throws -> String? {
        var providers: [String] = []
        for stype in file.types.compactMap(ServiceProtocolScanner.scan) {
            providers.append("""
struct \(stype.serviceName)ServiceProvider<Bridge: VaporToServiceBridgeProtocol, Service: \(stype.name)>: RouteCollection {
    var bridge: Bridge
    var serviceBuilder: @Sendable (Request) async throws -> Service
    init(bridge: Bridge, builder: @Sendable @escaping (Request) async throws -> Service) {
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
                name: "common.gen.swift",
                content: generateCommon()
            )
            try write(file: common)

            for inputFile in input.files {
                guard let generated = try processFile(file: inputFile) else { continue }
                let outputFile = URL(fileURLWithPath: inputFile.path.lastPathComponent.replacingOccurrences(of: ".swift", with: ".gen.swift")).lastPathComponent
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}
