# shellcheck shell=bash

# --- General Configuration ---

# History control
bind "\e[A":history-search-backward
bind "\e[B":history-search-forward

# Check window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

# --- Utility Functions ---

function parse_git_dirty {
    [[ $(git status 2>/dev/null | tail -n1) != "nothing to commit, working tree clean" ]] && echo "*"
}

function parse_git_branch {
    git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/[\1$(parse_git_dirty)]/"
}

function alias_pg_server() {
    pg_ctl -D /usr/local/var/postgres -l "$HOME/pg_log" "$1"
}

function pvrpush() {
    if command -v pvr &>/dev/null; then
        pvr add .
        pvr commit
        pvr post "$@"
    else
        echo "pvr command not found"
    fi
}

function curso {
    setsid cursor "$1" >/dev/null 2>&1 &
}

function serve {
    local port=${1:-9898}
    if command -v python3 &>/dev/null; then
        python3 -m http.server "$port"
    else
        echo "python3 not found"
    fi
}

_open_files_for_editing() {
    if [ -x /usr/bin/exo-open ]; then
        printf 'exo-open %q ' "$@" >&2
        setsid exo-open "$@" >&/dev/null
        return
    fi
    if [ -x /usr/bin/xdg-open ]; then
        for file in "$@"; do
            printf 'xdg-open %q ' "$file" >&2
            setsid xdg-open "$file" >&/dev/null
        done
        return
    fi
    echo "${FUNCNAME[0]}: package 'xdg-utils' or 'exo' is required." >&2
}

neovim() {
    if command -v alacritty &>/dev/null; then
        alacritty -e nvim "$@" 2>&1 &
    else
        nvim "$@"
    fi
}

disk_usage() {
    if command -v baobab &>/dev/null; then
        baobab "$@" >/dev/null 2>&1 &
    else
        du -h --max-depth=1 "$@"
    fi
}

memoryusage() {
    python3 -c "import subprocess, resource, sys; subprocess.run(sys.argv[1:]); print(f'\nPeak Memory: {resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss / 1024:.2f} MB')" "$@"
}

ShowInstallerIsoInfo() {
    local file=/usr/lib/endeavouros-release
    if [ -r $file ]; then
        cat $file
    else
        echo "Sorry, installer ISO info is not available." >&2
    fi
}

# --- Prompt Settings ---

# Fallback PS1 setup
_setup_ps1() {
    local debian_chroot=""
    if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
        debian_chroot=$(cat /etc/debian_chroot)
    fi

    local force_color_prompt=yes
    local color_prompt=yes

    if [ "$color_prompt" = yes ]; then
        # Standard PS1 with Git integration
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[0;33m\]$(parse_git_branch)\[\033[00m\]\n$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\u:\w\$ '
    fi

    # Window title handling
    case "$TERM" in
    xterm* | rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *) ;;
    esac

    # Live user handling (EndeavourOS specific)
    if [ "$(whoami)" = "liveuser" ]; then
        local iso_version
        iso_version="$(grep ^VERSION= /usr/lib/endeavouros-release 2>/dev/null | cut -d '=' -f 2)"
        if [ -n "$iso_version" ]; then
            local prefix="eos-"
            local iso_info="$prefix$iso_version"
            PS1="[\u@$iso_info \W]\$ "
        fi
    fi
}

# Try Starship first, otherwise fall back to manual PS1
if command -v starship &>/dev/null; then
    eval -- "$(starship init bash --print-full-init)"
else
    _setup_ps1
fi

# --- Aliases ---

# Color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# General aliases
alias ll='ls -lavh --ignore=..'
alias l='ls -lav --ignore=.?*'

# Navigation
if [ -d "$HOME/projects/" ]; then
    alias projects="cd ~/projects/"
    alias pantacor="cd ~/projects/pantacor"
fi

if [ -d "$HOME/Proyectos/" ]; then
    alias proyectos="cd ~/Proyectos/"
    alias pantacor="cd ~/Proyectos/pantacor"
fi

if [ -d "/home/projects/" ]; then
    alias projects="cd /home/projects"
    alias pantacor="cd /home/projects/pantacor"
fi

