#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
APP_DIR="$ROOT_DIR/dist/Klip.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DMG_ROOT="$ROOT_DIR/.build/dmg-root"
OUTPUT="$ROOT_DIR/dist/Klip.dmg"
VERSION="${VERSION:-0.0.0}"
VERSION="${VERSION#v}"

cd "$ROOT_DIR"
swift build -c release --product Klip
swift "$ROOT_DIR/Scripts/create-icon.swift"

rm -rf "$APP_DIR" "$DMG_ROOT" "$OUTPUT"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$DMG_ROOT"
iconutil -c icns "$BUILD_DIR/Klip.iconset" -o "$RESOURCES_DIR/Klip.icns"
cp "$BUILD_DIR/release/Klip" "$MACOS_DIR/Klip"
cp "$ROOT_DIR/Sources/Klip/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Sources/Klip/Klip.entitlements" "$CONTENTS_DIR/"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS_DIR/Info.plist"

codesign --force --deep --sign - "$APP_DIR"

mkdir -p "$DMG_ROOT"
cp -R "$ROOT_DIR/dist/Klip.app" "$DMG_ROOT/Klip.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
    -volname "Klip" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$OUTPUT"

printf 'Created %s\n' "$OUTPUT"
