sqfs_dir_scan() {
	for f in $@; do
		find -H "$f" -type d | tail -n +2 | while read dir; do
			echo "dir \"$dir\" 0755 0 0"
		done
	done
}

sqfs_slink_scan() {
	for f in $@; do
		find -H "$f" -type l | while read slink; do
			echo "slink \"$slink\" 0777 0 0 $(readlink $slink)"
		done
	done
}

sqfs_file_scan() {
	local mode="$1"
	shift

	for f in $@; do
		find -H "$f" -type f | while read fname; do
			echo "file \"$fname\" $mode 0 0"
		done
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
dir share/tabset 0755 0 0
dir share/terminfo 0755 0 0
dir share/aclocal 0755 0 0
dir share/bison 0755 0 0
dir share/gcc-9.2.0 0755 0 0
dir share/aclocal-1.16 0755 0 0
dir share/autoconf 0755 0 0
dir share/automake-1.16 0755 0 0
dir share/cmake-3.15 0755 0 0
dir share/misc 0755 0 0
dir usr 0755 0 0
slink usr/bin 0777 0 0 /bin
slink usr/lib 0777 0 0 /lib
slink usr/share 0777 0 0 /share
slink usr/include 0777 0 0 /include
slink usr/etc 0777 0 0 /etc
dir usr/local 0755 0 0
slink usr/local/bin 0777 0 0 /bin
slink usr/local/lib 0777 0 0 /lib
slink usr/local/share 0777 0 0 /share
slink usr/local/include 0777 0 0 /include
slink usr/local/etc 0777 0 0 /etc
dir $TARGET 0755 0 0
dir $TARGET/bin 0755 0 0
dir $TARGET/lib 0755 0 0
dir $TARGET/lib/ldscripts 0755 0 0
file init.sh 0700 0 0
_EOF

	sqfs_dir_scan "include" "lib" "etc" "share/tabset"
	sqfs_dir_scan "share/terminfo" "share/aclocal" "share/autoconf"
	sqfs_dir_scan "share/bison" "share/gcc-9.2.0" "share/aclocal-1.16"
	sqfs_dir_scan "share/automake-1.16" "share/cmake-3.15"

	sqfs_slink_scan "bin" "include" "etc" "lib" "share/tabset"
	sqfs_slink_scan "share/aclocal" "share/bison" "share/terminfo"
	sqfs_slink_scan "share/gcc-9.2.0" "share/aclocal-1.16" "share/autoconf"
	sqfs_slink_scan "share/automake-1.16" "share/cmake-3.15"

	sqfs_file_scan "0755" "bin" "$TARGET/bin"
	sqfs_file_scan "0644" "etc" "include" "share/misc" "share/tabset"
	sqfs_file_scan "0644" "share/aclocal" "share/bison" "share/gcc-9.2.0"
	sqfs_file_scan "0644" "share/aclocal-1.16" "share/autoconf"
	sqfs_file_scan "0644" "share/automake-1.16" "share/cmake-3.15"
	sqfs_file_scan "0644" "share/terminfo" "$TARGET/lib/ldscripts"

	find -H "lib" -name "*.so*" -type f | while read fname; do
		echo "file \"$fname\" 0755 0 0"
	done

	find -H "lib" ! -name "*.so*" -type f | while read fname; do
		echo "file \"$fname\" 0644 0 0"
	done
}
