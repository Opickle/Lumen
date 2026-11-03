#!/usr/bin/env bash
# Installs Lumen for the current user. No sudo needed.
set -euo pipefail

NAME="lumen"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/$NAME"
BIN_DIR="$HOME/.local/bin"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
SVC_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/$NAME"

if ! command -v qs >/dev/null 2>&1; then
    echo "Quickshell (qs) was not found. Install it first, e.g.: yay -S quickshell" >&2
    exit 1
fi
QS_PATH="$(command -v qs)"

echo "==> Copying config to $CONF_DIR"
mkdir -p "$CONF_DIR" "$BIN_DIR" "$APP_DIR" "$SVC_DIR" "$STATE_DIR"
install -m 644 "$SRC_DIR/shell.qml" "$CONF_DIR/shell.qml"

echo "==> Writing toggle script to $BIN_DIR/$NAME-toggle"
cat > "$BIN_DIR/$NAME-toggle" <<SCRIPT
#!/bin/sh
# Toggles the launcher. Starts Quickshell first if it is not running.
if ! $QS_PATH -c $NAME ipc call launcher toggle >/dev/null 2>&1; then
    $QS_PATH -c $NAME -d
    sleep 1
    $QS_PATH -c $NAME ipc call launcher toggle
fi
SCRIPT
chmod +x "$BIN_DIR/$NAME-toggle"

echo "==> Writing desktop entry (used for the KDE shortcut)"
cat > "$APP_DIR/$NAME-toggle.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Lumen Toggle
Comment=Open or close the Lumen launcher
Exec=sh $BIN_DIR/$NAME-toggle
Terminal=false
DESKTOP
command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true

echo "==> Setting up autostart (systemd user service)"
cat > "$SVC_DIR/$NAME.service" <<SERVICE
[Unit]
Description=Lumen launcher (Quickshell)
After=graphical-session.target
PartOf=graphical-session.target

[Service]
ExecStart=$QS_PATH -c $NAME
Restart=on-failure

[Install]
WantedBy=graphical-session.target
SERVICE
systemctl --user daemon-reload
systemctl --user enable "$NAME.service"
systemctl --user restart "$NAME.service"

cat <<DONE

Installed.

Last step (manual): bind a key in
  System Settings > Shortcuts > Add Application > "Lumen Toggle"

Check it is running:   systemctl --user status $NAME
See errors:            journalctl --user -u $NAME -n 30
DONE
