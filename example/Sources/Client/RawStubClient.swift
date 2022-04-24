import APIDefinition
@preconcurrency import Foundation

fileprivate struct Empty: Codable {}

struct ErrorFrame: Decodable, CustomStringConvertible, LocalizedError {
    var errorMessage: String

    var description: String { errorMessage }
    var errorDescription: String? { description }
}

enum RawStubClientError: Error, CustomStringConvertible, LocalizedError {
    case invalidState
    case errorFrame(ErrorFrame)

    var description: String {
        switch self {
        case .invalidState:
            return "unexpected state"
        case .errorFrame(let errorFrame):
            return errorFrame.description
        }
    }
    var errorDescription: String? { description }
}

final class RawStubClient: StubClientProtocol {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL) {
        self.baseURL = baseURL
        session = .init(configuration: .ephemeral)
    }

    func send<Req: Encodable, Res: Decodable>(
        path: String,
        request: Req,
        responseType: Res.Type = Res.self
    ) async throws -> Res {
        var q = URLRequest(url: baseURL.appendingPathComponent(path))
        q.httpMethod = "POST"

        q.addValue("Bearer xxxxxxxxxxxx", forHTTPHeaderField: "Authorization")
        q.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try makeEncoder().encode(request)
        q.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        q.httpBody = body

        let (data, urlResponse) = try await session.data(for: q)
        return try Self.handleResponse(data: data, response: urlResponse, responseType: responseType)
    }

    private static func handleResponse<Res: Decodable>(
        data: Data,
        response: URLResponse,
        responseType: Res.Type = Res.self
    ) throws -> Res {
        guard let urlResponse = response as? HTTPURLResponse else {
            throw RawStubClientError.invalidState
        }

        if 200...299 ~= urlResponse.statusCode {
            if responseType == Empty.self {
                return Empty() as! Res
            }
            return try makeDecoder().decode(Res.self, from: data)
        } else if 400...599 ~= urlResponse.statusCode {
            let errorFrame = try makeDecoder().decode(ErrorFrame.self, from: data)
            throw RawStubClientError.errorFrame(errorFrame)
        } else {
            throw RawStubClientError.invalidState
        }
    }
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
