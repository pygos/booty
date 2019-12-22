#!/bin/sh

include_pkg() {
	PKGNAME="$1"		# globally visible package name

	unset -f download prepare build deploy
	unset -v VERSION TARBALL URL SRCDIR SHA256SUM CONFIGURE_OPTIONS
	. "$SCRIPTDIR/template/emptypkg.sh"
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

	if [ -d "$PKGDEPLOYDIR/share/pkgconfig" ]; then
		mkdir -p "$PKGDEPLOYDIR/lib/pkgconfig"
		mv "$PKGDEPLOYDIR/share/pkgconfig"/* "$PKGDEPLOYDIR/lib/pkgconfig"
		rmdir "$PKGDEPLOYDIR/share/pkgconfig"
	fi

	for f in "$PKGDEPLOYDIR/lib"/*.la; do
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

build_package() {
	if [ -f "$PKGLOGDIR/${PKGNAME}.done" ]; then
		return
	fi

	mount -t tmpfs none "$PKGBUILDDIR"
	mount -t tmpfs none "$PKGDEPLOYDIR"

	run_pkg_command "download" "$PKGDOWNLOADDIR"
	run_pkg_command "build" "$PKGBUILDDIR"
	run_pkg_command "deploy" "$PKGBUILDDIR"
	deploy_dev_cleanup
	strip_files "$PKGDEPLOYDIR/bin" "$PKGDEPLOYDIR/lib" \
		    "$PKGDEPLOYDIR/$TARGET/bin"

	cd "$PKGDEPLOYDIR"
	find -H "." -type f | while read f; do
		rm -f "$SYSROOT/$f"
	done
	find -H "." -type l | while read f; do
		rm -f "$SYSROOT/$f"
	done
	ls | while read f; do
		cp -r "$f" "$SYSROOT"
	done
	cd "/"

	umount -l "$PKGBUILDDIR"
	umount -l "$PKGDEPLOYDIR"
	touch "$PKGLOGDIR/${PKGNAME}.done"
}
