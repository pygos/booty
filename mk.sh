#!/bin/sh

set -e

BUILDROOT="$(pwd)"
SCRIPTDIR=$(cd $(dirname "$0") && pwd)

echo "--- running stage 1 ---"

env -i - PATH=$PATH unshare -fimpuUr \
    "$SCRIPTDIR/util/stage1chroot.sh" "$BUILDROOT" "$SCRIPTDIR" \
    "/scripts/util/bootstrap.sh"

echo "--- copying bootstrap scripts to sysroot ---"

echo "--- running stage 2 ---"

# TODO: actually run bootstrap.sh inside the stage 1 container
unshare -fimpuUr "$SCRIPTDIR/util/stage2chroot.sh" "$BUILDROOT" "$SCRIPTDIR"
