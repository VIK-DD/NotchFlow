#!/bin/bash
#
# make_app_bundle.sh
# Builds NotchFlow in release mode and packages it into a distributable,
# ad-hoc-signed NotchFlow.app bundle.
#
# Usage:
#   ./scripts/make_app_bundle.sh
#
# The resulting bundle is written to ./build/NotchFlow.app
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="NotchFlow"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"

echo "==> Building release binary…"
# Try a universal (Apple Silicon + Intel) binary first; fall back to host arch.
if swift build -c release --arch arm64 --arch x86_64 >/dev/null 2>&1; then
    echo "    Built universal (arm64 + x86_64)."
    BIN_PATH="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/$APP_NAME"
else
    echo "    Universal build unavailable on this toolchain; building host arch."
    swift build -c release
    BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"
fi

echo "==> Assembling app bundle…"
rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

cp "$BIN_PATH" "$CONTENTS/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"

# App icon (regenerate if missing).
if [ ! -f "$ROOT/Resources/AppIcon.icns" ]; then
    echo "    Generating app icon…"
    "$ROOT/scripts/make_icns.sh" >/dev/null
fi
cp "$ROOT/Resources/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"

echo "==> Ad-hoc code signing…"
# A stable (even ad-hoc) signature lets macOS remember the Automation permission
# and use launch-at-login reliably.
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "✅ Done: $APP_BUNDLE"
echo ""
echo "Next steps:"
echo "  • Launch:        open \"$APP_BUNDLE\""
echo "  • Install:       cp -R \"$APP_BUNDLE\" /Applications/"
echo "  • First run will ask permission to control Spotify — click OK."
