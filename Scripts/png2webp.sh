#!/bin/bash

if [  $# -le 0 ] 
then 
    echo -e "This script converts all png images to WebP format in a folder and it's subfolders."
    echo -e "Before running this script make sure ImageMagick is available with WebP support."
    echo -e "\nUsage:\n$0 tile_folder_to_convert\n" 
    exit 1
fi  

for OUTFILE in `find $1 | grep '\.png$'` ; do

    if [[ $OUTFILE == *"mask"* ]]
    then
        echo "Skip ${OUTFILE}"
        continue
    fi

    FILE=${OUTFILE%.*}

    echo "Converting to ${FILE}.webp"
    `convert -define webp:lossless=true,method=6 "$OUTFILE" ${FILE}.webp`
    \rm "$OUTFILE"

done
