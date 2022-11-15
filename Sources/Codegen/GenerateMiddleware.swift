import Foundation
import SwiftTypeReader

struct GenerateMiddleware {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]

    private func processFile(file: Generator.InputFile) throws -> String? {
        var providers: [String] = []
        for stype in file.types.compactMap(ServiceProtocolScanner.scan) {
            providers.append("""
protocol \(stype.serviceName)ServiceMiddlewareProtocol: \(stype.serviceName)ServiceProtocol {
    associatedtype Output
    associatedtype Next: \(stype.serviceName)ServiceProtocol
    func prepare() async throws -> Output
    var next: (Output) -> Next { get }
}

extension \(stype.serviceName)ServiceMiddlewareProtocol {
\(stype.functions.map { f in
    let req = f.request.map { "\($0.argName): \($0.typeName)" } ?? ""
    let res = f.response.map { " -> \($0.typeName)" } ?? ""
    return """
    func \(f.name)(\(req)) async throws\(res) {
        try await next(try await prepare()).\(f.name)(\(f.request.map { "\($0.argName): \($0.argName)" } ?? ""))
    }
""" }.joined(separator: "\n"))
}

""")
        }
        if providers.isEmpty { return nil }

        return """
import \(definitionModule)

\(providers.joined())
"""
    }

    func run() throws {
        var g = Generator(definitionModule: definitionModule, srcDirectory: srcDirectory, dstDirectory: dstDirectory, dependencies: dependencies)
        g.isOutputFileName = { $0.hasSuffix(".gen.swift") }
        
        try g.run { input, write in
            for inputFile in input.files {
                guard let generated = try processFile(file: inputFile) else { continue }
                let outputFile = URL(fileURLWithPath: inputFile.path.lastPathComponent.replacingOccurrences(of: ".swift", with: "Middleware.gen.swift")).lastPathComponent
                try write(file: .init(
                    name: outputFile,
                    content: generated
                ))
            }
        }
    }
}
