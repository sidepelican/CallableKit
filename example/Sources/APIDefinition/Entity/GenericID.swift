public struct GenericID<T>: Codable & RawRepresentable & Sendable {
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var rawValue: String
}

public struct GenericID2<_IDSpecifier, RawValue: Sendable & Hashable & Codable>: RawRepresentable, Sendable, Hashable, Codable {
    public var rawValue: RawValue { id }

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}
