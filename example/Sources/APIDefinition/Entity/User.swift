public struct User: Identifiable, Sendable, Codable, Hashable {
    public var id: ID
    public var name: String

    public init(id: User.ID, name: String) {
        self.id = id
        self.name = name
    }

    public struct ID: Hashable, RawRepresentable, Sendable, Codable {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self.init(rawValue: rawValue)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }
}
