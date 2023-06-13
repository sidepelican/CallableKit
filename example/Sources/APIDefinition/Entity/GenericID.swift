public struct GenericIDz<T>: Codable & RawRepresentable & Sendable {
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var rawValue: String
}
