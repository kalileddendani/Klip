import AppKit

/// Wires together the clipboard monitor, the floating popup panel and the
/// global hotkey. Runs as a background "agent" app (no Dock icon, no menu bar).
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var clipboardManager: ClipboardManager!
    private var popupController: PopupPanelController!
    private var hotkeyManager: HotkeyManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-suspenders: even if Info.plist LSUIElement is missing,
        // this hides the Dock icon and menu bar at runtime.
        NSApp.setActivationPolicy(.accessory)

        clipboardManager = ClipboardManager()
        clipboardManager.startMonitoring()

        popupController = PopupPanelController(clipboardManager: clipboardManager)

        hotkeyManager = HotkeyManager { [weak self] in
            self?.popupController.toggle()
        }
        hotkeyManager.register()

        requestAccessibilityPermissionIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// Accessibility permission is required to simulate the Cmd+V keystroke
    /// (auto-paste) via CGEvent. This prompts the user once and lets them
    /// grant access in System Settings > Privacy & Security > Accessibility.
    private func requestAccessibilityPermissionIfNeeded() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: [String: Any] = [promptKey: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
