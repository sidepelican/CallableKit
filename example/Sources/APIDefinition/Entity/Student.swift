public struct Student: Codable, Sendable {
    public typealias ID = GenericID<Student>

    public init(
        id: ID,
        name: String
    ) {
        self.id = id
        self.name = name
    }

    public var id: ID
    public var name: String
}
