import Foundation
import SwiftTypeReader

struct ServiceProtocolType {
    var name: String
    var serviceName: String

    struct Function {
        var name: String
        struct Request {
            var argOuterName: String?
            var argName: String
            var typeName: String
            var raw: any SType
        }
        var request: Request?
        struct Response {
            var typeName: String
            var raw: any SType
        }
        var response: Response?
        var hasRequest: Bool {
            request != nil
        }
        var hasResponse: Bool {
            response != nil
        }
        var raw: FuncDecl
    }
    var functions: [Function]
    var raw: ProtocolType
}

enum ServiceProtocolScanner {
    static func scan(_ decl: any TypeDecl) -> ServiceProtocolType? {
        scan(decl.declaredInterfaceType)
    }

    static func scan(_ stype: any SType) -> ServiceProtocolType? {
        guard let ptype = stype as? ProtocolType,
              ptype.decl.attributes.contains(where: { $0.name == "Callable" }),
              !ptype.decl.functions.isEmpty
        else { return nil }

        let serviceName = ptype.name.trimmingSuffix("Protocol").trimmingSuffix("Service")

        let functions = ptype.decl.functions.compactMap { fdecl -> ServiceProtocolType.Function? in
            guard fdecl.parameters.count <= 1 else {
                print("⚠ the number of arguments must be zero or one. \(ptype.name).\(fdecl.name) is ignored.")
                return nil
            }

            return ServiceProtocolType.Function(
                name: fdecl.name,
                request: fdecl.parameters.first.map {
                    .init(argOuterName: $0.outerName, argName: $0.name!, typeName: $0.interfaceType.description, raw: $0.interfaceType)
                },
                response: fdecl.resultTypeRepr.map {
                    .init(
                        typeName: $0.description,
                        raw: $0.resolve(from: fdecl)
                    )
                },
                raw: fdecl
            )
        }

        if functions.isEmpty {
            return nil
        }

        return ServiceProtocolType(
            name: ptype.name,
            serviceName: serviceName,
            functions: functions,
            raw: ptype
        )
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
