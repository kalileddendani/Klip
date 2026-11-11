import Carbon
import Foundation

enum HotkeyChoice: String, CaseIterable, Identifiable {
    case commandShiftV, commandOptionV, controlOptionV, controlShiftV

    var id: String { rawValue }
    var title: String {
        switch self {
        case .commandShiftV: return "⌘⇧V"
        case .commandOptionV: return "⌥⌘V"
        case .controlOptionV: return "⌃⌥V"
        case .controlShiftV: return "⌃⇧V"
        }
    }
    var modifiers: UInt32 {
        switch self {
        case .commandShiftV: return UInt32(cmdKey | shiftKey)
        case .commandOptionV: return UInt32(cmdKey | optionKey)
        case .controlOptionV: return UInt32(controlKey | optionKey)
        case .controlShiftV: return UInt32(controlKey | shiftKey)
        }
    }
}

final class KlipSettings: ObservableObject {
    private let defaults: UserDefaults

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    @Published var hotkey: HotkeyChoice {
        didSet { defaults.set(hotkey.rawValue, forKey: "hotkey") }
    }
    @Published var historyLimit: Int {
        didSet { defaults.set(historyLimit, forKey: "historyLimit") }
    }
    @Published var deduplicate: Bool {
        didSet { defaults.set(deduplicate, forKey: "deduplicate") }
    }
    @Published var persistHistory: Bool {
        didSet { defaults.set(persistHistory, forKey: "persistHistory") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? true
        hotkey = HotkeyChoice(rawValue: defaults.string(forKey: "hotkey") ?? "") ?? .commandShiftV
        let savedLimit = defaults.integer(forKey: "historyLimit")
        historyLimit = savedLimit > 0 ? min(savedLimit, 200) : 20
        deduplicate = defaults.bool(forKey: "deduplicate")
        persistHistory = defaults.bool(forKey: "persistHistory")
    }
}
