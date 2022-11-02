import Foundation
import SwiftTypeReader

struct ServiceProtocolType {
    var name: String
    var serviceName: String

    struct Function {
        var name: String
        struct Request {
            var argName: String
            var typeName: String
            var raw: SType
        }
        var request: Request?
        struct Response {
            var typeName: String
            var raw: SType
        }
        var response: Response?
        var hasRequest: Bool {
            request != nil
        }
        var hasResponse: Bool {
            response != nil
        }
        var raw: FunctionRequirement
    }
    var functions: [Function]
    var raw: ProtocolType
}

enum ServiceProtocolScanner {
    static func scan(_ stype: SType) -> ServiceProtocolType? {
        guard let ptype = stype.protocol,
              ptype.name.hasSuffix("ServiceProtocol"),
              !ptype.functionRequirements.isEmpty
        else { return nil }

        let serviceName = ptype.name.replacingOccurrences(of: "ServiceProtocol", with: "")

        let functions = ptype.functionRequirements.compactMap { fdecl -> ServiceProtocolType.Function? in
            guard fdecl.parameters.count <= 1 else {
                print("⚠ the number of arguments must be zero or one. \(ptype.name).\(fdecl.name) is ignored.")
                return nil
            }

            return ServiceProtocolType.Function(
                name: fdecl.name,
                request: fdecl.parameters.first.map {
                    .init(argName: $0.name, typeName: $0.unresolvedType.description, raw: try! $0.type())
                },
                response: try! fdecl.unresolvedOutputType.map {
                    .init(
                        typeName: $0.description,
                        raw: try $0.resolved()  // INFO: 後段の利用のために先にresolveする。 https://github.com/omochi/CodableToTypeScript/issues/23
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
