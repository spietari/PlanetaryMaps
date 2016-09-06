#!/bin/bash

gdal_translate -of GTiff -co "TILED=YES" -co "TFW=YES" -outsize $3 $4 $1 $2