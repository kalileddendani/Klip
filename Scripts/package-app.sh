#!/bin/bash
set -euo pipefail

APP_NAME="Klip"
CONFIGURATION="${CONFIGURATION:-release}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION" --product "$APP_NAME"
swift "$ROOT_DIR/Scripts/create-icon.swift"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
iconutil -c icns "$BUILD_DIR/$APP_NAME.iconset" -o "$RESOURCES_DIR/Klip.icns"
cp "$BUILD_DIR/$CONFIGURATION/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Sources/Klip/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Sources/Klip/Klip.entitlements" "$CONTENTS_DIR/"

if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
    codesign --force --deep --options runtime \
        --entitlements "$ROOT_DIR/Sources/Klip/Klip.entitlements" \
        --sign "$SIGNING_IDENTITY" "$APP_DIR"
else
    codesign --force --deep --sign - "$APP_DIR"
fi

printf 'Created %s\n' "$APP_DIR"
