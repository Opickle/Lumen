# quicksearch

A fast, minimal app launcher for KDE Plasma (Wayland) built with
[Quickshell](https://quickshell.org). Shows your recently launched apps
with "x hours ago" timestamps, and filters installed apps as you type.

## Requirements

- Arch Linux (or any distro with Quickshell)
- KDE Plasma 6 on Wayland
- `quickshell`

## Install

```bash
yay -S quickshell
git clone https://github.com/Opickle/quicksearch.git
cd quicksearch
./install.sh
```

Then bind a key: **System Settings > Shortcuts > Add Application >
"Quicksearch Toggle"**, and assign a key (e.g. Alt+Space).

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
`~/.config/quickshell/quicksearch/shell.qml` (colors, size, position,
number of results), then restart:

```bash
systemctl --user restart quicksearch
```

## Troubleshooting

```bash
systemctl --user status quicksearch
journalctl --user -u quicksearch -n 30
qs -c quicksearch ipc call launcher toggle   # test without the shortcut
```

## Uninstall

```bash
./uninstall.sh          # keeps launch history
./uninstall.sh --purge  # also deletes history
```

## License

MIT
