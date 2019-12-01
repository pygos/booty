#!/bin/sh

apply_patches() {
	local PATCH

	for PATCH in $SCRIPTDIR/pkg/$PKGNAME/*.patch; do
		if [ -f $PATCH ]; then
			patch -p1 < $PATCH
		fi
	done
}

prepare() {
	apply_patches
}

download() {
	if [ -z "$TARBALL" -o -f "$TARBALL" ]; then
		return
	fi

	curl -o "$TARBALL" --silent --show-error -L "$URL/$TARBALL"
	echo "$SHA256SUM  $PKGDOWNLOADDIR/$TARBALL" | sha256sum -c "-"

	if [ ! -d "$PKGSRCDIR/$SRCDIR" ]; then
		tar -C "$PKGSRCDIR" -xf "$PKGDOWNLOADDIR/$TARBALL"

		cd "$PKGSRCDIR/$SRCDIR"
		prepare "$SCRIPTDIR/pkg/$PKGNAME"
	fi
}

build() {
	return
}

deploy() {
	return
}