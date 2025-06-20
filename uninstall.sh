#!/bin/bash

echo "starting posh themer uninstall"
FOLDER_NAME="posh_themer"
cd ~ || exit

if [ -d ~/"$FOLDER_NAME" ] ; then
    #remove source folder
    rm -rf ~/"$FOLDER_NAME"
    #remove function from .zshrc

    sed -i '/#posh_themer:start/,/#posh_themer:end/d' ~/.zshrc
    echo "finished unistalling posh_themer assets"
else 
   echo "folder to delete not found"
   exit 1
fi
    

