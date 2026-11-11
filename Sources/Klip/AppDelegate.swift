import AppKit
import ServiceManagement

/// Wires together the clipboard monitor, the floating popup panel and the
/// global hotkey. Runs as a background "agent" app (no Dock icon, no menu bar).
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var clipboardManager: ClipboardManager!
    private var popupController: PopupPanelController!
    private var hotkeyManager: HotkeyManager!
    private let settings = KlipSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-suspenders: even if Info.plist LSUIElement is missing,
        // this hides the Dock icon and menu bar at runtime.
        NSApp.setActivationPolicy(.accessory)

        clipboardManager = ClipboardManager(settings: settings)
        clipboardManager.startMonitoring()

        if settings.launchAtLogin {
            registerForLaunchAtLogin()
        }

        popupController = PopupPanelController(
            clipboardManager: clipboardManager,
            settings: settings,
            onChangeHotkey: { [weak self] shortcut in self?.changeHotkey(shortcut) },
            onChangeLaunchAtLogin: { [weak self] enabled in self?.changeLaunchAtLogin(enabled) }
        )

        hotkeyManager = HotkeyManager { [weak self] in
            self?.popupController.toggle()
        }
        let status = hotkeyManager.register(settings.hotkey)
        if status != noErr {
            clipboardManager.errorMessage = "Could not register shortcut \(settings.hotkey.title) (error \(status))."
            popupController.show()
        }

        requestAccessibilityPermissionIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func registerForLaunchAtLogin() {
        guard SMAppService.mainApp.status == .notRegistered else { return }

        do {
            try SMAppService.mainApp.register()
        } catch {
            clipboardManager.errorMessage = "Could not enable launch at login: \(error.localizedDescription)"
        }
    }

    private func changeHotkey(_ shortcut: HotkeyChoice) {
        guard shortcut != settings.hotkey else { return }
        let status = hotkeyManager.register(shortcut)
        guard status == noErr else {
            clipboardManager.errorMessage = "Could not register shortcut \(shortcut.title) (error \(status))."
            return
        }
        settings.hotkey = shortcut
    }

    private func changeLaunchAtLogin(_ enabled: Bool) {
        do {
            let service = SMAppService.mainApp
            if enabled && service.status == .notRegistered {
                try service.register()
            } else if !enabled && service.status != .notRegistered {
                try service.unregister()
            }
            settings.launchAtLogin = enabled
            if enabled && service.status == .requiresApproval {
                clipboardManager.errorMessage = "Allow Klip in System Settings > General > Login Items."
            }
        } catch {
            clipboardManager.errorMessage = "Could not change launch at login: \(error.localizedDescription)"
        }
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
