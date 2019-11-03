#!/bin/bash

export PATH="/bin"
export HOME="/root"
export SHELL="/bin/bash"
export PROMPT_COMMAND=""
export PS1="\[\033[1;31m\][\u@\h \W]# \[\033[0m\]"
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

eval $(dircolors -b)

alias ..='cd ..'
alias ...='cd ../..'
alias cls='tput reset'
alias dir='ls --color=auto -l'
alias ll='ls --color=auto -l'
alias la='ls --color=auto -la'
alias l='ls --color=auto -alF'
alias ls='ls --color=auto'
alias rm='rm -I'
alias cp='cp -i'

shopt -s histappend
shopt -s checkwinsize
history -a

cd
exec /bin/bash --noprofile --norc $@
