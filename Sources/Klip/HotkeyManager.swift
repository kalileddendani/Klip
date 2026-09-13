import AppKit
import Carbon

/// Registers a system-wide hotkey (default: Cmd+Shift+V) using the Carbon
/// Event Manager. Carbon hotkeys work even though the app has no windows,
/// no Dock icon and never becomes the active app.
final class HotkeyManager {

    private static var registry: [UInt32: HotkeyManager] = [:]

    private let action: () -> Void
    private let hotKeyID: UInt32 = 1
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func register() {
        Self.registry[hotKeyID] = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                HotkeyManager.registry[hkID.id]?.action()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        let keyCodeV: UInt32 = 9  // kVK_ANSI_V
        let modifiers = UInt32(cmdKey | shiftKey)
        let carbonHotKeyID = EventHotKeyID(signature: OSType(0x4B4C_4950), id: hotKeyID)  // 'KLIP'

        RegisterEventHotKey(
            keyCodeV,
            modifiers,
            carbonHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        Self.registry[hotKeyID] = nil
    }

    deinit {
        unregister()
    }
}
