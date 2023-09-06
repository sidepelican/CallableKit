public struct Student: Codable, Sendable {
    public typealias ID = GenericID<Student>

    public init(id: ID, name: String) {
        self.id = id
        self.name = name
    }
    public var id: ID
    public var name: String
}

public struct Student2: Codable, Sendable {
    public typealias ID = GenericID2<Student2, String>

    public init(id: ID, name: String) {
        self.id = id
        self.name = name
    }
    public var id: ID
    public var name: String
}

public struct Student3: Codable, Sendable {
    public typealias ID = GenericID3<Student3>

    public init(id: ID, name: String) {
        self.id = id
        self.name = name
    }
    public var id: ID
    public var name: String
}

public struct Student4: Codable, Sendable {
    public typealias ID = GenericID2<Student4, GenericID2<Student4, MyValue>>

    public init(id: ID, name: String) {
        self.id = id
        self.name = name
    }
    public var id: ID
    public var name: String
}
