public struct GenericID<T>: Codable & RawRepresentable & Sendable {
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var rawValue: String
}

public struct GenericID2<_IDSpecifier, RawValue: Sendable & Codable>: RawRepresentable, Sendable, Codable {
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public var rawValue: RawValue
}

public enum MyValue: Codable, Sendable {
    case id(String)
    case none
}

public struct GenericID3<T>: Codable & RawRepresentable & Sendable {
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    public typealias RawValue = MyValue
    public var rawValue: RawValue
}
