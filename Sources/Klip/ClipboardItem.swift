import Foundation

/// The payload of a clipboard entry: either plain text or image bytes (PNG).
enum ClipboardContent: Equatable {
    case text(String)
    case image(Data)
}

/// A single entry in the clipboard history.
struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: ClipboardContent
    let date: Date
}
