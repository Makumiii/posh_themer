#!/usr/bin/env bash
FOLDER_NAME="posh_themer"
export PATH="$HOME/.local/bin:$HOME/.deno/bin:$PATH"
DENO_CMD="deno -A $HOME/$FOLDER_NAME/index.ts"

INSTRUCTION="${1,,}"


if [ "$INSTRUCTION" = "uninstall" ]; then 
    cd "$HOME/posh_themer" || exit
    ./uninstall.sh
else
 

    $DENO_CMD

    exec zsh

fi
