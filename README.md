# Klip: Clipboard Manager for macOS

[![macOS](https://img.shields.io/badge/macOS-13%2B-111827?logo=apple&logoColor=white)](https://github.com/kalileddendani/Klip)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![License](https://img.shields.io/badge/license-MIT-2ea44f)](LICENSE)

Klip is a lightweight, open-source **clipboard manager for macOS** that keeps
your recently copied text and images available in one fast clipboard history.
It is designed for people who copy and paste often and want a simple,
private alternative to repeatedly switching between apps.

Press **Command + Shift + V** anywhere to open Klip near your cursor. Select a
previous clipboard item with the mouse or keyboard and Klip copies it back to
the clipboard and pastes it into the app you were using.

## Why Klip?

Klip works quietly in the background as a macOS clipboard history tool. It has
no Dock icon and no menu bar clutter, so it stays out of the way until you
need it.

## Features

- Clipboard history for the last 20 copied items
- Supports copied text and images
- Fast search through text history
- Keyboard navigation with `Up`, `Down`, and `Enter`
- Global shortcut: `Command + Shift + V`
- Automatic paste into the previously active application
- Compact translucent popup positioned near the mouse cursor
- One-click copy and paste from clipboard history
- Duplicate consecutive clipboard entries are ignored
- Close with `Escape` or by clicking outside the popup
- Minimal clipboard-and-leaf icon
- Built with Swift, SwiftUI, and AppKit
- No third-party runtime dependencies

## Privacy

Clipboard history is kept in memory and is cleared when Klip quits. Klip does
not upload clipboard content to a server. Clipboard data can contain sensitive
information, so do not copy passwords or private keys unless you understand
the risks of keeping them in clipboard history.

## Installation

Download the latest **Klip.dmg** file from the
[GitHub Releases](https://github.com/kalileddendani/Klip/releases) page.

1. Open `Klip.dmg`.
2. Drag `Klip.app` to the `Applications` folder.
3. Open Klip from `Applications`.
4. Grant Accessibility permission under **System Settings → Privacy & Security
   → Accessibility** if you want automatic paste to work.
5. Press **Command + Shift + V** to open your clipboard history.

The current release is distributed as a DMG for a simple drag-and-drop
installation. Because the app is currently not Apple-notarized, macOS may
show a security warning the first time you open Klip.

If macOS shows the warning:

1. Open `Klip.app` once and close the warning.
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the security section.
4. Click **Open Anyway** next to the message about Klip.
5. Confirm by clicking **Open**.
