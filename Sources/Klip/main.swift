import AppKit

// Entry point: build a plain NSApplication (no storyboard/xib) so we have
// full control over activation policy, the floating panel, and global hotkey.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
