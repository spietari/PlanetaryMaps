#!/bin/bash

if [  $# -le 0 ] 
then 
    echo -e "This script removes all kml and blank png files from a folder."
    echo -e "\nUsage:\n$0 tile_folder_to_optimize\n" 
    exit 1
fi  

find $1 -name "*.kml" -delete

for OUTFILE in `find $1 | grep '\.png$'` ; do

    if [[ $OUTFILE == *"mask"* ]]
    then
        echo "Skip ${OUTFILE}"
        continue
    fi

    FILE=${OUTFILE%.*}

    # check if image is empty
    CNT=`gdalinfo -mm -noct -nomd "$OUTFILE" | grep 'Min/Max' | \
       cut -f2 -d= | head -n 3 | tr ',' '\n' | uniq | wc -l`
    if [ "$CNT" -ne 6 ] ; then
        echo "Deleting blank image $OUTFILE"
        \rm "$OUTFILE"
        continue
    fi

done

find $1 -type d -empty -delete