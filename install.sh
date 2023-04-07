#! /bin/bash

base=$(dirname "${BASH_SOURCE[0]}")
base_abs=$(readlink -f "$base")

# Get vscode user path
vscode_user_path()
{
    local app=${1:-Code}

    if [[ $OSTYPE == msys || $OSTYPE == cygwin ]]; then
        echo "$(cygpath -ua "$APPDATA")/$app/User"
    elif [[ $OSTYPE = darwin* ]]; then
        echo "$HOME/Library/Application Support/$app/User"
    else
        echo "$HOME/.config/$app/User"
    fi
}

dry_wrap() {
    echo >&2 "RUN:$(printf " %q" "$@")"
    "$@"
}

# Sync one file
# ARGS: $SRC $DST
handle_file()
{
    dry_wrap ln -sf "$1" "$2"
}

# Handle dotfiles for vscode specifically
handle_dotfiles_vscode()
{
    local app tdir

    for app in Code VSCodium; do
        tdir=$(vscode_user_path "$app")
        if [[ ! -d $tdir ]]; then
            echo >&2 "missing $tdir, assuming not installed and skipping"
            continue
        fi
        handle_file "$base_abs/vscode-user-settings.json" "$tdir/settings.json"
        handle_file "$base_abs/vscode-user-keybindings.json" "$tdir/keybindings.json"
    done
}

handle_gitconfig()
(
    if ! command -v git; then
        echo >&2 "missing git"
        return 0
    fi

    git config --global --unset-all include.path
    git config --global --add include.path "$(readlink -f common.gitconfig)"
    git config --global --add include.path "$(readlink -f personal-identity.gitconfig)"
)

main()
{
    set -x
    handle_dotfiles_vscode
    handle_gitconfig
    handle_file "$(readlink -f bashrc)" "$HOME/.bashrc"
}

main "$@"
