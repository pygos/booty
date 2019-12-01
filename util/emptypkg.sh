#!/bin/sh

download() {
	if [ -z "$TARBALL" -o -f "$TARBALL" ]; then
		return
	fi

	curl -o "$TARBALL" --silent --show-error -L "$URL/$TARBALL"
	echo "$SHA256SUM  $PKGDOWNLOADDIR/$TARBALL" | sha256sum -c "-"
}

prepare() {
	apply_patches
}

build() {
	return
}

deploy() {
	return
}
