public struct Student: Codable, Sendable {
    public typealias IDz = GenericIDz<Student>

    public init(
        id: IDz,
        name: String
    ) {
        self.id = id
        self.name = name
    }

    public var id: IDz
    public var name: String
}
