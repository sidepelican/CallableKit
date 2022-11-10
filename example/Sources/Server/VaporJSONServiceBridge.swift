import Foundation
import Vapor

struct ErrorFrame: Encodable {
    var errorMessage: String
}

extension VaporToServiceBridgeProtocol where Self == VaporJSONServiceBridge {
    static var `default`: VaporJSONServiceBridge { VaporJSONServiceBridge() }
}

struct VaporJSONServiceBridge: VaporToServiceBridgeProtocol {
    func makeHandler<Service, Req, Res>(
        _ serviceBuilder: @Sendable @escaping (Request) async throws -> Service,
        _ methodSelector: @escaping (Service.Type) -> (Service) -> (Req) async throws -> Res
    ) -> (Request) async -> Response
    where Req: Decodable & Sendable, Res: Encodable & Sendable
    {
        VaporJSONServiceHandler(serviceBuilder: serviceBuilder, methodSelector: methodSelector)
            .callAsFunction(request:)
    }
}

private struct VaporJSONServiceHandler<Service, Req, Res> where Req: Decodable & Sendable, Res: Encodable & Sendable {
    var serviceBuilder: @Sendable (Request) async throws -> Service
    var methodSelector: (Service.Type) -> (Service) -> (Req) async throws -> Res

    func callAsFunction(request: Request) async -> Response {
        do {
            let service = try await serviceBuilder(request)
            guard let body = request.body.data else {
                let errorFrame = ErrorFrame(errorMessage: "no body")
                return try makeResponse(status: .badRequest, body: errorFrame)
            }
            let rpcRequest = try makeDecoder().decode(Req.self, from: body)
            let rpcResponse = try await methodSelector(Service.self)(service)(rpcRequest)
            return try makeResponse(status: .ok, body: rpcResponse)
        } catch let error {
            let errorFrame = ErrorFrame(errorMessage: "\(error)")
            let status: HTTPResponseStatus = .internalServerError
            return try! makeResponse(status: status, body: errorFrame)
        }
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
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = .withInternetDateTime

        for formatter in [f1, f2] {
            if let date = formatter.date(from: string) {
                return date
            }
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "vaild date formatter not found.")
    }
    return decoder
}

private func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}
