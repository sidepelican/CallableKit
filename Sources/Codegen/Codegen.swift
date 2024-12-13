import ArgumentParser
import CodegenImpl
import Foundation

@main struct Codegen: ParsableCommand {
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
        try Runner(
            definitionDirectory: definitionDirectory,
            tsOut: ts_out,
            module: module,
            dependencies: dependency,
            nextjs: nextjs
        ).run()
    }
}

extension URL: ArgumentParser.ExpressibleByArgument {
    public init?(argument: String) {
        self = URL(fileURLWithPath: argument)
    }
}
