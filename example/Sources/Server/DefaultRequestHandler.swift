import APIDefinition
import Foundation
import Vapor

struct ErrorFrame: Encodable {
    var errorMessage: String
}

private func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    let f1 = ISO8601DateFormatter()
    f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let f2 = ISO8601DateFormatter()
    f2.formatOptions = .withInternetDateTime
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
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

struct DefaultHandler: RawRequestHandler {
    func makeHandler<Req: Decodable & Sendable, Res: Encodable & Sendable, Service>(
        _ makeService: @escaping (Request) -> Service,
        _ callMethod: @Sendable @escaping (Service, Req) async throws -> (Res)
    ) -> (Request) async -> Response {
        { request in
            do {
                guard let body = request.body.data else {
                    let errorFrame = ErrorFrame(errorMessage: "no body")
                    return try makeResponse(status: .badRequest, body: errorFrame)
                }
                let rpcRequest = try makeDecoder().decode(Req.self, from: body)
                let service = makeService(request)
                let rpcResponse = try await callMethod(service, rpcRequest)
                return try makeResponse(status: .ok, body: rpcResponse)
            } catch let error {
                let errorFrame = ErrorFrame(errorMessage: "\(error)")
                let status: HTTPResponseStatus = .internalServerError
                return try! makeResponse(status: status, body: errorFrame)
            }
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

extension RawRequestHandler where Self == DefaultHandler {
    static var `default`: DefaultHandler { DefaultHandler() }
}
