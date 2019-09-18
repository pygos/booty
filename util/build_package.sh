build_package() {
	if [ -f "$PKGLOGDIR/${PKGNAME}.done" ]; then
		return
	fi

	fetch_package
	mkdir -p "$SYSROOT" "$PKGBUILDDIR"
	run_pkg_command "build"
	run_pkg_command "deploy"
	deploy_dev_cleanup
	rm -rf "$PKGBUILDDIR"

	touch "$PKGLOGDIR/${PKGNAME}.done"
}
