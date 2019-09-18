#!/bin/bash

ln -sf /proc/self/fd /dev/fd
ln -sf /proc/self/fd/0 /dev/stdin
ln -sf /proc/self/fd/1 /dev/stdout
ln -sf /proc/self/fd/2 /dev/stderr

/bin/hostname -F /etc/hostname
/bin/mount -t proc none /proc

exec /bin/bash --noprofile --rcfile /etc/bashrc $@
