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
