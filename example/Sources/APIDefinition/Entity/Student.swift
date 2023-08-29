public struct Student: Codable, Sendable {
    public typealias ID = GenericID<Student>
    public typealias ID2 = GenericID2<Student, Int>

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
