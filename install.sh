#!/usr/bin/env bash
REPO_URL="https://github.com/Makumiii/posh_themer.git"
FOLDER_NAME="posh_themer"
USER_BIN_PATH="$HOME/.local/bin"
DENO_BIN_PATH="$HOME/.deno/bin"
THEMES_PATH="$HOME/.cache/oh-my-posh/themes"
DEFAULT_THEME="jandedobbeleer.omp.json"
ZSHRC_PATH="$HOME/.zshrc"
BASHRC_PATH="$HOME/.bashrc"

export PATH="$USER_BIN_PATH:$DENO_BIN_PATH:$PATH"

cat <<EOF
-----WELCOME TO POSH_THEMER-----
Installation will run now
--------------------------------
EOF

echo checking if already installed
cd "$HOME" || exit

install_apt_package(){
    package_name="$1"

    if ! command -v apt-get >/dev/null 2>&1; then
        echo "$package_name is required but apt-get was not found."
        echo "Install $package_name manually with your system package manager and run this installer again."
        return 1
    fi

    echo "$package_name not found, installing with apt-get"
    sudo apt-get update || { echo "failed to update apt package lists" ; return 1; }
    sudo apt-get install -y "$package_name" || { echo "failed to install $package_name" ; return 1; }
}

ensure_command(){
    command_name="$1"
    package_name="${2:-$1}"

    if command -v "$command_name" >/dev/null 2>&1; then
        return 0
    fi

    install_apt_package "$package_name" || return 1

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "$command_name is still not available after installing $package_name"
        return 1
    fi
}

ensure_archive_extractor(){
    if command -v unzip >/dev/null 2>&1; then
        return 0
    fi

    if command -v 7z >/dev/null 2>&1; then
        return 0
    fi

    echo "neither unzip nor 7z was found; installing unzip"
    install_apt_package unzip || return 1

    if ! command -v unzip >/dev/null 2>&1; then
        echo "unzip is still not available after installation"
        return 1
    fi
}

ensure_theme_extractor(){
    if command -v unzip >/dev/null 2>&1; then
        return 0
    fi

    echo "unzip is required to extract oh-my-posh themes"
    install_apt_package unzip || return 1

    if ! command -v unzip >/dev/null 2>&1; then
        echo "unzip is still not available after installation"
        return 1
    fi
}

detect_shell(){
    raw_shell="${POSH_THEMER_SHELL:-${SHELL:-}}"
    shell_name="${raw_shell##*/}"

    case "$shell_name" in
        bash|zsh)
            echo "$shell_name"
            return 0
            ;;
    esac

    if command -v zsh >/dev/null 2>&1; then
        echo zsh
        return 0
    fi

    if command -v bash >/dev/null 2>&1; then
        echo bash
        return 0
    fi

    echo "Could not detect a supported shell. Install bash or zsh and run this installer again." >&2
    return 1
}

shell_config_path(){
    shell_name="$1"

    case "$shell_name" in
        bash)
            echo "$BASHRC_PATH"
            ;;
        zsh)
            echo "$ZSHRC_PATH"
            ;;
        *)
            echo "Unsupported shell: $shell_name" >&2
            return 1
            ;;
    esac
}

preflight_dependencies(){
    echo "checking required dependencies"
    shell_name="$(detect_shell)" || return 1
    ensure_command curl curl || return 1
    ensure_command git git || return 1
    ensure_command jq jq || return 1
    ensure_command "$shell_name" "$shell_name" || return 1
    ensure_theme_extractor || return 1
}

ensure_deno(){
    if command -v deno >/dev/null 2>&1; then
        return 0
    fi

    echo "deno not found, installing deno"
    ensure_command curl curl || return 1
    ensure_archive_extractor || return 1
    curl -fsSL https://deno.land/install.sh | sh || { echo "failed to install deno" ; return 1; }
    if [ ! -x "$DENO_BIN_PATH/deno" ]; then
        echo "deno installer completed but $DENO_BIN_PATH/deno was not found"
        return 1
    fi
    ln -sf "$DENO_BIN_PATH/deno" "$USER_BIN_PATH/deno"
    command -v deno >/dev/null 2>&1 || { echo "deno is still not available after installation" ; return 1; }
}

