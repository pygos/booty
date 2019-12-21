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

HOSTTUPLE=$($SCRIPTDIR/template/config.guess)
TARGET="$(uname -m)-linux-musl"
TCDIR="$BUILDROOT/toolchain"
GCC_CPU="x86-64"

export SOURCE_DATE_EPOCH="0"
export KBUILD_OUTPUT="$PKGBUILDDIR"
export KCONFIG_NOTIMESTAMP=1
export PATH="$TCDIR/bin:$PATH"

mkdir -p "$TCDIR/bin"

CMAKETCFILE="$TCDIR/toolchain.cmake"

############################# include utilities ##############################
. "$SCRIPTDIR/util/misc.sh"
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

for pkg in basefiles cabundle ncurses xz make zlib file gzip bzip2 zstd \
	   tar busybox flex bison gmp mpfr mpc openssl curl squashfs-tools-ng \
	   patch perl5 rhash expat libarchive jsoncpp libuv binutils gcc cmake\
	   m4 autoconf autoconf-archive automake pkg-config libtool; do
	include_pkg "$pkg"
	build_package
done

strip_files "$SYSROOT/bin" "$SYSROOT/lib" "$SYSROOT/$TARGET/bin"

echo "--- done ---"
