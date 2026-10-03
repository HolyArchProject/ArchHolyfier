#!/bin/sh
# Installs lordhelp on an existing Arch-based system.
#
#   sudo ./install.sh
#   curl -fsSL https://raw.githubusercontent.com/HolyArchProject/lordhelp-pkgmngr/main/install.sh | sudo sh
set -e

REPO_RAW=${HOLYARCH_REPO:-https://raw.githubusercontent.com/HolyArchProject/lordhelp-pkgmngr/main}
FILES="lordhelp hooks/holyarch-installed.hook hooks/holyarch-removed.hook systemd/holyarch-rebuild.service holyconfig.arch"

[ "$(id -u)" -eq 0 ] || { echo "must be run as root"; exit 1; }
command -v pacman >/dev/null || { echo "pacman not found, this only works on Arch-based systems"; exit 1; }

SRC=$(dirname "$0")
if [ ! -f "$SRC/lordhelp" ]; then
    SRC=$(mktemp -d)
    trap 'rm -rf "$SRC"' EXIT
    for f in $FILES; do
        mkdir -p "$SRC/$(dirname "$f")"
        curl -fsSL "$REPO_RAW/$f" -o "$SRC/$f"
    done
fi

pacman -S --needed --noconfirm python sudo

install -Dm755 "$SRC/lordhelp" /usr/bin/lordhelp
ln -sf lordhelp /usr/bin/rebuildconfig
install -Dm644 "$SRC/hooks/holyarch-installed.hook" /etc/pacman.d/hooks/holyarch-installed.hook
install -Dm644 "$SRC/hooks/holyarch-removed.hook" /etc/pacman.d/hooks/holyarch-removed.hook
install -Dm644 "$SRC/systemd/holyarch-rebuild.service" /etc/systemd/system/holyarch-rebuild.service
install -Dm644 "$SRC/holyconfig.arch" /usr/share/holyarch/holyconfig.example.arch
systemctl daemon-reload
systemctl enable holyarch-rebuild.service

[ -f /etc/holyarch/holyconfig.arch ] || /usr/bin/lordhelp init

for cmd in lordhelp rebuildconfig; do
    found=$(command -v "$cmd" || true)
    if [ "$(readlink -f "$found")" != "$(readlink -f "/usr/bin/$cmd")" ]; then
        echo "warning: '$cmd' resolves to $found instead of /usr/bin/$cmd"
    fi
done

echo "done, config is in /etc/holyarch/holyconfig.arch"
