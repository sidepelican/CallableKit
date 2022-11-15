import Foundation

public enum CodableResult<T: Codable & Sendable, E: Error & Codable>: Codable, Sendable {
    case success(T)
    case failure(E)
}
