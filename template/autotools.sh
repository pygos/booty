#!/bin/sh

run_configure() {
	local srcdir="$1"
	shift

	ac_cv_func_malloc_0_nonnull=yes \
	ac_cv_func_realloc_0_nonnull=yes \
	ac_cv_func_posix_getpwuid_r=yes \
	ac_cv_func_posix_getgrgid_r=yes \
	glib_cv_stack_grows=no \
	glib_cv_long_long_format=ll \
	glib_cv_uscore=no \
	$srcdir/configure --prefix="" --build="$HOSTTUPLE" --host="$TARGET" \
		--bindir="/bin" --sbindir="/bin" --sysconfdir="/etc" \
		--libexecdir="/lib/libexec" --datarootdir="/share" \
		--datadir="/share" --sharedstatedir="/share" \
		--with-bashcompletiondir="/share/bash-completion/completions" \
		--includedir="/include" \
		--libdir="/lib" \
		--enable-shared --disable-static $@
}

unfuck_libtool() {
	local libdir="$PKGDEPLOYDIR/lib"
	local f

	for f in $(find $PKGBUILDDIR -type f -name '*.la' -o -name '*.lai'); do
		if [ -f "$f" ]; then
			sed -i "s#libdir='.*'#libdir='$libdir'#g" "$f"
		fi
	done

	if [ -f "$PKGBUILDDIR/libtool" ]; then
		sed -i -r "s/(finish_cmds)=.*$/\1=\"\"/" "$PKGBUILDDIR/libtool"
		sed -i -r "s/(hardcode_into_libs)=.*$/\1=no/" \
		    "$PKGBUILDDIR/libtool"
		sed -i "s#libdir='\$install_libdir'#libdir='$libdir'#g" \
		    "$PKGBUILDDIR/libtool"
	fi
}

# provide default implementations
build() {
	run_configure "$1" $CONFIGURE_OPTIONS
	make -j $NUMJOBS
}

deploy() {
	unfuck_libtool
	make DESTDIR="$PKGDEPLOYDIR" install
}
