#!/bin/bash

SYSROOT="$1"
shift

for dev in console full null ptmx random tty urandom zero; do
	touch "$SYSROOT/dev/$dev"
	mount --bind "/dev/$dev" "$SYSROOT/dev/$dev"
done

CHROOT=$(which chroot)
env -i "$CHROOT" "$SYSROOT" /init.sh $@
