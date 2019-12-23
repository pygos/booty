#!/bin/sh

set -e

BUILDROOT="$1"
shift

SCRIPTDIR="$1"
shift

SYSROOT="$BUILDROOT/stage2"

for dev in console full null ptmx tty zero; do
	touch "$SYSROOT/dev/$dev"
	mount --bind "/dev/$dev" "$SYSROOT/dev/$dev"
done

mkdir -p "$SYSROOT/download" "$SYSROOT/src" "$SYSROOT/toolchain"
mkdir -p "$SYSROOT/log" "$SYSROOT/sysroot" "$SYSROOT/build"
mkdir -p "$SYSROOT/deploy"
mkdir -p "$BUILDROOT/log2" "$BUILDROOT/sysroot"
mount --bind "$BUILDROOT/download" "$SYSROOT/download"
mount --bind "$BUILDROOT/src" "$SYSROOT/src"
mount --bind "$BUILDROOT/log2" "$SYSROOT/log"
mount --bind "$BUILDROOT/sysroot" "$SYSROOT/sysroot"

mkdir -p "$SYSROOT/scripts"
cp -rf "$SCRIPTDIR/pkg" "$SYSROOT/scripts"
cp -rf "$SCRIPTDIR/util" "$SYSROOT/scripts"
cp -rf "$SCRIPTDIR/template" "$SYSROOT/scripts"

CHROOT=$(which chroot)
env -i "$CHROOT" "$SYSROOT" /init.sh $@
