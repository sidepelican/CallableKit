import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

enum FoundationHTTPStubClientError: Error {
    case unexpectedState
    case unexpectedStatusCode(_ code: Int)
}

struct FoundationHTTPStubResponseError: Error, CustomStringConvertible {
    var path: String
    var body: Data
    var request: URLRequest
    var response: HTTPURLResponse
    var description: String {
        "ResponseError. path=\(path), status=\(response.statusCode)"
    }
}

final class FoundationHTTPStubClient: StubClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let onWillSendRequest: (@Sendable (inout URLRequest) async throws -> Void)?
    private let mapResponseError: (@Sendable (FoundationHTTPStubResponseError) throws -> Never)?

    init(
        baseURL: URL,
        onWillSendRequest: (@Sendable (inout URLRequest) async throws -> Void)? = nil,
        mapResponseError: (@Sendable (FoundationHTTPStubResponseError) throws -> Never)? = nil
    ) {
        self.baseURL = baseURL
        session = .init(configuration: .ephemeral)
        self.onWillSendRequest = onWillSendRequest
        self.mapResponseError = mapResponseError
    }

    func send<Req: Encodable, Res: Decodable>(
        path: String,
        request: Req
    ) async throws -> Res {
        var q = URLRequest(url: baseURL.appendingPathComponent(path))
        q.httpMethod = "POST"

        q.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try makeEncoder().encode(request)
        q.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        q.httpBody = body

        if let onWillSendRequest = onWillSendRequest {
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
            throw FoundationHTTPStubClientError.unexpectedState
        }

        if 200...299 ~= urlResponse.statusCode {
            return try makeDecoder().decode(Res.self, from: data)
        } else if 400...599 ~= urlResponse.statusCode {
            let error = FoundationHTTPStubResponseError(
                path: path,
                body: data,
                request: request,
                response: urlResponse
            )
            if let mapResponseError = mapResponseError {
                try mapResponseError(error)
            } else {
                throw error
            }
        } else {
            throw FoundationHTTPStubClientError.unexpectedStatusCode(urlResponse.statusCode)
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

#if canImport(FoundationNetworking)
private class TaskBox: @unchecked Sendable {
    var task: URLSessionTask?
}

extension URLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let taskBox = TaskBox()
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
                taskBox.task = task
                task.resume()
            }
        }, onCancel: {
            taskBox.task?.cancel()
        })
    }
}
#endif
