public struct GenericIDz<T>: Codable & RawRepresentable {
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var rawValue: String
}
