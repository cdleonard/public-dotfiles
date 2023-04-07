# vim: set foldmethod=marker:
#
# Personal .bashrc file
# shellcheck shell=bash disable=SC1090,SC1091
#

# This first section is also executed on non-interactive shells, like with ssh.

# Adjust PATH {{{
#
# Order entries to prefer custom over system software
#

bashrc_source_parts()
{
    local part part_list
    part_list=$(echo ~/.config/bashrc.d/*.sh | sort)
    for part in $part_list; do
        [[ -r $part ]] && source "$part"
    done
}

bashrc_append_to_path()
{
    local what=$1
    if [[ $PATH != $what:* && $PATH != *:$what && $PATH != *:$what:* ]]; then
        #echo "Including $what" >&2
        PATH+=:$what
    fi
}

bashrc_prepend_to_path()
{
    local what=$1
    [[ ! -d $what ]] && return
    if [[ $PATH != $what:* && $PATH != *:$what && $PATH != *:$what:* ]]; then
        #echo "Including $what" >&2
        PATH=$what:$PATH
    fi
}

# sbin even for regular user
bashrc_append_to_path /usr/local/sbin
bashrc_append_to_path /usr/sbin
bashrc_append_to_path /sbin

# PATH prepends, lower to higher precedence: {{{

# Debian ccache:
bashrc_prepend_to_path /usr/lib/ccache

# mingw64 binaries
bashrc_prepend_to_path /mingw64/bin

# mingw64 ucrt64 binaries, higher precedence than mingw64
bashrc_prepend_to_path /ucrt64/bin

# MacPorts:
bashrc_prepend_to_path /opt/local/bin

# Mac brew
bashrc_prepend_to_path /usr/local/bin

# Global linuxbrew
bashrc_prepend_to_path /home/linuxbrew/.linuxbrew/bin

# Per-user linuxbrew
bashrc_prepend_to_path ~/.linuxbrew/bin

# Include .local/bin. This is used for pip, npm, go
bashrc_prepend_to_path ~/.local/bin

# PATH prepends done }}}

#echo "\$PATH is now $PATH" >&2
# }}} PATH adjustment done

bashrc_source_parts

# Add ~/.local/lib/private-scripts/share to XDG_DATA_DIRS
export XDG_DATA_DIRS=~/.local/lib/private-scripts/share/:$XDG_DATA_DIRS

# Multiprocessor support for make/scons by default {{{
if [[ -f /proc/cpuinfo ]]; then
    cpu_count=$(grep -c ^processor /proc/cpuinfo)
elif [[ $OSTYPE = darwin* ]]; then
    cpu_count=$(sysctl -n hw.ncpu)
else
    cpu_count=2
fi
export SCONSFLAGS="-j$cpu_count"
if [[ -z $NO_MAKEFLAGS ]]; then
    export MAKEFLAGS="-j$cpu_count"
fi
unset cpu_count
# }}}


# The rest is for interactive mode only.
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignorespace:erasedups

# Huge history files.
export HISTSIZE="1000000"
export HISTFILESIZE="1000000"

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

bashrc_prompt_command()
{
    # Append new history lines.
    history -a
    # Read history lines not already read.
    history -n
}
PROMPT_COMMAND=bashrc_prompt_command

# Default:
export BASHRC_PROMPT_CACHE_PWD=$HOME
export BASHRC_PROMPT_CACHE_LOCATION=''

bashrc_setup_prompt()
{
    # Include SHLVL in PS1. This value increases in recursive shells like those
    # for prefix entering.
    if (( SHLVL > 1)); then
        local shlvl_prompt=" \\\$SHLVL=$SHLVL"
    else
        local shlvl_prompt=""
    fi

    local location_prompt='\u@\h:\w'
    local title_location_prompt='bash \u@\h:\w'

    # Setup prompt
    PS1="\
$location_prompt\
$shlvl_prompt\
 \A\
 \\\\\$?=\$?\
\n\\\$ "

    # If this is an xterm set the title as well.
    if [[ $TERM =~ ^(xterm|screen|tmux) ]]; then
        PS1="\[\e]0;$title_location_prompt\a\]$PS1"
    fi
}

bashrc_setup_prompt

# Add colors
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Pick EDITOR
# First available of: vim nvim vi
export EDITOR=vi
if which nvim &>/dev/null; then
    export EDITOR=nvim
fi
if which vim &>/dev/null; then
    export EDITOR=vim
fi

# Alias vi to the preferred variant found
# shellcheck disable=SC2139
alias vi=$EDITOR

# Clear the screen in man's pager instead of scrolling from the bottom
# This stops short manpages from displaying at the bottom.
export MANPAGER="less -c"
