#!/bin/sh

apply_patches() {
	local PATCH

	for PATCH in $SCRIPTDIR/pkg/$PKGNAME/*.patch; do
		if [ -f $PATCH ]; then
			patch -p1 < $PATCH
		fi
	done
}

deploy_dev_cleanup() {
	local f

	if [ -d "$SYSROOT/share/pkgconfig" ]; then
		mkdir -p "$SYSROOT/lib/pkgconfig"
		mv "$SYSROOT/share/pkgconfig"/* "$SYSROOT/lib/pkgconfig"
		rmdir "$SYSROOT/share/pkgconfig"
	fi

	for f in "$SYSROOT/lib"/*.la; do
		[ ! -e "$f" ] || rm "$f"
	done
}

strip_files() {
	local f

	for f in $@; do
		[ ! -L "$f" ] || continue;

		if [ -d "$f" ]; then
			strip_files ${f}/*
		fi

		[ -f "$f" ] || continue;

		if file -b $f | grep -q -i elf; then
			${TARGET}-strip --discard-all "$f" 2> /dev/null || true
		fi
	done
}
