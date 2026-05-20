#!/usr/bin/env bash
REPO_URL="https://github.com/Makumiii/posh_themer.git"
FOLDER_NAME="posh_themer"
USER_BIN_PATH="$HOME/.local/bin"
DENO_BIN_PATH="$HOME/.deno/bin"
THEMES_PATH="$HOME/.cache/oh-my-posh/themes"
DEFAULT_THEME="jandedobbeleer.omp.json"
ZSHRC_PATH="$HOME/.zshrc"

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

    install_apt_package "$package_name"
}

ensure_jq(){
    ensure_command jq jq
}

ensure_deno(){
    if command -v deno >/dev/null 2>&1; then
        return 0
    fi

    echo "deno not found, installing deno"
    ensure_command curl curl || return 1
    curl -fsSL https://deno.land/install.sh | sh || { echo "failed to install deno" ; return 1; }
    ln -sf "$DENO_BIN_PATH/deno" "$USER_BIN_PATH/deno"
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
}

ensure_oh_my_posh_themes(){
    if [ -f "$THEMES_PATH/$DEFAULT_THEME" ]; then
        return 0
    fi

    echo "oh-my-posh themes not found, downloading themes"
    ensure_command curl curl || return 1
    ensure_command unzip unzip || return 1

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

configure_zshrc(){
    path_line='export PATH="$HOME/.local/bin:$HOME/.deno/bin:$PATH"'
    posh_line='eval "$(oh-my-posh init zsh --config "$HOME/.cache/oh-my-posh/themes/jandedobbeleer.omp.json")"'

    touch "$ZSHRC_PATH" || { echo "failed to create $ZSHRC_PATH" ; return 1; }

    if ! grep -Fqx "$path_line" "$ZSHRC_PATH"; then
        printf '\n%s\n' "$path_line" >> "$ZSHRC_PATH" || {
            echo "failed to update PATH in $ZSHRC_PATH"
            return 1
        }
    fi

    tmp_file="$(mktemp)" || { echo "failed to create temporary file" ; return 1; }
    awk -v new_line="$posh_line" '
        /oh-my-posh init zsh/ && /--config/ {
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
    ' "$ZSHRC_PATH" > "$tmp_file" || {
        rm -f "$tmp_file"
        echo "failed to update oh-my-posh configuration in $ZSHRC_PATH"
        return 1
    }

    mv "$tmp_file" "$ZSHRC_PATH" || {
        rm -f "$tmp_file"
        echo "failed to save $ZSHRC_PATH"
        return 1
    }
}

prepare_environment(){
    mkdir -p "$USER_BIN_PATH" || { echo "failed to create $USER_BIN_PATH" ; return 1; }
    ensure_jq || return 1
    ensure_deno || return 1
    ensure_oh_my_posh || return 1
    ensure_oh_my_posh_themes || return 1
    configure_zshrc || return 1
}

install_launcher(){
    cp "$HOME/$FOLDER_NAME/posh_theme.sh" "$USER_BIN_PATH"
    mv -f "$USER_BIN_PATH/posh_theme.sh" "$USER_BIN_PATH/posh_theme"
    chmod +x "$USER_BIN_PATH/posh_theme"
}

install(){
    prepare_environment || return 1
    ensure_command git git || return 1
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
