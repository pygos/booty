#!/bin/bash

SYSROOT="$1"
shift

BUILDROOT="$1"
shift

for dev in console full null ptmx tty zero; do
	touch "$SYSROOT/dev/$dev"
	mount --bind "/dev/$dev" "$SYSROOT/dev/$dev"
done

mkdir -p "$SYSROOT/root/download"
mount --bind "$BUILDROOT/download" "$SYSROOT/root/download"

CHROOT=$(which chroot)
env -i "$CHROOT" "$SYSROOT" /init.sh $@
