#!/bin/sh

set -e

BUILDROOT="$(pwd)"
SYSROOT="$BUILDROOT/sysroot"
SCRIPTDIR=$(cd $(dirname "$0") && pwd)

echo "--- running stage 1 ---"

"$SCRIPTDIR/util/bootstrap.sh"

echo "--- copying bootstrap scripts to sysroot ---"

mkdir -p "$SYSROOT/scripts"

if [ ! -d "$SYSROOT/scripts/pkg" ]; then
	cp -r "$SCRIPTDIR/pkg" "$SYSROOT/scripts"
fi

if [ ! -d "$SYSROOT/scripts/util" ]; then
	cp -r "$SCRIPTDIR/util" "$SYSROOT/scripts"
fi

if [ ! -d "$SYSROOT/scripts/template" ]; then
	cp -r "$SCRIPTDIR/template" "$SYSROOT/scripts"
fi

echo "--- running stage 2 ---"

# TODO: actually run bootstrap.sh inside the stage 1 container
unshare -fimpuUr "$SCRIPTDIR/util/runchroot.sh" "$SYSROOT" "$BUILDROOT"
