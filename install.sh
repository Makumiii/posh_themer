#!/bin/bash
REPO_URL="git@github.com:Makumiii/posh_themer.git"
FOLDER_NAME="posh_themer"
DENO_CMD="deno -A ~/$FOLDER_NAME/index.ts"

cat <<EOF 
-----WELCOME TO POSH_THEMER-----
Installation will run now
--------------------------------
EOF

echo checking if already installed
cd ~ || exit

install(){
    git clone $REPO_URL

    cat <<EOF >> ~/.zshrc 
#posh_themer:start
function posh_theme(){
    $DENO_CMD && source ~/.zshrc
}
posh_theme
#posh_themer:end

EOF
    
}

if [ -d ~/"$FOLDER_NAME" ]; then
    echo Already installed

    echo Remove existing folder at ~/posh_themer

else
    echo Proceeding with installation
    install
fi




