#!/bin/bash

set -e

################################ basic setup ################################
BUILDROOT="$(pwd)"
SCRIPTDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
NUMJOBS=$(grep -e "^processor" /proc/cpuinfo | wc -l)

PKGSRCDIR="$BUILDROOT/src"
PKGDOWNLOADDIR="$BUILDROOT/download"
PKGBUILDDIR="$BUILDROOT/build"
PKGLOGDIR="$BUILDROOT/log"
SYSROOT="$BUILDROOT/sysroot"

mkdir -p "$PKGSRCDIR" "$PKGDOWNLOADDIR" "$PKGLOGDIR" "$SYSROOT"

HOSTTUPLE=$($SCRIPTDIR/util/config.guess)
TARGET="$(uname -m)-linux-musl"
TCDIR="$BUILDROOT/toolchain"
GCC_CPU="x86-64"

export SOURCE_DATE_EPOCH="0"
export PATH="$TCDIR/bin:$PATH"

mkdir -p "$TCDIR/bin"

CMAKETCFILE="$TCDIR/toolchain.cmake"

############################# include utilities ##############################
source "$SCRIPTDIR/util/download.sh"
source "$SCRIPTDIR/util/pkgcmd.sh"
source "$SCRIPTDIR/util/misc.sh"
source "$SCRIPTDIR/util/autotools.sh"
source "$SCRIPTDIR/util/build_package.sh"

############################### build packages ###############################
echo "--- building toolchain ---"

for pkg in linux_headers tc-binutils tc-gcc1 musl tc-gcc2 toolchain; do
	include_pkg "$pkg"
	build_package
done

echo "--- building packages ---"

export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
export PKG_CONFIG_LIBDIR="$SYSROOT/lib/pkgconfig"
export PKG_CONFIG_PATH="$SYSROOT/lib/pkgconfig"

for pkg in perl5; do
	include_pkg "$pkg"
	build_package
done

# TODO: if we are in the container, nuke /include and /lib. We no longer build
# host tools and we don't want ANY cross contamination.

for pkg in basefiles ncurses readline bash coreutils util-linux xz gzip bzip2 \
	   diffutils findutils grep gawk sed tar make zlib flex bison \
	   gmp mpfr mpc openssl curl inetutils less squashfs-tools-ng patch \
	   binutils gcc rhash expat libarchive cmake m4 autoconf \
	   autoconf-archive automake pkg-config libtool; do
	include_pkg "$pkg"
	build_package
done

if [ -z "$PYGOS_BUILD_CONTAINER" ]; then
	echo "--- copying bootstrap scripts to sysroot ---"

	mkdir -p "$SYSROOT/scripts"
	cp "$SCRIPTDIR/mk.sh" "$SYSROOT/scripts"

	if [ ! -d "$SYSROOT/scripts/pkg" ]; then
		cp -r "$SCRIPTDIR/pkg" "$SYSROOT/scripts"
	fi

	if [ ! -d "$SYSROOT/scripts/util" ]; then
		cp -r "$SCRIPTDIR/util" "$SYSROOT/scripts"
	fi

	echo "--- running stage 2 ---"

	unshare -fimpuUr "$SCRIPTDIR/util/runchroot.sh" "$SYSROOT"
else
	echo "--- generating squashfs ---"

	cat > "$BUILDROOT/files.txt" <<_EOF
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

	pushd "$SYSROOT" > /dev/null
	find -H "include" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "lib" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "etc" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/awk" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/tabset" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/terminfo" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/aclocal" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/bison" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/gcc-9.2.0" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/aclocal-1.16" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/autoconf" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/automake-1.16" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"
	find -H "share/cmake-3.15" -type d -printf "dir \"%p\" 0%m 0 0\\n" | tail -n +2 >> "$BUILDROOT/files.txt"

	find -H "bin" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "include" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "etc" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "lib" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/awk" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/tabset" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/terminfo" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/aclocal" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/bison" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/gcc-9.2.0" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/aclocal-1.16" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/autoconf" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/automake-1.16" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"
	find -H "share/cmake-3.15" -type l -printf "slink \"%p\" 0%m 0 0 %l\\n" >> "$BUILDROOT/files.txt"

	find -H "bin" -type f -printf "file \"%p\" 0755 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "include" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "etc" -type f -printf "file \"%p\" 0755 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "lib" -name "*.so*" -type f -printf "file \"%p\" 0755 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "lib" ! -name "*.so*" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/awk" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/tabset" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/terminfo" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/aclocal" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/bison" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/gcc-9.2.0" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/aclocal-1.16" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/autoconf" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/automake-1.16" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "share/cmake-3.15" -type f -printf "file \"%p\" 0644 0 0\\n" >> "$BUILDROOT/files.txt"

	find -H "$TARGET/bin" -type f -printf "file \"%p\" 0755 0 0\\n" >> "$BUILDROOT/files.txt"
	find -H "$TARGET/lib/ldscripts" -type f -printf "file \"%p\" 0755 0 0\\n" >> "$BUILDROOT/files.txt"
	popd  > /dev/null

	gensquashfs -j $NUMJOBS -D "$SYSROOT" -F "$BUILDROOT/files.txt" -fq rootfs.sqfs
fi

echo "--- done ---"
