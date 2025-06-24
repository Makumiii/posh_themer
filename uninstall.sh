#!/usr/bin/env bash

echo "starting posh themer uninstall"
FOLDER_NAME="posh_themer"
BIN_FILE_LOCATION="$HOME/.local/bin/posh_theme"
cd "$HOME" || exit

if [ -d "$HOME/$FOLDER_NAME" ] ; then
    #remove source folder
    rm -rf ~/"$FOLDER_NAME"
    #remove bin 
    if [ -f "$BIN_FILE_LOCATION" ]; then 

        rm -f "$BIN_FILE_LOCATION"
    fi

    
    echo "finished unistalling posh_themer assets"
else 
   echo "folder to delete not found"
   exit 1
fi
    

