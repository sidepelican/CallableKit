import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

public struct CallableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let `protocol` = declaration.as(ProtocolDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@Callable can only be attached to protocols.")
        }

        let protocolName = `protocol`.name.trimmedDescription
        let serviceName = protocolName.trimmingSuffix("Protocol").trimmingSuffix("Service")

        let functions = `protocol`.memberBlock.members.compactMap { item in
            return item.decl.as(FunctionDeclSyntax.self)
        }

        let configureFunc = try FunctionDeclSyntax("""
        public func configure\(raw: protocolName)<\(raw: serviceName): \(raw: protocolName)>(
            transport: some ServiceTransport<\(raw: serviceName)>
        )
        """) {
            for function in functions {
                FunctionCallExprSyntax(
                    callee: "transport.register" as ExprSyntax,
                    trailingClosure: ClosureExprSyntax {
                        "$0.\(function.name)" as ExprSyntax
                    }
                ) {
                    LabeledExprSyntax(
                        label: "path",
                        expression: "\(serviceName)/\(function.name)".makeLiteralSyntax()
                    )
                }
            }
        }

        return [DeclSyntax(configureFunc)]
    }
}

extension String {
    fileprivate func trimmingSuffix(_ suffix: String) -> String {
        if self.hasSuffix(suffix) {
            var copy = self
            copy.removeLast(suffix.count)
            return copy
        }
        return self
    }
}
