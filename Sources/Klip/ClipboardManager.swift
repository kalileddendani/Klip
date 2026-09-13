import AppKit
import Combine

/// Polls `NSPasteboard.general` on a lightweight timer and keeps a capped,
/// de-duplicated history of copied text.
final class ClipboardManager: ObservableObject {

    @Published private(set) var items: [ClipboardItem] = []

    private let maxItems = 20
    private let pollInterval: TimeInterval = 0.5
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    func startMonitoring() {
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        // Add to .common so the timer keeps firing while menus/panels are open and tracking mouse events.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Prefer plain text; fall back to any image representation (screenshots,
        // copied Finder/Preview images, pasted bitmap data, etc.).
        if let text = pasteboard.string(forType: .string) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            insert(.text(text))
        } else if let imageData = readImagePNGData(from: pasteboard) {
            insert(.image(imageData))
        }
    }

    private func readImagePNGData(from pasteboard: NSPasteboard) -> Data? {
        guard let image = NSImage(pasteboard: pasteboard),
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:])
        else { return nil }
        return png
    }

    private func insert(_ content: ClipboardContent) {
        // Ignore duplicate consecutive entries.
        if items.first?.content == content { return }

        items.insert(ClipboardItem(content: content, date: Date()), at: 0)
        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }
    }

    /// Copies an item back to the pasteboard. Updates our own change count
    /// bookkeeping first so the monitor doesn't re-insert it as "new".
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let data):
            if let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        }
        lastChangeCount = pasteboard.changeCount
    }
}
