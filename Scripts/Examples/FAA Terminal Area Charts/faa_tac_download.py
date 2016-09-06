#!/usr/bin/python
import re,urllib2,urllib
from subprocess import call
import os
import os.path
import sys
import argparse

parser = argparse.ArgumentParser(description="Downloads either Terminal Area Charts or Sectional charts as GeoTIFF images (packed in ZIP files) from FAA.",epilog="For example: " + sys.argv[0] + " Moon/Moon.vrt Moon/*.tif")
parser.add_argument("type", help="The type of chart (Must be SEC or TAC)")
parser.add_argument("--output-directory", help="The directory the charts are downloaded to")
args = parser.parse_args()

if args.type != "TAC" and args.type != "SEC":
    parser.print_help()
    sys.exit(1)

if args.type == "TAC":
    keyword = "tac_files"
else:
    keyword = "sectional_files"

if args.output_directory is not None:
    output = args.output_directory
else:
    output = "download"

call(["mkdir", output])

htmlpage = urllib2.urlopen("https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/vfr/").read()
alllinks = re.findall('<a href=(.*?)>.*?</a>',htmlpage)
count=1

for link in alllinks:

    if keyword in link and ".zip" in link and "PDFs" not in link:
        
        file = os.path.join(output, os.path.basename(link));
        tempfile = file + ".download"
        
        lastUnderScore = file.rfind("_") + 1
        lastPeriod = file.rfind(".")
        
        version = int(file[lastUnderScore:lastPeriod])

        for i in range(0, version):
            checkFile = "{start}{check}.zip".format(start=file[0:lastUnderScore],check=i);
            if os.path.exists(checkFile):
                print "{file} exists, deleting...".format(file=checkFile)
                call(["rm", checkFile]);

        if os.path.exists("{start}{check}.zip".format(start=file[0:lastUnderScore],check=version+1)):
            print "Newer version exists for {file}".format(file=file)
            continue

        if os.path.exists(file) or os.path.exists(tempfile):
            print "File {file} exists".format(file=file)
            continue
        else:
            print "downloading {link}".format(link=link)
            urllib.urlretrieve(link, file + ".download")
            call(["mv", file + ".download", file])



        

