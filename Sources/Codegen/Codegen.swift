import ArgumentParser
import Foundation

enum CodegenError: Error {
    case definitionsModuleNameNotFound
}

@main struct Codegen: ParsableCommand {
    @Option(help: "generate client stub", completion: .directory)
    var client_out: URL?

    @Option(help: "generate service middleware code", completion: .directory)
    var middleware_out: URL?

    @Option(help: "generate routing code for vipor", completion: .directory)
    var vapor_out: URL?

    @Option(help: "generate client stub for typescript", completion: .directory)
    var ts_out: URL?

    @Option(name: .shortAndLong, help: "module name of definition")
    var module: String?

    @Argument(help: "directory path of definition codes", completion: .directory)
    var definitionDirectory: URL

    mutating func run() throws {
        let moduleName = definitionDirectory
            .resolvingSymlinksInPath()
            .pathComponents
            .eachPairs()
            .first { (f, s) in
                f == "Sources"
            }
            .map(\.1)
        guard let module = module ?? moduleName else {
            throw CodegenError.definitionsModuleNameNotFound
        }

        if let client_out = client_out {
            try GenerateIOSClient(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: client_out
            ).run()
        }

        if let middleware_out = middleware_out {
            try GenerateMiddleware(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: middleware_out
            ).run()
        }

        if let vapor_out = vapor_out {
            try GenerateVaporProvider(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: vapor_out
            ).run()
        }

        if let ts_out = ts_out {
            try GenerateNextClient(
                srcDirectory: definitionDirectory,
                dstDirectory: ts_out
            ).run()
        }
    }
}

extension Sequence {
    func eachPairs() -> AnySequence<(Element, Element)> {
        AnySequence(
            zip(self, self.dropFirst())
        )
    }
}

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self = URL(fileURLWithPath: argument)
    }
}
