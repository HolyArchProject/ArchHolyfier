#!/bin/bash
# Builds the HolyArch ISO from archiso's releng profile.
# Needs Arch Linux. Run with: sudo ./build-iso.sh
set -euo pipefail
cd "$(dirname "$0")"

ROOT=$PWD
WORK=$ROOT/build
PROFILE=$WORK/profile
REPO=$PROFILE/airootfs/opt/holyarch-repo
PKGDIR=$WORK/pkg

[[ $EUID -eq 0 ]] || { echo "must be run as root"; exit 1; }
[[ -n ${SUDO_USER:-} ]] || { echo "run through sudo, makepkg needs a normal user"; exit 1; }

pacman -S --needed --noconfirm archiso base-devel

rm -rf "$WORK"
mkdir -p "$WORK" "$PKGDIR" "$REPO"
cp -r /usr/share/archiso/configs/releng "$PROFILE"

# build the holyarch package
cp packaging/PKGBUILD packaging/holyarch.install lordhelp holyconfig.arch \
   hooks/*.hook systemd/*.service "$PKGDIR"
chown -R "$SUDO_USER" "$PKGDIR"
sudo -u "$SUDO_USER" bash -c "cd '$PKGDIR' && makepkg -f --noconfirm"

# local repo shipped on the ISO, so pacstrap can install holyarch offline
cp "$PKGDIR"/holyarch-*.pkg.tar.zst "$REPO/"
repo-add "$REPO/holyarch.db.tar.gz" "$REPO"/holyarch-*.pkg.tar.zst

cat >> "$PROFILE/pacman.conf" <<EOF

[holyarch]
SigLevel = Optional TrustAll
Server = file://$REPO
EOF
mkdir -p "$PROFILE/airootfs/etc"
sed "s|file://$REPO|file:///opt/holyarch-repo|" "$PROFILE/pacman.conf" \
    > "$PROFILE/airootfs/etc/pacman.conf"

echo holyarch >> "$PROFILE/packages.x86_64"

# the live system shouldn't rebuild itself
mkdir -p "$PROFILE/airootfs/etc/systemd/system"
ln -sf /dev/null "$PROFILE/airootfs/etc/systemd/system/holyarch-rebuild.service"

sed -i \
  -e 's/^iso_name=.*/iso_name="holyarch"/' \
  -e 's/ARCH_/HOLYARCH_/' \
  -e 's/^iso_publisher=.*/iso_publisher="HolyArch"/' \
  -e 's/^iso_application=.*/iso_application="HolyArch Live\/Rescue DVD"/' \
  "$PROFILE/profiledef.sh"

mkarchiso -v -w "$WORK/work" -o "$ROOT/out" "$PROFILE"
