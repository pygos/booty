#!/bin/sh

export PATH="/bin"
export HOME="/root"
export SHELL="/bin/sh"
export TERM="xterm-256color"
export CURL_CA_BUNDLE="/etc/ssl/cert.pem"
export PYGOS_BUILD_CONTAINER="yes"
export LC_ALL="C"
export TZ="UTC"

ln -sf /proc/self/fd /dev/fd
ln -sf /proc/self/fd/0 /dev/stdin
ln -sf /proc/self/fd/1 /dev/stdout
ln -sf /proc/self/fd/2 /dev/stderr

hostname -F /etc/hostname
mount -t proc none /proc

cd
exec /bin/sh $@
