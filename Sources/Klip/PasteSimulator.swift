import AppKit
import ApplicationServices

/// Simulates a Cmd+V keystroke into the frontmost application using CGEvent.
/// Requires the app to be granted Accessibility permission.
enum PasteSimulator {

    static func simulatePaste() {
        guard AXIsProcessTrusted() else { return }

        let source = CGEventSource(stateID: .hidSystemState)

        let vKeyCode: CGKeyCode = 0x09  // kVK_ANSI_V
        let cmdKeyCode: CGKeyCode = 0x37  // kVK_Command

        guard
            let cmdDown = CGEvent(
                keyboardEventSource: source, virtualKey: cmdKeyCode, keyDown: true),
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false),
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: cmdKeyCode, keyDown: false)
        else { return }

        vDown.flags = .maskCommand
        vUp.flags = .maskCommand

        let tap = CGEventTapLocation.cghidEventTap
        cmdDown.post(tap: tap)
        vDown.post(tap: tap)
        vUp.post(tap: tap)
        cmdUp.post(tap: tap)
    }
}
