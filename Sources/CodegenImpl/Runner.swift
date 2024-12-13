import Foundation

public struct Runner {
    public init(definitionDirectory: URL, clientOut: URL? = nil, tsOut: URL? = nil, module: String? = nil, dependencies: [URL] = [], nextjs: Bool = false) {
        self.definitionDirectory = definitionDirectory
        self.clientOut = clientOut
        self.tsOut = tsOut
        self.module = module
        self.dependencies = dependencies
        self.nextjs = nextjs
    }

    public var definitionDirectory: URL
    public var clientOut: URL?
    public var tsOut: URL?
    public var module: String?
    public var dependencies: [URL] = []
    public var nextjs: Bool = false

    public func run() throws {
        guard let module = module ?? detectModuleName(dir: definitionDirectory) else {
            throw MessageError("definitionsModuleNameNotFound")
        }

        if let clientOut {
            try GenerateSwiftClient(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: clientOut,
                dependencies: dependencies
            ).run()
        }

        if let tsOut {
            try GenerateTSClient(
                definitionModule: module,
                srcDirectory: definitionDirectory,
                dstDirectory: tsOut,
                dependencies: dependencies,
                nextjs: nextjs
            ).run()
        }
    }
}