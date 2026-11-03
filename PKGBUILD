# Maintainer: Opickle
pkgname=lumen
pkgver=0.1.0
pkgrel=1
pkgdesc="A Windows-inspired application launcher for KDE Plasma, built with Quickshell"
arch=('any')
url="https://github.com/Opickle/Lumen"
license=('Unlicense')
depends=('quickshell')
optdepends=(
  'dolphin: file manager quick action'
  'wireplumber: volume and microphone quick actions (wpctl)'
  'brightnessctl: brightness quick actions'
  'networkmanager: Wi-Fi quick actions (nmcli)'
  'bluez-utils: Bluetooth quick actions (bluetoothctl)'
)
makedepends=('git')
source=("lumen::git+https://github.com/Opickle/Lumen.git#commit=ac5a3a6b13673ecb89311c69ad181dbffee3adf6")
sha256sums=('SKIP')

package() {
  cd "$srcdir/lumen"

  # System-wide Quickshell configuration, following Quickshell's packaging guidance.
  install -Dm644 shell.qml "$pkgdir/etc/xdg/quickshell/lumen/shell.qml"

  # Toggle command.
  install -Dm755 packaging/lumen "$pkgdir/usr/bin/lumen"

  # Optional user service; users can enable it themselves.
  install -Dm644 packaging/lumen.service "$pkgdir/usr/lib/systemd/user/lumen.service"

  # KDE application shortcut, also usable for assigning a keyboard shortcut.
  install -Dm644 packaging/lumen.desktop "$pkgdir/usr/share/applications/lumen.desktop"

  # License.
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