# Git
if command -v git &>/dev/null; then
    alias gs='git status'
    [ -s "/usr/share/bash-completion/completions/git" ] && . "/usr/share/bash-completion/completions/git"
fi

# Tool aliases
if command -v zeditor &>/dev/null; then
    alias zed='zeditor'
fi

if command -v ruby &>/dev/null; then
    alias webserver='ruby -run -e httpd . -p 3000'
fi

if command -v pvr &>/dev/null; then
    alias pvsign='pvr add && pvr commit && pvr sig update && pvr add && pvr commit'
fi

if command -v lsblk &>/dev/null; then
    alias usbls="lsblk -d -p -o NAME,SIZE,TYPE,MODEL,VENDOR,TRAN"
fi

# alias ef='_open_files_for_editing'
# alias pacdiff=eos-pacdiff

# --- Environment & Path ---

# Helper to add path if exists
path_prepend() {
    if [ -d "$1" ]; then
        export PATH="$1:$PATH"
    fi
}
path_append() {
    if [ -d "$1" ]; then
        export PATH="$PATH:$1"
    fi
}

# Go
if [ -d "$HOME/go" ]; then
    export GOROOT="$HOME/.go"
    export GOPATH="$HOME/go"
    path_prepend "$GOPATH/bin"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
if [ -d "$NVM_DIR" ]; then
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# RVM
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
    path_append "$HOME/.rvm/bin"
fi

# Local Bins
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/bin/v"

# Yarn
export YARN_BIN="$HOME/.yarn/bin"
export YARN_GLOBAL="$HOME/.config/yarn/global/node_modules/.bin"
path_prepend "$YARN_BIN"
path_prepend "$YARN_GLOBAL"

# PNPM
export PNPM_HOME="$HOME/.local/share/pnpm"
if [ -d "$PNPM_HOME" ]; then
    path_prepend "$PNPM_HOME"
fi

# Bun
export BUN_INSTALL="$HOME/.bun"
if [ -d "$BUN_INSTALL" ]; then
    path_prepend "$BUN_INSTALL/bin"
fi

# Deno
if [ -f "$HOME/.deno/env" ]; then
    . "$HOME/.deno/env"
    if [ -f "$HOME/.local/share/bash-completion/completions/deno.bash" ]; then
        source "$HOME/.local/share/bash-completion/completions/deno.bash"
    fi
fi

# ZVM
if [ -d "$HOME/.zvm/current" ]; then
    path_append "$HOME/.zvm/current"
fi

# Soar (Ridge specific, making generic if exists)
if [ -d "$HOME/.local/share/soar/bin" ]; then
    path_prepend "$HOME/.local/share/soar/bin"
fi

# Balena CLI
if [ -d "$HOME/.local/balena-cli" ]; then
    path_append "$HOME/.local/balena-cli"
fi

# Kiex / Elixir
[ -s "$HOME/.kiex/scripts/kiex" ] && source "$HOME/.kiex/scripts/kiex"
[ -s "$HOME/.erl/activate" ] && source "$HOME/.erl/activate"

# Zed completion
[ -s "$HOME/.zed/bash_completion" ] && \. "$HOME/.zed/bash_completion"

# Git Subrepo
[ -f "$HOME/bin/git-subrepo/.rc" ] && source "$HOME/bin/git-subrepo/.rc"

# --- Tool Integrations ---

# EDITOR
if command -v nvim &>/dev/null; then
    export EDITOR=nvim
elif command -v vim &>/dev/null; then
    export EDITOR=vim
else
    export EDITOR=vi
fi

# FZF
if command -v fzf &>/dev/null; then
    source <(fzf --bash)
fi

# Kubectl
if command -v kubectl &>/dev/null; then
    source <(kubectl completion bash)
fi

# Scaleway CLI
if command -v scw &>/dev/null; then
    eval "$(scw autocomplete script shell=bash)"
fi

# Docker
export DOCKER_CONTENT_TRUST=0

# Build flags
export BB_NUMBER_THREADS="16"
export PARALLEL_MAKE="-j16"

# Source welcome screen if exists
[[ -f ~/.welcome_screen ]] && . ~/.welcome_screen

# Limits recursive functions
[[ -z "$FUNCNEST" ]] && export FUNCNEST=100
