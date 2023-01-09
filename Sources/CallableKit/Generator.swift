import Foundation
import SwiftTypeReader

struct Generator {
    var definitionModule: String
    var srcDirectory: URL
    var dstDirectory: URL
    var dependencies: [URL]
    var fileManager = FileManager()
    var isOutputFileName: ((_ filename: String) -> Bool)?

    typealias InputFile = SwiftTypeReader.SourceFile

    struct OutputFile {
        var name: String
        var content: String
    }

    struct Input {
        var context: SwiftTypeReader.Context
        var files: [InputFile]
    }

    class OutputSink {
        public init(dstDirectory: URL, fileManager: FileManager) {
            self.dstDirectory = dstDirectory
            self.fileManager = fileManager
        }

        var files: Set<String> = []
        var dstDirectory: URL
        var fileManager: FileManager

        func callAsFunction(file: OutputFile) throws {
            let dst = dstDirectory.appendingPathComponent(file.name)
            try fileManager.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
            try file.content.data(using: .utf8)!
                .write(to: dstDirectory.appendingPathComponent(file.name), options: .atomic)
            print("generated...", file.name)
            files.insert(file.name)
        }
    }

    func run(_ perform: (Input, _ write: OutputSink) throws -> ()) throws {
        let context = SwiftTypeReader.Context()

        var inputFiles: [InputFile] = []
        let sources = try SwiftTypeReader.Reader(
            context: context,
            module: context.getOrCreateModule(name: definitionModule)
        )
        .read(directory: srcDirectory)
        inputFiles.append(contentsOf: sources)
        for dependency in dependencies {
            let module = context.getOrCreateModule(
                name: detectModuleName(dir: dependency) ?? dependency.lastPathComponent
            )
            let sources = try SwiftTypeReader.Reader(context: context,module: module)
                .read(directory: dependency)
            inputFiles.append(contentsOf: sources)
        }

        let input = Input(context: context, files: inputFiles)
        let sink = OutputSink(dstDirectory: dstDirectory, fileManager: fileManager)
        try fileManager.createDirectory(at: dstDirectory, withIntermediateDirectories: true)
        try perform(input, sink)

        // リネームなどによって不要になった生成物を出力ディレクトリから削除
        for dstFile in try findFiles(in: dstDirectory) {
            if let isOutputFileName = isOutputFileName, !isOutputFileName(URL(fileURLWithPath: dstFile).lastPathComponent) {
                continue
            }
            if !sink.files.contains(dstFile) {
                let path = dstDirectory.appendingPathComponent(dstFile)
                try fileManager.removeItem(at: path)
                print("removed...", path.relativePath)
            }
        }
        // 空のディレクトリを削除
        for dstFile in try fileManager.subpathsOfDirectory(atPath: dstDirectory.path) {
            let path = dstDirectory.appendingPathComponent(dstFile)
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: path.path, isDirectory: &isDir),
               isDir.boolValue,
               try fileManager.contentsOfDirectory(atPath: path.path).isEmpty
            {
                try fileManager.removeItem(at: path)
                print("removed...", path.relativePath)
            }
        }
    }

    private func findFiles(in directory: URL) throws -> [String] {
        try fileManager.subpathsOfDirectory(atPath: directory.path)
            .filter {
                !fileManager.isDirectory(at: directory.appendingPathComponent($0))
            }
    }
}
