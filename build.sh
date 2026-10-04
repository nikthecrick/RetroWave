#!/bin/bash
# RetroWave build script.
#
# This machine has the Xcode Command Line Tools but not the full Xcode app, so
# there is no `xcodebuild`. The bundle is therefore assembled by hand:
#   1. compile every Swift source with swiftc
#   2. lay out the .app Contents tree
#   3. ad-hoc code sign
#
# Usage: ./build.sh [output-dir]

set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
# Default output is ./build inside the project, so the bundle lands next to the
# sources instead of in the parent directory.
OUT_DIR="${1:-$SRC_DIR/build}"
APP_NAME="RetroWave"
APP="$OUT_DIR/$APP_NAME.app"

DEPLOY_TARGET="13.0"
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then TARGET_TRIPLE="arm64-apple-macos$DEPLOY_TARGET"; else TARGET_TRIPLE="x86_64-apple-macos$DEPLOY_TARGET"; fi

echo "==> RetroWave build"
echo "    target : $TARGET_TRIPLE"
echo "    out    : $APP"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# ---------------------------------------------------------------- compile
# Everything under the app source tree is compiled; Tools/ holds standalone
# helper scripts (top-level code) and is built separately.
SOURCES=()
while IFS= read -r -d '' f; do SOURCES+=("$f"); done < <(find "$SRC_DIR" -name '*.swift' -not -path "$SRC_DIR/Tools/*" -not -path '*/build/*' -print0 | sort)

echo "==> compiling ${#SOURCES[@]} Swift files"
swiftc \
  -parse-as-library \
  -O \
  -target "$TARGET_TRIPLE" \
  -sdk "$(xcrun --show-sdk-path)" \
  -framework SwiftUI \
  -framework AVFoundation \
  -framework AppKit \
  -o "$APP/Contents/MacOS/$APP_NAME" \
  "${SOURCES[@]}"

# ---------------------------------------------------------------- resources
cp "$SRC_DIR/Resources/Info.plist" "$APP/Contents/Info.plist"

# stations.json lives next to the sources in Models/ and ships in Resources/
STATIONS="$SRC_DIR/Models/stations.json"
if [ ! -f "$STATIONS" ]; then
  echo "!! $STATIONS missing — build would produce an empty station list" >&2
  exit 1
fi
cp "$STATIONS" "$APP/Contents/Resources/stations.json"
cp "$SRC_DIR/NOTES.md" "$APP/Contents/Resources/NOTES.md" 2>/dev/null || true

if [ -f "$SRC_DIR/Resources/AppIcon.icns" ]; then
  cp "$SRC_DIR/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

# ---------------------------------------------------------------- sign
echo "==> ad-hoc code signing"
codesign --force --deep --sign - --timestamp=none "$APP" 2>&1 | sed 's/^/    /'
codesign --verify --deep --strict "$APP" && echo "    signature OK"

# ---------------------------------------------------------------- report
echo "==> bundle contents"
find "$APP" -type f | sed "s|$APP|    $APP_NAME.app|"
echo "==> done: $APP"
du -sh "$APP" | sed 's/^/    size: /'
