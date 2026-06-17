#!/bin/bash
#
# make_dmg.sh
# Builds NotchFlow.app and packages it into a styled drag-to-Applications DMG.
# No external tools — uses hdiutil + Finder (AppleScript) for the layout.
#
# Output: build/NotchFlow.dmg
#

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="NotchFlow"
VOL_NAME="NotchFlow"
BUILD="$ROOT/build"
APP="$BUILD/$APP_NAME.app"
STAGE="$BUILD/dmg-stage"
BG="$BUILD/dmg-bg.png"
RW_DMG="$BUILD/rw.dmg"
FINAL_DMG="$BUILD/$APP_NAME.dmg"

# 1. Build the app bundle.
"$ROOT/scripts/make_app_bundle.sh" >/dev/null
[ -d "$APP" ] || { echo "app bundle missing"; exit 1; }

# 2. Render the background art.
swift tools/make_dmg_bg.swift "$BG" >/dev/null

# 3. Staging folder: app + /Applications symlink + hidden background.
rm -rf "$STAGE"; mkdir -p "$STAGE/.background"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp "$BG" "$STAGE/.background/background.png"

# 4. Create a writable DMG from the staging folder.
rm -f "$RW_DMG" "$FINAL_DMG"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE" \
    -fs HFS+ -format UDRW -ov "$RW_DMG" >/dev/null

# 5. Mount and style with Finder.
MOUNT="/Volumes/$VOL_NAME"
hdiutil detach "$MOUNT" >/dev/null 2>&1 || true
hdiutil attach "$RW_DMG" -mountpoint "$MOUNT" -nobrowse >/dev/null

echo "==> Styling DMG window (Finder)…"
osascript <<EOF || true
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set theWin to container window
        set current view of theWin to icon view
        set toolbar visible of theWin to false
        set statusbar visible of theWin to false
        set bounds of theWin to {200, 120, 860, 540}
        set vOpts to icon view options of theWin
        set arrangement of vOpts to not arranged
        set icon size of vOpts to 120
        set background picture of vOpts to file ".background:background.png"
        set position of item "$APP_NAME.app" of theWin to {165, 230}
        set position of item "Applications" of theWin to {495, 230}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

sync
hdiutil detach "$MOUNT" >/dev/null 2>&1 || true

# 6. Convert to compressed, read-only DMG.
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG" >/dev/null
rm -f "$RW_DMG"

# 7. Ad-hoc sign the DMG so it has a stable identity.
codesign --force --sign - "$FINAL_DMG" 2>/dev/null || true

echo ""
echo "✅ $FINAL_DMG"
ls -lh "$FINAL_DMG" | awk '{print "   size:", $5}'
