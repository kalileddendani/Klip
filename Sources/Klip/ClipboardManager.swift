import AppKit
import Combine

/// Polls `NSPasteboard.general` on a lightweight timer and keeps a capped,
/// de-duplicated history of copied text.
final class ClipboardManager: ObservableObject {

    @Published private(set) var items: [ClipboardItem] = []

    private let settings: KlipSettings
    private let store: HistoryStore?
    private let pollInterval: TimeInterval = 0.5
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    private var historyLoadFailed = false
    @Published var errorMessage: String?

    init(settings: KlipSettings, store: HistoryStore? = nil) {
        self.settings = settings
        if let store {
            self.store = store
        } else {
            do {
                self.store = try HistoryStore.applicationStore()
            } catch {
                self.store = nil
                errorMessage = "Could not locate history storage: \(error.localizedDescription)"
            }
        }
        if settings.persistHistory {
            do {
                guard let store = self.store else { return }
                items = try store.load()
                trimHistory()
            } catch {
                historyLoadFailed = true
                errorMessage = "Could not load clipboard history: \(error.localizedDescription)"
            }
        }
    }

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

    func insert(_ content: ClipboardContent) {
        // Ignore duplicate consecutive entries.
        if items.first(where: { !$0.isPinned })?.content == content { return }

        if settings.deduplicate, let existing = items.first(where: { $0.content == content }) {
            if existing.isPinned { return }
            items.removeAll { $0.content == content }
        }
        let index = items.firstIndex(where: { !$0.isPinned }) ?? items.endIndex
        items.insert(ClipboardItem(content: content), at: index)
        trimHistory()
        saveHistory()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = items.remove(at: index)
        updated.isPinned.toggle()
        let insertionIndex = updated.isPinned ? 0 : (items.firstIndex(where: { !$0.isPinned }) ?? items.endIndex)
        items.insert(updated, at: insertionIndex)
        trimHistory()
        saveHistory()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func applyHistoryLimit() {
        trimHistory()
        saveHistory()
    }

    func removeDuplicates() {
        var seen: [ClipboardContent] = []
        items.removeAll { item in
            if seen.contains(item.content) { return true }
            seen.append(item.content)
            return false
        }
        saveHistory()
    }

    private func trimHistory() {
        var unpinnedCount = 0
        items.removeAll { item in
            guard !item.isPinned else { return false }
            unpinnedCount += 1
            return unpinnedCount > settings.historyLimit
        }
    }

    func setPersistence(_ enabled: Bool) {
        guard let store else {
            errorMessage = "Clipboard history storage is unavailable."
            return
        }
        do {
            if enabled {
                try store.save(items)
            } else {
                try store.delete()
            }
            settings.persistHistory = enabled
            historyLoadFailed = false
        } catch {
            errorMessage = "Could not \(enabled ? "save" : "delete") clipboard history: \(error.localizedDescription)"
        }
    }

    private func saveHistory() {
        guard settings.persistHistory else { return }
        guard !historyLoadFailed else {
            errorMessage = "Clipboard history was not saved because the existing history could not be loaded."
            return
        }
        do {
            guard let store else {
                errorMessage = "Clipboard history storage is unavailable."
                return
            }
            try store.save(items)
        } catch {
            errorMessage = "Could not save clipboard history: \(error.localizedDescription)"
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
