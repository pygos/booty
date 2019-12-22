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
	if [ -z "$TARBALL" ]; then
		return
	fi

	if [ ! -f "$TARBALL" ]; then
		curl -o "$TARBALL" --silent --show-error -L "$URL/$TARBALL"
	fi

	if [ ! -d "$PKGSRCDIR/$SRCDIR" ]; then
		echo "$SHA256SUM  $PKGDOWNLOADDIR/$TARBALL" | sha256sum -c "-"
		tar -C "$PKGSRCDIR" -xf "$PKGDOWNLOADDIR/$TARBALL" \
		    --no-same-owner

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
