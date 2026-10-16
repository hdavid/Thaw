#!/bin/bash
# Archive, Developer ID sign, notarize, staple and install the fork build.
# Notary credentials come from NOTARY_ENV (default: TraktorKontrol's .env.local).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TEAM="TZG5V3393A"
NOTARY_ENV="${NOTARY_ENV:-$HOME/GitHub/TraktorKontrol/.env.local}"
LOGDIR="$REPO/build/logs"
mkdir -p "$LOGDIR"
cd "$REPO"

# Read KEY=VALUE lines literally: the file is Makefile syntax, not shell.
env_value() { sed -n "s/^$1=//p" "$NOTARY_ENV" | tail -1; }
NOTARY_APPLE_ID="$(env_value NOTARY_APPLE_ID)"
NOTARY_TEAM_ID="$(env_value NOTARY_TEAM_ID)"
NOTARY_PASSWORD="$(env_value NOTARY_PASSWORD)"
: "${NOTARY_APPLE_ID:?missing in $NOTARY_ENV}" "${NOTARY_PASSWORD:?missing in $NOTARY_ENV}"

echo "▶ archive"
rm -rf build/Thaw.xcarchive build/export
xcodebuild archive -project Thaw.xcodeproj -scheme Thaw -configuration Release \
    -derivedDataPath build/dd -archivePath build/Thaw.xcarchive \
    DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates \
    > "$LOGDIR/archive.log" 2>&1 || { grep -E "error:" "$LOGDIR/archive.log" | sort -u; exit 1; }

echo "▶ export (developer-id)"
PLIST="$LOGDIR/ExportOptions.plist"
rm -f "$PLIST"
/usr/libexec/PlistBuddy -c "Clear dict" -c "Add :method string developer-id" \
    -c "Add :teamID string $TEAM" -c "Add :signingStyle string automatic" "$PLIST" >/dev/null 2>&1 || true
xcodebuild -exportArchive -archivePath build/Thaw.xcarchive -exportPath build/export \
    -exportOptionsPlist "$PLIST" -allowProvisioningUpdates > "$LOGDIR/export.log" 2>&1 \
    || { grep -iE "error" "$LOGDIR/export.log" | sort -u; exit 1; }
codesign --verify --deep --strict build/export/Thaw.app

echo "▶ notarize"
rm -f build/Thaw-notarize.zip
ditto -c -k --keepParent build/export/Thaw.app build/Thaw-notarize.zip
xcrun notarytool submit build/Thaw-notarize.zip --apple-id "$NOTARY_APPLE_ID" \
    --team-id "${NOTARY_TEAM_ID:-$TEAM}" --password "$NOTARY_PASSWORD" --wait \
    | grep -E "status:" | tail -1 | grep -q "Accepted" || { echo "notarization not accepted" >&2; exit 1; }
xcrun stapler staple build/export/Thaw.app >/dev/null
spctl -a -vv build/export/Thaw.app 2>&1 | grep -E "source="

echo "▶ install"
"$REPO/scripts/fork-install.sh" install
