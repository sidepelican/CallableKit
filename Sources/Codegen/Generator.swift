import Foundation
import SwiftTypeReader

struct Generator {
    var srcDirectory: URL
    var dstDirectory: URL
    var fileManager = FileManager()
    var isOutputFileName: ((_ filename: String) -> Bool)?

    struct InputFile {
        var name: String
        var module: Module
    }

    struct OutputFile {
        var name: String
        var content: String
    }

    struct Input {
        var allModule: Modules
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
        let srcFiles = (fileManager.subpaths(atPath: srcDirectory.path) ?? [])
            .filter {
                !fileManager.isDirectory(at: srcDirectory.appendingPathComponent($0))
            }
        if srcFiles.isEmpty { return }
        try fileManager.createDirectory(at: dstDirectory, withIntermediateDirectories: true)

        let allModule = Modules()
        let input = Input(
            allModule: allModule,
            files: try srcFiles.map { file in
                let reader = SwiftTypeReader.Reader(modules: allModule, moduleName: file)
                let result = try reader.read(file: srcDirectory.appendingPathComponent(file), module: nil)
                return .init(name: URL(fileURLWithPath: file).lastPathComponent, module: result.module)
            }
        )

        let sink = OutputSink(dstDirectory: dstDirectory)
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
}
