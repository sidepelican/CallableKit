import PackagePlugin
import Foundation

@main
struct CodegenPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let codegenTool = try context.tool(named: "codegen")
        let codegenExec = URL(fileURLWithPath: codegenTool.path.string)

        let arguments: [String] = [
            "Sources/APIDefinition",
            "--client_out", "Sources/Client/Gen",
            "--vapor_out", "Sources/Server/Gen",
            "--ts_out", "TSClient/src/Gen",
            "--dependency", "Sources/OtherDependency",
        ]

        let process = try Process.run(codegenExec, arguments: arguments)
        process.waitUntilExit()

        if process.terminationReason == .exit && process.terminationStatus == 0 {
            // ok. do nothing
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("codegen invocation failed: \(problem)")
        }
    }
}
