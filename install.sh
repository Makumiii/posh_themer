#!/bin/bash
REPO_URL="git@github.com:Makumiii/posh_themer.git"
FOLDER_NAME="posh_themer"
USER_BIN_PATH="$HOME/.local/bin"

cat <<EOF 
-----WELCOME TO POSH_THEMER-----
Installation will run now
--------------------------------
EOF

echo checking if already installed
cd "$HOME" || exit

install(){
    git clone $REPO_URL || { echo "failed to clone repo" ; return 1; }
    cd "$USER_BIN_PATH" || { echo "failed to navigate to path" ; return 1; }
    cp "$HOME/$FOLDER_NAME/posh_theme.sh" "$USER_BIN_PATH"


    chmod +x posh_theme.sh
    { echo "success installing posh_themer" ; return 0; }

}

if [ -d "$HOME/$FOLDER_NAME" ]; then
    echo Already installed

    echo Remove existing folder at ~/posh_themer

else
    echo Proceeding with installation
    install
fi




