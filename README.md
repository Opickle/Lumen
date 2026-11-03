# Lumen

A fast, minimal app launcher for KDE Plasma (Wayland) built with
[Quickshell](https://quickshell.org). Shows your recently launched apps
with "x hours ago" timestamps, and filters installed apps as you type.

Full step-by-step guide: [INSTRUCTIONS.txt](INSTRUCTIONS.txt)

## Requirements

- Arch Linux (or any distro with Quickshell)
- KDE Plasma 6 on Wayland
- `quickshell`

## Install

```bash
yay -S quickshell
git clone https://github.com/Opickle/Lumen.git
cd Lumen
bash install.sh
```

Then bind a key: **System Settings > Shortcuts > Add Application >
"Lumen Toggle"**, and assign a key (e.g. Alt+Space). Click Apply.

## Usage

| Key | Action |
|-----|--------|
| shortcut | open / close |
| type | filter apps |
| Up / Down | move selection |
| Enter | launch |
| Esc | close |

Recently launched apps appear when the search box is empty, so the list
fills up as you use it.

## Customize

Edit the `SETTINGS` block at the top of
`~/.config/quickshell/lumen/shell.qml`, then restart:

```bash
systemctl --user restart lumen
```

## Troubleshooting

```bash
systemctl --user status lumen
journalctl --user -u lumen -n 30
qs -c lumen ipc call launcher toggle   # test without the shortcut
```

## Uninstall

```bash
bash uninstall.sh          # keeps launch history
bash uninstall.sh --purge  # also deletes history
```

## License

Public domain (Unlicense).
