#!/usr/bin/env bash
# Removes quicksearch. Your launch history is kept unless you pass --purge.
set -u

NAME="quicksearch"
systemctl --user disable --now "$NAME.service" 2>/dev/null || true
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$NAME.service"
systemctl --user daemon-reload
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/$NAME"
rm -f "$HOME/.local/bin/$NAME-toggle"
rm -f "${XDG_DATA_HOME:-$HOME/.local/share}/applications/$NAME-toggle.desktop"
command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true

if [ "${1:-}" = "--purge" ]; then
    rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/$NAME"
fi

echo "Removed. Also delete the Quicksearch Toggle shortcut in System Settings > Shortcuts."
