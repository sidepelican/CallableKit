import Foundation
import SwiftTypeReader

struct Generator {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]
    var fileManager = FileManager()
    var isOutputFileName: ((_ filename: String) -> Bool)?

    struct InputFile {
        var name: URL
        var module: Module
        var types: [SType]
        var imports: [ImportDecl]
    }

    struct OutputFile {
        var name: String
        var content: String
    }

    struct Input {
        var context: SwiftTypeReader.Context
        var files: [InputFile]
    }

    class OutputSink {
        public init(dstDirectory: URL) {
            self.dstDirectory = dstDirectory
        }

        var files: Set<String> = []
        var dstDirectory: URL

        func callAsFunction(file: OutputFile) throws {
            print("generated...", file.name)
            try file.content.data(using: .utf8)!
                .write(to: dstDirectory.appendingPathComponent(file.name), options: .atomic)

            files.insert(file.name)
        }
    }

    func run(_ perform: (Input, _ write: OutputSink) throws -> ()) throws {
        let context = SwiftTypeReader.Context()

        _ = try SwiftTypeReader.Reader(
            context: context,
            module: context.getOrCreateModule(name: definitionModule)
        )
        .read(file: srcDirectory)
        for dependency in dependencies {
            let module = context.getOrCreateModule(
                name: detectModuleName(dir: dependency) ?? dependency.lastPathComponent
            )
            _ = try SwiftTypeReader.Reader(context: context,module: module)
                .read(file: dependency)
        }

        let inputFiles = context.modules
            .filter { $0.name != "Swift" }
            .flatMap { module -> [InputFile] in
                let typeMap = [URL: [SType]](grouping: module.types, by: { $0.asSpecifier().file! })
                let importMap = [URL: [ImportDecl]](grouping: module.imports, by: { $0.file! })
                return typeMap.map { (file, types) in
                    InputFile(name: file, module: module, types: types, imports: importMap[file] ?? [])
                }
            }

        let input = Input(context: context, files: inputFiles)
        let sink = OutputSink(dstDirectory: dstDirectory)
        try fileManager.createDirectory(at: dstDirectory, withIntermediateDirectories: true)
        try perform(input, sink)

        // リネームなどによって不要になった生成物を出力ディレクトリから削除
        for dstFile in try fileManager.subpathsOfDirectory(atPath: dstDirectory.path) {
            if let isOutputFileName = isOutputFileName, !isOutputFileName(URL(fileURLWithPath: dstFile).lastPathComponent) {
                continue
            }
            if !sink.files.contains(dstFile) {
                try fileManager.removeItem(at: dstDirectory.appendingPathComponent(dstFile))
            }
        }
    }

    private func findFiles(in directory: URL) -> [String] {
        (fileManager.subpaths(atPath: directory.path) ?? [])
            .filter {
                !fileManager.isDirectory(at: directory.appendingPathComponent($0))
            }
    }
}
