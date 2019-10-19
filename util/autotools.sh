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
