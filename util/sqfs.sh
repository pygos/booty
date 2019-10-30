sqfs_dir_scan() {
	for f in $@; do
		find -H "$f" -type d -printf "dir \"%p\" 0%m 0 0\\n" |\
			tail -n +2
	done
}

sqfs_slink_scan() {
	for f in $@; do
		find -H "$f" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n"
	done
}

sqfs_file_scan() {
	local mode="$1"
	shift

	for f in $@; do
		find -H "$f" -type f -printf "file \"%p\" $mode 0 0\\n"
	done
}

gen_sqfs_file_list() {
	cat <<_EOF
dir bin 0755 0 0
dir include 0755 0 0
dir lib 0755 0 0
dir etc 0755 0 0
dir dev 0755 0 0
dir tmp 0755 0 0
dir root 0700 0 0
dir share 0755 0 0
dir proc 0755 0 0
dir share/awk 0755 0 0
dir share/tabset 0755 0 0
dir share/terminfo 0755 0 0
dir share/aclocal 0755 0 0
dir share/bison 0755 0 0
dir share/gcc-9.2.0 0755 0 0
dir share/aclocal-1.16 0755 0 0
dir share/autoconf 0755 0 0
dir share/automake-1.16 0755 0 0
dir share/cmake-3.15 0755 0 0
dir $TARGET 0755 0 0
dir $TARGET/bin 0755 0 0
dir $TARGET/lib 0755 0 0
dir $TARGET/lib/ldscripts 0755 0 0
file init.sh 0700 0 0
_EOF

	sqfs_dir_scan "include" "lib" "etc" "share/awk" "share/tabset"
	sqfs_dir_scan "share/terminfo" "share/aclocal" "share/autoconf"
	sqfs_dir_scan "share/bison" "share/gcc-9.2.0" "share/aclocal-1.16"
	sqfs_dir_scan "share/automake-1.16" "share/cmake-3.15"

	sqfs_slink_scan "bin" "include" "etc" "lib" "share/awk" "share/tabset"
	sqfs_slink_scan "share/aclocal" "share/bison" "share/terminfo"
	sqfs_slink_scan "share/gcc-9.2.0" "share/aclocal-1.16" "share/autoconf"
	sqfs_slink_scan "share/automake-1.16" "share/cmake-3.15"

	sqfs_file_scan "0755" "bin" "$TARGET/bin"
	sqfs_file_scan "0644" "etc" "include" "share/awk" "share/tabset"
	sqfs_file_scan "0644" "share/aclocal" "share/bison" "share/gcc-9.2.0"
	sqfs_file_scan "0644" "share/aclocal-1.16" "share/autoconf"
	sqfs_file_scan "0644" "share/automake-1.16" "share/cmake-3.15"
	sqfs_file_scan "0644" "share/terminfo" "$TARGET/lib/ldscripts"

	find -H "lib" -name "*.so*" -type f -printf "file \"%p\" 0755 0 0\\n"
	find -H "lib" ! -name "*.so*" -type f -printf "file \"%p\" 0644 0 0\\n"
}
