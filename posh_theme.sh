#!/bin/bash
FOLDER_NAME="posh_themer"
DENO_CMD="deno -A $HOME/$FOLDER_NAME/index.ts"

INSTRUCTION="${1,,}"


if [ "$INSTRUCTION" = "uninstall" ]; then 
    cd "$HOME/posh_themer" || exit
    ./uninstall
else
 

    $DENO_CMD
    source "$HOME/.zshrc"


fi

