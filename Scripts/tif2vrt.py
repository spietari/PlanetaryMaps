#!/usr/bin/python
from subprocess import call
import sys
import os
import os.path
import json
from subprocess import Popen, PIPE, STDOUT
import argparse

def pixelsToCoordinates(file, tuple):
    proc = Popen(["gdaltransform", "-t_srs", "EPSG:4326", file], stdin=PIPE,stdout=PIPE)
    coordinates=proc.communicate(str(tuple[0]) + " " + str(tuple[1]))[0].split(" ")
    return (float(coordinates[0]), float(coordinates[1]))

def findBounds(file, lt, rt, rb, lb):    
    
    lt_c = pixelsToCoordinates(file, lt)
    mt_c = pixelsToCoordinates(file, ((lt[0] + rt[0]) / 2, (lt[1] + rt[1]) / 2))
    rt_c = pixelsToCoordinates(file, rt)

    rm_c = pixelsToCoordinates(file, ((rt[0] + rb[0]) / 2, (rt[1] + rb[1]) / 2))

    rb_c = pixelsToCoordinates(file, rb)
    mb_c = pixelsToCoordinates(file, ((rb[0] + lb[0]) / 2, (rb[1] + lb[1]) / 2))
    lb_c = pixelsToCoordinates(file, lb)

    lm_c = pixelsToCoordinates(file, ((lt[0] + lb[0]) / 2, (lt[1] + lb[1]) / 2))
    

    l = max(lt_c[0], lm_c[0], lb_c[0]);
    r = min(rt_c[0], rm_c[0], rb_c[0]);

    t = min(lt_c[1], mt_c[1], rt_c[1]);
    b = max(lb_c[1], mb_c[1], rb_c[1]);

    return (l, b, r, t)

def d2m(x, y):
    arg = "%.2f %.2f" %(x, y)
    p = Popen(["cs2cs", "+init=epsg:4326", "+to", "+init=epsg:3857"], stdout=PIPE, stdin=PIPE, stderr=PIPE)
    output = p.communicate(input=arg)[0]
    output = output.replace('\t', ' ')
    outputArray = output.split(" ")
    return (outputArray[0], outputArray[1])

def degreesToMeters(minX, minY, maxX, maxY):
    m1 = d2m(minX, minY)
    m2 = d2m(maxX, maxY)
    return (m1[0], m1[1], m2[0], m2[1])

parser = argparse.ArgumentParser(description="Reprojects the supplied GeoTIFF images into WGS84 and adds them to one VRT file.",epilog="For example: " + sys.argv[0] + " Moon/Moon.vrt Moon/*.tif")
parser.add_argument("output_vrt_name", help="The name of the output vrt file.")
parser.add_argument("tif_files", nargs='*', help="The GeoTIFF input files to process.")
parser.add_argument("--pixel_bounds", help="Optional bounds in pixels, four pixel pairs with origin in upper left corner. Useful for stripping out map legends etc. The order of pixel pair is clockwise from top left corner. For example: \"10,10 990,10 990,990 10,990\"")
parser.add_argument("--json_bounds", help="Optional bounds specified in a JSON file")
parser.add_argument("--ignore", help="A comma-separated string of keywords. The files containing one or more of keywords are ignored. For example: \"Planning,Graphic\"")
args = parser.parse_args()

if args.output_vrt_name is None:
    output = "output.vrt"
else: 
    output = args.output_vrt_name

jsonPixelBounds = None
pixelBounds = None

if args.json_bounds is not None:
    with open (args.json_bounds, "r") as jsonfile:
        jsonContent = jsonfile.read().replace('\n', '')
        jsonPixelBounds = json.loads(jsonContent)
elif args.pixel_bounds is not None:
    pairs = args.pixel_bounds.split(" ")
    if len(pairs) != 4:
        parser.print_help()
        sys.exit(1)
    pixelBounds = []
    for pair in pairs:
        tuple = pair.split(",")
        if len(tuple) != 2:
            parser.print_help()
            sys.exit(1)
        pixelBounds.append((int(tuple[0]), int(tuple[1])))

resultProjTifFiles = []

tempPath = "temp/"

outputPath = "VRT/"
call(["mkdir", outputPath])

ignoreWords = None
if args.ignore is not None:
    ignoreWords = args.ignore.split(",")

for inputFile in args.tif_files:

    filesToProcess = []

    unzipFolder = None

    if inputFile.endswith("zip"):
        call(["mkdir", tempPath])
        unzipFolder = os.path.join(tempPath, os.path.split(inputFile.replace(".zip", ""))[1])
        call(["unzip", "-o", inputFile, "-d", unzipFolder])
        unzippedFiles = os.listdir(unzipFolder)
        filesToProcess.extend([os.path.join(unzipFolder, name) for name in unzippedFiles if name.endswith(".tif")])
    else:
        filesToProcess.append(inputFile)

    for tif in filesToProcess:

        if ignoreWords is not None:
            if any(word in tif for word in ignoreWords):
                print "Ignoring " + tif
                continue

        if tif.endswith("_rgb.tif"):
            call(["rm", tif]);
            continue

        if tif.endswith("_pro.tif"):
            continue

        rgbFile = tif.replace(".tif", "_rgb.tif")
        proFile = os.path.join(outputPath, os.path.split(tif)[1].replace(".tif", "_pro.tif"))

        # Target epsg:3857 is mercator and 4326 is WGS84
        parameters = ["gdalwarp", "-t_srs", "epsg:4326", "-r", "cubic", rgbFile, proFile, "-dstnodata", "0 0 0 0", "-dstalpha"]

        bounds = None

        if jsonPixelBounds is not None:
            for key in jsonPixelBounds.keys():
                if os.path.split(tif)[1].startswith(key):
                    pLeftTop = (jsonPixelBounds[key]["left_top"], jsonPixelBounds[key]["top_left"])
                    pRightTop = (jsonPixelBounds[key]["right_top"], jsonPixelBounds[key]["top_right"])
                    pRightBottom = (jsonPixelBounds[key]["right_bottom"], jsonPixelBounds[key]["bottom_right"])
                    pLeftBottom = (jsonPixelBounds[key]["left_bottom"], jsonPixelBounds[key]["bottom_left"])
                    bounds = findBounds(tif, pLeftTop, pRightTop, pRightBottom, pLeftBottom)
                    break

        if pixelBounds is not None:
            bounds = findBounds(tif, pixelBounds[0], pixelBounds[1], pixelBounds[2], pixelBounds[3])

        if bounds is not None:            
            parameters.extend(["-te", str(bounds[0]), str(bounds[1]), str(bounds[2]), str(bounds[3])])

        if not os.path.exists(proFile):
            print "Convert to RGB"
            call(["gdal_translate", "-expand", "RGB", tif, rgbFile])
            call(parameters)
            call(["rm", rgbFile]);

        resultProjTifFiles.append(proFile)

    if unzipFolder is not None:
        call(["rm", "-rf", unzipFolder]);

call(["rm", "-rf", tempPath]);

parameters = ["gdalbuildvrt", os.path.join(outputPath, output), "-vrtnodata", "0 0 0"]
parameters.extend(resultProjTifFiles);
call(parameters)
