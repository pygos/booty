#!/bin/sh

set -e

################################ basic setup ################################
BUILDROOT="$(pwd)"
SCRIPTDIR=$(cd $(dirname "$0") && pwd)
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
. "$SCRIPTDIR/util/download.sh"
. "$SCRIPTDIR/util/pkgcmd.sh"
. "$SCRIPTDIR/util/misc.sh"
. "$SCRIPTDIR/util/autotools.sh"
. "$SCRIPTDIR/util/build_package.sh"
. "$SCRIPTDIR/util/sqfs.sh"

############################### build packages ###############################
echo "--- building toolchain ---"

for pkg in linux_headers tc-binutils tc-gcc1 musl tc-gcc2 tc-file toolchain; do
	include_pkg "$pkg"
	build_package
done

echo "--- building packages ---"

export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
export PKG_CONFIG_LIBDIR="$SYSROOT/lib/pkgconfig"
export PKG_CONFIG_PATH="$SYSROOT/lib/pkgconfig"

for pkg in basefiles cabundle ncurses readline bash xz make zlib file busybox \
	   flex bison gmp mpfr mpc openssl curl squashfs-tools-ng patch perl5 \
	   rhash expat libarchive jsoncpp libuv binutils gcc cmake m4 \
	   autoconf autoconf-archive automake pkg-config libtool; do
	include_pkg "$pkg"
	build_package
done

strip_files "$SYSROOT/bin" "$SYSROOT/lib" "$SYSROOT/$TARGET/bin"

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

	unshare -fimpuUr "$SCRIPTDIR/util/runchroot.sh" "$SYSROOT" "$BUILDROOT"
else
	echo "--- generating squashfs ---"
	cd "$SYSROOT"
	gen_sqfs_file_list >> "$BUILDROOT/files.txt"
	cd "$BUILDROOT"

	gensquashfs -j $NUMJOBS -D "$SYSROOT" -F "$BUILDROOT/files.txt" -fq rootfs.sqfs
fi

echo "--- done ---"
