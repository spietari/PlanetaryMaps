#!/bin/sh

# This sample downloads the Terminal Area Charts from FAA and processes them into PNG tiles.
# The script doesn't delete the resulting huge _pro.tif files and you should delete them manually.
# FAA Charts are of great quality so zoom level 10 can be used here. Note that it takes a long
# time to generate zoom level 10 base tiles.

./faa_tac_download.py TAC
../../tif2vrt.py TAC.vrt download/*.zip  --json_bounds tac.json --ignore "Planning,Graphic,FLY"
../../gdal2tiles.py --zoom 1-10 -p geodetic --no-kml -w none VRT/TAC.vrt VRT/Tiles/
../../optimise_tiles.sh VRT/Tiles/