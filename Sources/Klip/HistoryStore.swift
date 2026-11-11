import Foundation

struct HistoryStore {
    let directory: URL
    private var file: URL { directory.appendingPathComponent("history.json") }

    static func applicationStore() throws -> HistoryStore {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        return HistoryStore(directory: base.appendingPathComponent("Klip", isDirectory: true))
    }

    func load() throws -> [ClipboardItem] {
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        return try JSONDecoder().decode([ClipboardItem].self, from: Data(contentsOf: file))
    }

    func save(_ items: [ClipboardItem]) throws {
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        try JSONEncoder().encode(items).write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }

    func delete() throws {
        guard FileManager.default.fileExists(atPath: file.path) else { return }
        try FileManager.default.removeItem(at: file)
    }
}
