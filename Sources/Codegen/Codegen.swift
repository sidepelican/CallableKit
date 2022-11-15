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

    @Option(name: .shortAndLong, parsing: .singleValue, help: "directory path of dependency module source", completion: .directory)
    var dependency: [URL] = []

    @Argument(help: "directory path of definition codes", completion: .directory)
    var definitionDirectory: URL

    @Flag(help: "use import decl of Next.js style")
    var nextjs: Bool = false

    mutating func run() throws {
        guard let module = module ?? detectModuleName(dir: definitionDirectory) else {
            throw CodegenError.definitionsModuleNameNotFound
        }

        if let client_out = client_out {
            try GenerateSwiftClient(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: client_out,
                dependencies: dependency
            ).run()
        }

        if let middleware_out = middleware_out {
            try GenerateMiddleware(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: middleware_out,
                dependencies: dependency
            ).run()
        }

        if let vapor_out = vapor_out {
            try GenerateVaporProvider(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: vapor_out,
                dependencies: dependency
            ).run()
        }

        if let ts_out = ts_out {
            try GenerateTSClient(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: ts_out,
                dependencies: dependency,
                nextjs: nextjs
            ).run()
        }
    }
}

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self = URL(fileURLWithPath: argument)
    }
}
