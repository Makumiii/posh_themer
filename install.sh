#!/usr/bin/env bash
REPO_URL="https://github.com/Makumiii/posh_themer.git"
FOLDER_NAME="posh_themer"
USER_BIN_PATH="$HOME/.local/bin"

export PATH="$USER_BIN_PATH:$HOME/.deno/bin:$PATH"

cat <<EOF 
-----WELCOME TO POSH_THEMER-----
Installation will run now
--------------------------------
EOF

echo checking if already installed
cd "$HOME" || exit

ensure_deno(){
    if command -v deno >/dev/null 2>&1; then
        return 0
    fi

    echo "deno not found, installing deno"
    curl -fsSL https://deno.land/install.sh | sh || { echo "failed to install deno" ; return 1; }
    ln -sf "$HOME/.deno/bin/deno" "$USER_BIN_PATH/deno"
}

install(){
    mkdir -p "$USER_BIN_PATH" || { echo "failed to create $USER_BIN_PATH" ; return 1; }
    ensure_deno || return 1
    git clone $REPO_URL || { echo "failed to clone repo" ; return 1; }
    cd "$USER_BIN_PATH" || { echo "failed to navigate to path" ; return 1; }
    cp "$HOME/$FOLDER_NAME/posh_theme.sh" "$USER_BIN_PATH"
    mv "posh_theme.sh" "posh_theme"


    chmod +x posh_theme
    { echo "success installing posh_themer" ; return 0; }

}

if [ -d "$HOME/$FOLDER_NAME" ]; then
    echo Already installed

    echo Remove existing folder at ~/posh_themer

else
    echo Proceeding with installation
    install
fi


