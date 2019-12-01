#!/bin/sh

include_pkg() {
	PKGNAME="$1"		# globally visible package name

	unset -f download prepare build deploy
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

build_package() {
	if [ -f "$PKGLOGDIR/${PKGNAME}.done" ]; then
		return
	fi

	mkdir -p "$SYSROOT" "$PKGBUILDDIR"

	if [ -z "$PYGOS_BUILD_CONTAINER" ]; then
		run_pkg_command "download" "$PKGDOWNLOADDIR"
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
