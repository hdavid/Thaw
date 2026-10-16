#!/bin/bash
# Swap the fork's Release build into /Applications, or put the official build back.
# Usage: scripts/fork-install.sh [install|restore]
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILT="$REPO/build/dd/Build/Products/Release/Thaw.app"
TARGET="/Applications/Thaw.app"
BACKUP="$HOME/GitHub/Thaw-official-backup.app"

quit_thaw() {
    osascript -e 'tell application id "com.stonerl.Thaw" to quit' 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -x Thaw >/dev/null || return 0; sleep 0.5; done
    pkill -x Thaw || true
}

case "${1:-install}" in
install)
    [ -d "$BUILT" ] || { echo "No build at $BUILT" >&2; exit 1; }
    quit_thaw
    if [ ! -d "$BACKUP" ]; then
        ditto "$TARGET" "$BACKUP"
        echo "Backed up the official app to $BACKUP"
    fi
    rm -rf "$TARGET"
    ditto "$BUILT" "$TARGET"
    defaults write com.stonerl.Thaw EnableDiagnosticLogging -bool true
    open "$TARGET"
    echo "Fork build installed. Logs: ~/Library/Logs/Thaw/"
    ;;
restore)
    [ -d "$BACKUP" ] || { echo "No backup at $BACKUP" >&2; exit 1; }
    quit_thaw
    rm -rf "$TARGET"
    ditto "$BACKUP" "$TARGET"
    open "$TARGET"
    echo "Official build restored."
    ;;
*)
    echo "Usage: $0 [install|restore]" >&2
    exit 64
    ;;
esac
