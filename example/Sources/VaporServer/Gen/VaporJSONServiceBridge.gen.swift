import Foundation
import Vapor

extension VaporToServiceBridgeProtocol where Self == VaporJSONServiceBridge {
    static var `default`: VaporJSONServiceBridge { VaporJSONServiceBridge() }
}

struct VaporJSONServiceBridge: VaporToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (Request) async throws -> Response
    where Req: Decodable & Sendable, Res: Encodable & Sendable
    {
        VaporJSONServiceHandler(serviceBuilder: serviceBuilder, methodSelector: methodSelector)
            .callAsFunction(request:)
    }
}

private struct VaporJSONServiceHandler<Service, Req, Res> where Req: Decodable & Sendable, Res: Encodable & Sendable {
    var serviceBuilder: @Sendable (Request) async throws -> Service
    var methodSelector: (Service.Type) -> (Service) -> (Req) async throws -> Res

    func callAsFunction(request: Request) async throws -> Response {
        let service = try await serviceBuilder(request)
        guard let body = request.body.data else {
            throw Abort(.badRequest, reason: "no body")
        }
        let rpcRequest = try makeDecoder().decode(Req.self, from: body)
        let rpcResponse = try await methodSelector(Service.self)(service)(rpcRequest)
        return try makeResponse(status: .ok, body: rpcResponse)
    }

    private func makeResponse<R: Encodable>(status: HTTPResponseStatus, body: R) throws -> Response {
        let body = try makeEncoder().encode(body)
        var headers = HTTPHeaders()
        headers.contentType = .json
        headers.cacheControl = .init(noStore: true)
        return Response(status: status, headers: headers, body: .init(data: body))
    }
}

private func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    return decoder
}

private func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    return encoder
}
