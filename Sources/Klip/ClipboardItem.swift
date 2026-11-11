import Foundation

/// The payload of a clipboard entry: either plain text or image bytes (PNG).
enum ClipboardContent: Codable, Equatable {
    case text(String)
    case image(Data)
}

/// A single entry in the clipboard history.
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: ClipboardContent
    let date: Date
    var isPinned: Bool

    init(id: UUID = UUID(), content: ClipboardContent, date: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.date = date
        self.isPinned = isPinned
    }
}
