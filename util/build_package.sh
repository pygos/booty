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

	run_pkg_command "build"
	run_pkg_command "deploy"
	deploy_dev_cleanup

	if [ -z "$PYGOS_BUILD_CONTAINER" ]; then
		rm -rf "$PKGBUILDDIR"
	else
		umount "$PKGBUILDDIR"
	fi

	touch "$PKGLOGDIR/${PKGNAME}.done"
}
