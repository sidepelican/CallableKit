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

        let stubStruct = try StructDeclSyntax("public struct \(raw: protocolName)Stub<C: StubClientProtocol>: \(raw: protocolName), Sendable") {
            VariableDeclSyntax(
                modifiers: [.init(name: .keyword(.private))],
                .let,
                name: "client" as PatternSyntax,
                type: TypeAnnotationSyntax(type: "C" as TypeSyntax)
            )
            try InitializerDeclSyntax("public init(client: C)") {
                "self.client = client"
            }
            for function in functions {
                function
                    .with(\.leadingTrivia, [])
                    .with(\.modifiers, [.init(name: .keyword(.public))])
                    .with(\.body, CodeBlockSyntax {
                        if let param = function.signature.parameterClause.parameters.first {
                            let argName = param.secondName ?? param.firstName
                            #"return try await client.send(path: "\#(raw: serviceName)/\#(function.name)", request: \#(argName))"#
                        } else {
                            #"return try await client.send(path: "\#(raw: serviceName)/\#(function.name)")"#
                        }
                    })
            }
        }

        return [DeclSyntax(configureFunc), DeclSyntax(stubStruct)]
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
