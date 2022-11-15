import Foundation

extension FileManager {
    func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        if fileExists(atPath: url.path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        return false
    }
}

struct UnitStringType<Tag>:
    RawRepresentable,
    Equatable,
    Hashable,
    CustomStringConvertible,
    LosslessStringConvertible
{
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    init(rawValue: String) {
        self.rawValue = rawValue
    }

    var rawValue: String

    var description: String {
        rawValue.description
    }
}

struct MessageError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}

func detectModuleName(dir: URL) -> String? {
    dir
        .resolvingSymlinksInPath()
        .pathComponents
        .eachPairs()
        .first { (f, s) in
            f == "Sources"
        }
        .map(\.1)
}

extension Sequence {
    func eachPairs() -> AnySequence<(Element, Element)> {
        AnySequence(
            zip(self, self.dropFirst())
        )
    }
}
