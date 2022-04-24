import Foundation
import SwiftTypeReader

struct GenerateVaporProvider {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL

    private func generateCommon() -> String {
        """
import Vapor

protocol RawRequestHandler {
    func makeHandler<Req: Decodable & Sendable, Res: Encodable & Sendable, Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service, Req) async throws -> (Res)
    ) -> (Request) async -> Response
}

private struct Empty: Codable, Sendable {}

extension RawRequestHandler {
    func makeHandler<Res: Encodable & Sendable, Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service) async throws -> (Res)
    ) -> (Request) async -> Response {
        makeHandler(makeService, { (s: Service, r: Empty) in
            try await callMethod(s)
        })
    }

    func makeHandler<Req: Decodable & Sendable, Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service, Req) async throws -> Void
    ) -> (Request) async -> Response {
        makeHandler(makeService, { (s: Service, r: Req) -> Empty in
            try await callMethod(s, r)
            return Empty()
        })
    }

    func makeHandler<Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service) async throws -> Void
    ) -> (Request) async -> Response {
        makeHandler(makeService, { (s: Service, r: Empty) -> Empty in
            try await callMethod(s)
            return Empty()
        })
    }
}

"""
    }

    private func processFile(module: Module) throws -> String? {
        var providers: [String] = []
        for stype in module.types.compactMap(ServiceProtocolScanner.scan) {
            providers.append("""
struct \(stype.serviceName)ServiceProvider<RequestHandler: RawRequestHandler, Service: \(stype.name)>: RouteCollection {
    var requestHandler: RequestHandler
    var serviceBuilder: (Request) -> Service
    init(handler: RequestHandler, builder: @escaping (Request) -> Service) {
        self.requestHandler = handler
        self.serviceBuilder = builder
    }

    func boot(routes: RoutesBuilder) throws {
        routes.group("\(stype.serviceName)") { group in
\(stype.functions.map { """
            group.post("\($0.name)", use: requestHandler.makeHandler(serviceBuilder) { s\($0.hasRequest ? ", r" : "") in
                try await s.\($0.name)(\($0.request.map { "\($0.argName): r" } ?? ""))
            })
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
        var g = Generator(srcDirectory: srcDirectory, dstDirectory: dstDirectory)
        g.isOutputFileName = { $0.hasSuffix(".gen.swift") }

        try g.run { input, write in
            let common = Generator.OutputFile(
                name: "common.gen.swift",
                content: generateCommon()
            )
            try write(file: common)

            for inputFile in input.files {
                guard let generated = try processFile(module: inputFile.module) else { continue }
                let outputFile = URL(fileURLWithPath: inputFile.name.replacingOccurrences(of: ".swift", with: ".gen.swift")).lastPathComponent
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}
