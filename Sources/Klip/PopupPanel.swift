import AppKit
import SwiftUI

/// A borderless, non-activating HUD-style panel that floats above the
/// currently active app without stealing keyboard focus from it.
final class PopupPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
    }

    // Non-activating panels can still become key (to receive clicks/typing)
    // without ever making the app itself the active/frontmost application.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }

    override func sendEvent(_ event: NSEvent) {
        guard event.type == .keyDown else {
            super.sendEvent(event)
            return
        }

        switch event.keyCode {
        case 125:
            NotificationCenter.default.post(
                name: .klipMoveSelection, object: nil, userInfo: ["direction": "down"])
        case 126:
            NotificationCenter.default.post(
                name: .klipMoveSelection, object: nil, userInfo: ["direction": "up"])
        case 36, 76:
            NotificationCenter.default.post(name: .klipConfirmSelection, object: nil)
        default:
            super.sendEvent(event)
        }
    }
}

/// Owns the panel instance, its SwiftUI content, positioning and lifecycle.
final class PopupPanelController {

    private let panel: PopupPanel
    private let clipboardManager: ClipboardManager
    private let size = NSSize(width: 320, height: 400)
    private var resignKeyObserver: NSObjectProtocol?

    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        panel = PopupPanel(contentRect: NSRect(origin: .zero, size: size))

        let visualEffect = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]

        let contentView = ContentView(clipboardManager: clipboardManager) { [weak self] item in
            self?.select(item)
        } onQuit: {
            NSApp.terminate(nil)
        }
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]

        visualEffect.addSubview(hostingView)
        panel.contentView = visualEffect

        // Close the popup as soon as the user clicks anywhere else (another
        // app's window, the desktop, etc.), i.e. when it loses key status.
        resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.hide()
        }
    }

    deinit {
        if let resignKeyObserver {
            NotificationCenter.default.removeObserver(resignKeyObserver)
        }
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        positionNearMouse()
        // makeKeyAndOrderFront on a non-activating panel does NOT bring our
        // app to the foreground, so the previously active app keeps focus.
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func positionNearMouse() {
        let mouseLocation = NSEvent.mouseLocation
        let screen =
            NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main

        var origin = NSPoint(x: mouseLocation.x, y: mouseLocation.y - size.height)

        if let visibleFrame = screen?.visibleFrame {
            origin.x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - size.width)
            origin.y = min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - size.height)
        }

        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func select(_ item: ClipboardItem) {
        clipboardManager.copyToPasteboard(item)
        hide()
        // Small delay lets the target app regain key focus/state before we post keystrokes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            PasteSimulator.simulatePaste()
        }
    }
}
