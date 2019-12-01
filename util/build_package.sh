#!/bin/sh

include_pkg() {
	PKGNAME="$1"		# globally visible package name

	unset -f build deploy prepare check_update
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM CONFIGURE_OPTIONS
	. "$SCRIPTDIR/util/emptypkg.sh"
	. "$SCRIPTDIR/pkg/$PKGNAME/build"
}

run_pkg_command() {
	local FUNCTION="$1"
	local LOGFILE="$PKGLOGDIR/${PKGNAME}-${FUNCTION}.log"
	local SRC="$PKGSRCDIR/$SRCDIR"
	local WORKDIR="$2"

	echo "$PKGNAME - $FUNCTION"

	cd "$WORKDIR"
	$FUNCTION "$SRC" > "$LOGFILE" 2>&1 < /dev/null
	cd "$BUILDROOT"

	gzip -f "$LOGFILE"
}

fetch_package() {
	echo "$PKGNAME - download"

	if [ -z "$TARBALL" ]; then
		return
	fi

	if [ ! -e "$PKGDOWNLOADDIR/$TARBALL" ]; then
		curl -o "$PKGDOWNLOADDIR/$TARBALL" --silent --show-error \
		     -L "$URL/$TARBALL"
	fi

	echo "$SHA256SUM  $PKGDOWNLOADDIR/${TARBALL}" | sha256sum -c "-"

	if [ ! -e "$PKGSRCDIR/$SRCDIR" ]; then
		echo "$PKGNAME - unpack"
		tar -C "$PKGSRCDIR" -xf "$PKGDOWNLOADDIR/$TARBALL"

		run_pkg_command "prepare" "$PKGSRCDIR/$SRCDIR"
	fi
}

build_package() {
	if [ -f "$PKGLOGDIR/${PKGNAME}.done" ]; then
		return
	fi

	mkdir -p "$SYSROOT" "$PKGBUILDDIR"

	if [ -z "$PYGOS_BUILD_CONTAINER" ]; then
		fetch_package
	else
		mount -t tmpfs none "$PKGBUILDDIR"
	fi

	run_pkg_command "build" "$PKGBUILDDIR"
	run_pkg_command "deploy" "$PKGBUILDDIR"
	deploy_dev_cleanup

	if [ -z "$PYGOS_BUILD_CONTAINER" ]; then
		rm -rf "$PKGBUILDDIR"
	else
		umount "$PKGBUILDDIR"
	fi

	touch "$PKGLOGDIR/${PKGNAME}.done"
}
