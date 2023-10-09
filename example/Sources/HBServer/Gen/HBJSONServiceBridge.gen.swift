import Foundation
import Hummingbird

extension HBToServiceBridgeProtocol where Self == HBJSONServiceBridge {
    static var `default`: HBJSONServiceBridge { HBJSONServiceBridge() }
}

struct HBJSONServiceBridge: HBToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (HBRequest) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (HBRequest) async throws -> HBResponse
    where Req: Decodable & Sendable, Res: Encodable & Sendable
    {
        HBJSONServiceHandler(serviceBuilder: serviceBuilder, methodSelector: methodSelector)
            .callAsFunction(request:)
    }
}

private struct HBJSONServiceHandler<Service, Req, Res> where Req: Decodable & Sendable, Res: Encodable & Sendable {
    var serviceBuilder: @Sendable (HBRequest) async throws -> Service
    var methodSelector: (Service.Type) -> (Service) -> (Req) async throws -> Res

    func callAsFunction(request: HBRequest) async throws -> HBResponse {
        let service = try await serviceBuilder(request)
        guard let body = request.body.buffer else {
            throw HBHTTPError(.badRequest, message: "no body")
        }
        let rpcRequest = try makeDecoder().decode(Req.self, from: body)
        let rpcResponse = try await methodSelector(Service.self)(service)(rpcRequest)
        return try makeResponse(status: .ok, body: rpcResponse)
    }

    private func makeResponse<R: Encodable>(status: HTTPResponseStatus, body: R) throws -> HBResponse {
        let body = try makeEncoder().encodeAsByteBuffer(body, allocator: .init())
        let headers = HTTPHeaders([
            ("Content-Type", "application/json"),
            ("Cache-Control", "no-store"),
        ])
        return HBResponse(status: status, headers: headers, body: .byteBuffer(body))
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
