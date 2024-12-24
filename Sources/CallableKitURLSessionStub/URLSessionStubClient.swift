import CallableKit
import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

public struct URLSessionStubClient: StubClientProtocol {
    public enum UnexpectedError: Error {
        case state
        case statusCode(_ code: Int)
    }

    public struct ResponseError: Error, CustomStringConvertible {
        public var path: String
        public var body: Data
        public var request: URLRequest
        public var response: HTTPURLResponse
        public var description: String {
            "ResponseError. path=\(path), status=\(response.statusCode)"
        }
    }

    public var baseURL: URL
    public var session: URLSession
    public var onWillSendRequest: (@Sendable (inout URLRequest) async throws -> Void)?
    public var mapResponseError: (@Sendable (ResponseError) throws -> Never)?

    public init(
        baseURL: URL,
        session: URLSession = .init(configuration: .ephemeral),
        onWillSendRequest: (@Sendable (inout URLRequest) async throws -> Void)? = nil,
        mapResponseError: (@Sendable (ResponseError) throws -> Never)? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.onWillSendRequest = onWillSendRequest
        self.mapResponseError = mapResponseError
    }

    public func send<Req: Encodable, Res: Decodable>(
        path: String,
        request: Req
    ) async throws -> Res {
        var q = URLRequest(url: baseURL.appendingPathComponent(path))
        q.httpMethod = "POST"

        q.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try makeEncoder().encode(request)
        q.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        q.httpBody = body

        if let onWillSendRequest {
            try await onWillSendRequest(&q)
        }
        let (data, urlResponse) = try await session.data(for: q)
        return try handleResponse(data: data, response: urlResponse, path: path, request: q)
    }

    private func handleResponse<Res: Decodable>(
        data: Data,
        response: URLResponse,
        path: String,
        request: URLRequest
    ) throws -> Res {
        guard let urlResponse = response as? HTTPURLResponse else {
            throw UnexpectedError.state
        }

        if 200...299 ~= urlResponse.statusCode {
            return try makeDecoder().decode(Res.self, from: data)
        } else if 400...599 ~= urlResponse.statusCode {
            let error = ResponseError(
                path: path,
                body: data,
                request: request,
                response: urlResponse
            )
            if let mapResponseError {
                try mapResponseError(error)
            } else {
                throw error
            }
        } else {
            throw UnexpectedError.statusCode(urlResponse.statusCode)
        }
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

#if compiler(<6.0)
#if canImport(FoundationNetworking)
extension URLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        nonisolated(unsafe) var taskBox: URLSessionTask?
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                let task = dataTask(with: request) { data, response, error in
                    guard let data, let response else {
                        return continuation.resume(
                            throwing: error ?? URLError(.badServerResponse)
                        )
                    }
                    return continuation.resume(returning: (data, response))
                }
                taskBox = task
                task.resume()
            }
        }, onCancel: {
            taskBox?.cancel()
        })
    }
}
#endif
#endif
