# Klip

Klip is a lightweight, open-source clipboard manager for macOS.

It runs quietly in the background without a Dock icon or menu bar item. Press
**⌘⇧V** anywhere to open the clipboard history near your cursor.

## Features

- Stores the last 20 copied text items and images
- Ignores consecutive duplicates
- Displays history in a compact translucent popup
- Keeps the active application focused
- Click an item to copy and automatically paste it
- Press `Escape` or click outside the popup to close it
- Supports image previews and restoring images to the clipboard
- Includes a minimal clipboard-and-leaf app icon

Klip is built with Swift, SwiftUI and AppKit and uses no third-party runtime
dependencies.

## Local Test

```bash
./Scripts/package-app.sh
open dist/Klip.app
```

Automatic paste requires Klip to be enabled under **System Settings → Privacy
& Security → Accessibility**.
