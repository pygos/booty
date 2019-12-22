#!/bin/sh

set -e

BUILDROOT="$1"
shift

SCRIPTDIR="$1"
shift

# set up basic mount points and file system
mkdir -p "$BUILDROOT/stage1"
mount -t tmpfs none "$BUILDROOT/stage1"

mkdir -p "$BUILDROOT/stage1/etc" "$BUILDROOT/stage1/dev" "$BUILDROOT/stage1/tmp"
mkdir -p "$BUILDROOT/stage1/root" "$BUILDROOT/stage1/proc"
mkdir -p "$BUILDROOT/stage1/var/lib"

mount -t proc proc "$BUILDROOT/stage1/proc"

for dir in usr bin sbin lib lib32 lib64 etc/pki etc/alternatives \
	   var/lib/ca-certificates; do
	if [ -d "/$dir" ]; then
		mkdir -p "$BUILDROOT/stage1/$dir"
		mount --rbind "/$dir" "$BUILDROOT/stage1/$dir"
	fi
done

for dev in console full null ptmx tty zero; do
	touch "$BUILDROOT/stage1/dev/$dev"
	mount --bind "/dev/$dev" "$BUILDROOT/stage1/dev/$dev"
done

ln -sf /proc/self/fd "$BUILDROOT/stage1/dev/fd"
ln -sf /proc/self/fd/0 "$BUILDROOT/stage1/dev/stdin"
ln -sf /proc/self/fd/1 "$BUILDROOT/stage1/dev/stdout"
ln -sf /proc/self/fd/2 "$BUILDROOT/stage1/dev/stderr"

# setup some files in /etc
echo "root:x:0:" > "$BUILDROOT/stage1/etc/group"
echo "root:x:0:0:root:/root:/bin/sh" > "$BUILDROOT/stage1/etc/passwd"
echo "booty" > "$BUILDROOT/stage1/etc/hostname"
echo "nameserver 1.1.1.1" > "$BUILDROOT/stage1/etc/resolv.conf"
echo "nameserver 8.8.8.8" >> "$BUILDROOT/stage1/etc/resolv.conf"

# mount stuff from the build directory
for dir in download log sysroot toolchain src; do
	mkdir -p "$BUILDROOT/$dir" "$BUILDROOT/stage1/$dir"
	mount --bind "$BUILDROOT/$dir" "$BUILDROOT/stage1/$dir"
done

mkdir -p "$BUILDROOT/stage1/build"
mkdir -p "$BUILDROOT/stage1/deploy"

# copy build scripts
mkdir -p "$BUILDROOT/stage1/scripts"
cp -r "$SCRIPTDIR/pkg" "$BUILDROOT/stage1/scripts"
cp -r "$SCRIPTDIR/util" "$BUILDROOT/stage1/scripts"
cp -r "$SCRIPTDIR/template" "$BUILDROOT/stage1/scripts"

# setup environment
export HOME="/root"
export SHELL="/bin/sh"
export TERM="xterm-256color"
export LC_ALL="C"
export TZ="UTC"
export PS1="[root@booty]# "
hostname -F "$BUILDROOT/stage1/etc/hostname"

# run the target command
chroot "$BUILDROOT/stage1" /bin/sh -c "$@"