ensure_oh_my_posh(){
    if command -v oh-my-posh >/dev/null 2>&1; then
        return 0
    fi

    echo "oh-my-posh not found, installing oh-my-posh"
    ensure_command curl curl || return 1
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$USER_BIN_PATH" || {
        echo "failed to install oh-my-posh"
        return 1
    }

    if [ ! -x "$USER_BIN_PATH/oh-my-posh" ]; then
        echo "oh-my-posh installer completed but $USER_BIN_PATH/oh-my-posh was not found"
        return 1
    fi

    command -v oh-my-posh >/dev/null 2>&1 || { echo "oh-my-posh is still not available after installation" ; return 1; }
}

ensure_oh_my_posh_themes(){
    if [ -f "$THEMES_PATH/$DEFAULT_THEME" ]; then
        return 0
    fi

    echo "oh-my-posh themes not found, downloading themes"
    ensure_command curl curl || return 1
    ensure_theme_extractor || return 1

    mkdir -p "$THEMES_PATH" || { echo "failed to create $THEMES_PATH" ; return 1; }
    tmp_file="$(mktemp)" || { echo "failed to create temporary file" ; return 1; }

    if ! curl -fsSL "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" -o "$tmp_file"; then
        rm -f "$tmp_file"
        echo "failed to download oh-my-posh themes"
        return 1
    fi

    if ! unzip -oq "$tmp_file" -d "$THEMES_PATH"; then
        rm -f "$tmp_file"
        echo "failed to extract oh-my-posh themes"
        return 1
    fi

    rm -f "$tmp_file"

    if [ ! -f "$THEMES_PATH/$DEFAULT_THEME" ]; then
        echo "default oh-my-posh theme not found at $THEMES_PATH/$DEFAULT_THEME"
        return 1
    fi
}

configure_shellrc(){
    shell_name="$(detect_shell)" || return 1
    shell_config="$(shell_config_path "$shell_name")" || return 1
    path_line='export PATH="$HOME/.local/bin:$HOME/.deno/bin:$PATH"'
    posh_line="eval \"\$(oh-my-posh init $shell_name --config \"\$HOME/.cache/oh-my-posh/themes/jandedobbeleer.omp.json\")\""

    echo "configuring $shell_name prompt in $shell_config"
    touch "$shell_config" || { echo "failed to create $shell_config" ; return 1; }

    if ! grep -Fqx "$path_line" "$shell_config"; then
        printf '\n%s\n' "$path_line" >> "$shell_config" || {
            echo "failed to update PATH in $shell_config"
            return 1
        }
    fi

    tmp_file="$(mktemp)" || { echo "failed to create temporary file" ; return 1; }
    awk -v new_line="$posh_line" '
        /oh-my-posh init (bash|zsh)/ && /--config/ {
            if (!replaced) {
                print new_line
                replaced = 1
            }
            next
        }
        { print }
        END {
            if (!replaced) {
                print new_line
            }
        }
    ' "$shell_config" > "$tmp_file" || {
        rm -f "$tmp_file"
        echo "failed to update oh-my-posh configuration in $shell_config"
        return 1
    }

    mv "$tmp_file" "$shell_config" || {
        rm -f "$tmp_file"
        echo "failed to save $shell_config"
        return 1
    }
}

prepare_environment(){
    mkdir -p "$USER_BIN_PATH" || { echo "failed to create $USER_BIN_PATH" ; return 1; }
    preflight_dependencies || return 1
    ensure_deno || return 1
    ensure_oh_my_posh || return 1
    ensure_oh_my_posh_themes || return 1
    configure_shellrc || return 1
}

install_launcher(){
    cp "$HOME/$FOLDER_NAME/posh_theme.sh" "$USER_BIN_PATH"
    mv -f "$USER_BIN_PATH/posh_theme.sh" "$USER_BIN_PATH/posh_theme"
    chmod +x "$USER_BIN_PATH/posh_theme"
}

install(){
    prepare_environment || return 1
    git clone "$REPO_URL" || { echo "failed to clone repo" ; return 1; }
    install_launcher || { echo "failed to install posh_theme launcher" ; return 1; }
    { echo "success installing posh_themer" ; return 0; }

}

if [ -d "$HOME/$FOLDER_NAME" ]; then
    echo Already installed
    echo Updating dependencies and shell configuration
    prepare_environment && install_launcher

else
    echo Proceeding with installation
    install
fi
