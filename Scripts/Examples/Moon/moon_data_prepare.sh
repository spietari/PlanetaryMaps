#!/bin/sh

# This sample downloads a series of GeoTIFFs and converts them into a bunch of geodetic png tiles.
# The maximum zoom level used 6 which roughly corresponds to the resolution of the GeoTIFF files.
# Using a higher zoom level makes no sense unless the original images are of higher resolution. 
# The script doesn't delete the resulting huge _pro.tif files and you should delete them manually.

mkdir download
wget ftp://pdsimage2.wr.usgs.gov/pub/pigpen/moon/clementine/UVVIS_ULCN2005_Basemap_v2/tiles_256ppd/clembase_30n045_256ppd.tif -N -P download/
wget ftp://pdsimage2.wr.usgs.gov/pub/pigpen/moon/clementine/UVVIS_ULCN2005_Basemap_v2/tiles_256ppd/clembase_30n135_256ppd.tif -N -P download/
wget ftp://pdsimage2.wr.usgs.gov/pub/pigpen/moon/clementine/UVVIS_ULCN2005_Basemap_v2/tiles_256ppd/clembase_30n225_256ppd.tif -N -P download/
wget ftp://pdsimage2.wr.usgs.gov/pub/pigpen/moon/clementine/UVVIS_ULCN2005_Basemap_v2/tiles_256ppd/clembase_30n315_256ppd.tif -N -P download/
wget ftp://pdsimage2.wr.usgs.gov/pub/pigpen/moon/clementine/UVVIS_ULCN2005_Basemap_v2/tiles_256ppd/clembase_30s045_256ppd.tif -N -P download/
wget ftp://pdsimage2.wr.usgs.gov/pub/pigpen/moon/clementine/UVVIS_ULCN2005_Basemap_v2/tiles_256ppd/clembase_30s135_256ppd.tif -N -P download/
wget ftp://pdsimage2.wr.usgs.gov/pub/pigpen/moon/clementine/UVVIS_ULCN2005_Basemap_v2/tiles_256ppd/clembase_30s225_256ppd.tif -N -P download/
wget ftp://pdsimage2.wr.usgs.gov/pub/pigpen/moon/clementine/UVVIS_ULCN2005_Basemap_v2/tiles_256ppd/clembase_30s315_256ppd.tif -N -P download/

../../tif2vrt.py Moon.vrt download/*.tif
../../gdal2tiles.py --zoom 1-6 -p geodetic --no-kml -w none VRT/Moon.vrt VRT/Tiles/
../../optimise_tiles.sh VRT/Tiles/