#!/bin/bash

set -euo pipefail

declare -r ARCH="${3:-${ARCH:-aarch64}}"
declare -r WORKDIR="$1"
declare -r BUILDDIR="$WORKDIR/build"
declare -r OUTPUTDIR="$WORKDIR/output"
declare -r IMAGE_VERSION="$2"
# This pacman.conf is used by the host pacman, but installs into the rootfs.
declare -r PACMAN_CONF="$WORKDIR/pacman.conf"
# This folder is used as `--gpgdir` for pacman, so that it trusts archlinuxarm's keyring.
declare -r KEYRING_DIR="$WORKDIR/alarm-keyring"
# This is used to install some tmp packages that should not be included in the final image.
# like fakechroot and fakeroot, we need the arm version of those libraries for them to work cross-architecture.
declare -r TMPDIR="$BUILDDIR/tmp"

mkdir -vp "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks"
find /usr/share/libalpm/hooks -exec ln -sf /dev/null "$BUILDDIR/alpm-hooks"{} \;

mkdir -vp "$BUILDDIR/var/lib/pacman/" "$OUTPUTDIR"

sed 's/Include = /&rootfs/g' < "/usr/share/devtools/pacman.conf.d/extra.conf" > "$WORKDIR/pacman.conf"

cp --recursive --preserve=timestamps rootfs/* "$BUILDDIR/"

fakechroot -- fakeroot -- \
    pacman-key --verbose \
        --config "$WORKDIR/pacman.conf" \
        --gpgdir "$KEYRING_DIR" \
        --init
fakechroot -- fakeroot -- \
    pacman-key --verbose \
        --config "$WORKDIR/pacman.conf" \
        --gpgdir "$KEYRING_DIR" \
        -a <(curl -Lss https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/refs/heads/master/core/archlinuxarm-keyring/archlinuxarm.gpg)
fakechroot -- fakeroot -- \
    pacman-key --verbose \
        --config "$WORKDIR/pacman.conf" \
        --gpgdir "$KEYRING_DIR" \
        --lsign-key builder@archlinuxarm.org

fakechroot -- fakeroot -- \
    pacman -Sy -r "$BUILDDIR" \
        --noconfirm --dbpath "$BUILDDIR/var/lib/pacman" \
        --arch "$ARCH" \
        --config "$WORKDIR/pacman.conf" \
        --noscriptlet \
        --gpgdir $KEYRING_DIR \
        --hookdir "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks/" base archlinuxarm-keyring

# install fakeroot and fakechroot to some other directory, so that they do not pollute the final rootfs.
declare -r TMPPACKAGEDIR="$TMPDIR/tmp-package"
mkdir -vp "$TMPPACKAGEDIR/var/lib/pacman/"
fakechroot -- fakeroot -- \
    pacman -Sy -r "$TMPPACKAGEDIR" \
        --noconfirm --dbpath "$TMPPACKAGEDIR/var/lib/pacman" \
        --arch "$ARCH" \
        --config "$WORKDIR/pacman.conf" \
        --noscriptlet \
        --gpgdir $KEYRING_DIR \
        --hookdir "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks/" fakeroot fakechroot
ln -svf "$TMPPACKAGEDIR/usr/lib/libfakeroot" "$BUILDDIR/usr/lib/libfakeroot"

export QEMU_LD_PREFIX="/usr/$ARCH-linux-gnu"
fakechroot -- fakeroot -- chroot "$BUILDDIR" update-ca-trust
fakechroot -- fakeroot -- chroot "$BUILDDIR" pacman-key --init
fakechroot -- fakeroot -- chroot "$BUILDDIR" pacman-key --populate
fakechroot -- fakeroot -- chroot "$BUILDDIR" /usr/bin/systemd-sysusers --root "/"
fakechroot -- fakeroot -- chroot "$BUILDDIR" /usr/bin/systemctl mask systemd-firstboot

unlink "$BUILDDIR/usr/lib/libfakeroot"

# Use fakeroot to map the gid / uid of the builder process to root
# See https://gitlab.archlinux.org/archlinux/archlinux-docker/-/issues/22
fakeroot -- \
    tar \
        --numeric-owner \
        --xattrs \
        --acls \
        --exclude-from=scripts/exclude \
        -C "$BUILDDIR" \
        -c . \
        -f "$OUTPUTDIR/archlinuxarm-$ARCH-$IMAGE_VERSION.tar"

cd "$OUTPUTDIR"
xz -T0 -9 "archlinuxarm-$ARCH-$IMAGE_VERSION.tar"
mv -v "archlinuxarm-$ARCH-$IMAGE_VERSION.tar.xz" "archlinuxarm-$ARCH-$IMAGE_VERSION.wsl"
sha256sum "archlinuxarm-$ARCH-$IMAGE_VERSION.wsl" > "archlinuxarm-$ARCH-$IMAGE_VERSION.wsl.SHA256"
