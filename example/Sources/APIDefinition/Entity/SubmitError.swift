import Foundation

public struct InputFieldError<E: RawRepresentable & Codable>: Codable where E.RawValue == String {
    public init(name: E, message: String) {
        self.name = name
        self.message = message
    }

    public var name: E
    public var message: String
}

public struct SubmitError<E: RawRepresentable & Codable>: Error, Codable where E.RawValue == String {
    public init(errors: [InputFieldError<E>]) {
        self.errors = errors
    }

    public var errors: [InputFieldError<E>]
}
