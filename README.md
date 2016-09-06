# PlanetaryMaps

[![Version](https://img.shields.io/cocoapods/v/PlanetaryMaps.svg?style=flat)](http://cocoapods.org/pods/PlanetaryMaps)
[![License](https://img.shields.io/cocoapods/l/PlanetaryMaps.svg?style=flat)](http://cocoapods.org/pods/PlanetaryMaps)
[![Platform](https://img.shields.io/cocoapods/p/PlanetaryMaps.svg?style=flat)](http://cocoapods.org/pods/PlanetaryMaps)

## Introduction

PlanetaryMaps is an iOS library written in Objective-C that uses OpenGL to render tiled maps on a planet surface. In addition to the maps you can add bitmap markers and polygons on top of the maps. 

The library uses a simple and clean API that enables easy customization of the map view.

The following screenshots are from the two sample apps. The leftmost is the Swift sample that shows the Moon between latitudes 75S and 75N. The six markers represent the positions of Apollo landers. The lines are just arbitrary connecting lines. The three other screenshots are from the Objective-C sample that displays Federal Aviation Admininistration's Sectional and Terminal Area Charts. This sample uses two map layers and also displays a great circle line between the current position and San Francisco International Airport. The two markers represent SFO airport and the current position along with the current true heading.

![](https://cloud.githubusercontent.com/assets/3495603/18255123/9432787a-73ae-11e6-892c-833d36e9157f.png)
![](https://cloud.githubusercontent.com/assets/3495603/18281729/a7057dfe-7466-11e6-8905-2eb6fe635392.png)
![](https://cloud.githubusercontent.com/assets/3495603/18281730/a7061912-7466-11e6-97de-9f994098144c.png)
![](https://cloud.githubusercontent.com/assets/3495603/18281731/a70d4ea8-7466-11e6-8789-a43d0bb33174.png)

## Requirements

The library itself has no dependencies but to use the scripts to make your own tilesets you will need to install [GDAL](http://www.gdal.org) and possibly ImageMagick (with WebP). 
## Installation

PlanetaryMaps is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PlanetaryMaps"
```

If you have use_frameworks in the Podfile then you must add _import PlanetaryMaps_ statements in your Swift files.

## Examples

There are two examples. One in Swift and one in Objective-C. To run the example project, clone the repo, and run `pod install` in either of the directories under Example.

## Usage

### PMPlanetaryView

This is the main class of the library. Add a GLKView to the project and set it's class to _PMPlanetaryView_. Use the following methods to set the coordinate under camera and the viewing distance. The distance is scaled such that at distance of 1 the height of the planet is exactly the height of the view. 

```objective-c
-(void)lookAtCoordinate:(CLLocationCoordinate2D)coordinate;
-(void)setLookDistance:(CGFloat)distance;
```

In order to control the visual aspect of the planet, halo and the background use the properties in PMPlanetaryView:

```objective-c
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *planetColor;

@property (nonatomic, assign) CGFloat minimumDistance;
@property (nonatomic, assign) CGFloat maximumDistance;

@property (nonatomic, assign) CGFloat haloWidth;
@property (nonatomic, strong) UIColor *haloColor;

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineSpacingInDegrees;
@property (nonatomic, assign) BOOL linesOnTop;

@property (nonatomic, assign) CGFloat edgeDimIntensity;
```

The lines refer to the lines of latitude and longitude that are drawn on the planet. Halo is drawn around the planet if the alpha component of _haloColor_ is non-zero. The property _haloWidth_ is defined as a percentage of the radius of the planet, for example a haloWidth on 100 means that the halo reaches to the distance of one radius from the planet surface. 

The default values for PMPlanetaryView properties are like in this screenshot:

![](https://cloud.githubusercontent.com/assets/3495603/18255122/94323de2-73ae-11e6-953f-cca209cc76ca.png)

The background is black, the planet is gray, the lines are drawn underneath the tiles and the halo is a dim blue. Planet edges are dimmed slightly.

### PMPlanetaryViewDelegate

To get callbacks regarding what user is doing with the view you can implement the following delegate methods:

```objective-c
-(void)planetaryView:(PMPlanetaryView*)view movedToDistance:(CGFloat)distance;
-(void)planetaryView:(PMPlanetaryView*)view movedToCoordinate:(CLLocationCoordinate2D)coordinate;

-(void)planetaryView:(PMPlanetaryView*)view isAboveTileAtZoom:(NSUInteger)zoom x:(NSUInteger)x y:(NSUInteger)y;
-(void)planetaryView:(PMPlanetaryView*)view tappedAt:(CLLocationCoordinate2D)location screenPoint:(CGPoint)screenPoint;

-(void)tilesChangedForPlanetaryView:(PMPlanetaryView*)view;
```

The difference between _movedToCoordinate_ and _isAboveTileAtZoom_ is that the former is called whenever the viewpoint changes and the latter only when the tile changes under the camera.

### PMTileDataSource

To show map tiles on the planet you will have to give PMPlanetaryView a _tileDataSource_ and implement at least the following method:

```objective-c
-(NSURL*)urlForTileLayer:(NSUInteger)layer withZoom:(NSUInteger)zoom atX:(NSUInteger)x andY:(NSUInteger)y;
```

You can either return an NSURL that points to a web resource or a local file.

If you want to use a file type other than what can be decoded by _[UIImage imageWithData:]_ you can also implement:

```objective-c
-(UIImage*)imageFromData:(NSData*)data;
```

WebP is a great image format and can be used through the above delegate method.

If you want to use multiple layers you should implement: 

```objective-c
-(NSUInteger)numberOfTileLayers;
```

### PMTileDelegate

If you want to change the resolution of the 3D geometry that makes one tile you can set the number of segments that each tile is made of: 

```objective-c
-(NSInteger)segmentsPerSideForTileLayer:(NSUInteger)layer;
```

### PMMarkerDataSource 

If you want to display bitmap markers on the planet use this delegate. The first two methods must be implemented. In addition to these two methods you should implement either _imageForMarkerAtIndex_ or _textureForMarkerAtIndex_.

```objective-c
-(NSInteger)numberOfMarkersInSet:(NSInteger)set;
-(CLLocationCoordinate2D)coordinateForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set;
@optional
-(NSInteger)numberOfMarkerSets;
-(GLint)textureForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set;
-(UIImage*)imageForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set;
-(CLLocationDegrees)headingForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set;
```

### PMMarkerDelegate

These are the optional methods for Marker Delegate. The _minimumDistanceForMarkersInSet_ method gives you the option to choose at which distance the marker becomes visible. The _useScreenSpaceForMarkersInSet_ method can be used switch between screen space and world space markers. If the marker is rendered in screen space then _sizeForMarkersInSet_ is given in screen points. If it's in world space then the size is given in meters. The default size is 50x50 points for screen space and 10000 meters for world space.

```objective-c
-(CGFloat)minimumDistanceForMarkersInSet:(NSInteger)set;
-(BOOL)useScreenSpaceForMarkersInSet:(NSInteger)set;
-(CGSize)sizeForMarkersInSet:(NSInteger)set;
-(void)didTapMarkerAtIndices:(NSArray*)indices inSets:(NSArray*)sets;
```

### PMPolygonDataSource

The lines on top of the map are referred to as polygons as groups of lines can be closed to form a polygon (see ToDo). You give the coordinates that make up a polygon through _coordinatesForPolygonAtIndex_ delegate method. You can have an unlimited number of polygon sets and an unlimited number of polygons in one set. The occlusion algorithm is quite efficient so performance is good even with a high number of polygons.

```objective-c
-(NSInteger)numberOfPolygonsInSet:(NSInteger)set;
-(NSArray<CLLocation*>*)coordinatesForPolygonAtIndex:(NSInteger)index inSet:(NSInteger)set;
@optional
-(NSInteger)numberOfPolygonSets;
-(BOOL)closePolygonAtIndex:(NSInteger)index inSet:(NSInteger)set;
```

### PMPolygonDelegate

These delegate methods control the visual aspect of the polygons. The method _fillColorForPolygonStrokesInSet_ refers to the outline of polygon itself, so there are three colors that make up a polygon, the polygon outline has fill and stroke colors and the polygon itself can be filled with a color (only if closed, see ToDo). If the polygon is rendered in screen space then _widthForPolygonOutlinesInSet_ is given in screen points. If it's in world space then the size is given in meters. The default width is 15 points for screen space and 1852 meters (one nautical mile) for world space.

```objective-c
@optional
-(CGFloat)minimumDistanceForPolygonsInSet:(NSInteger)set;
-(CGFloat)widthForPolygonOutlinesInSet:(NSInteger)set;
-(UIColor*)fillColorForPolygonOutlinesInSet:(NSInteger)set;
-(UIColor*)strokeColorForPolygonOutlinesInSet:(NSInteger)set;
-(UIColor*)fillColorForPolygonInSet:(NSInteger)set;
-(BOOL)useScreenSpaceForPolygonsInSet:(NSInteger)set;
```

## ToDo

These two polygon delegate methods have not been implemented yet:

```objective-c
-(UIColor*)strokeColorForPolygonOutlinesInSet:(NSInteger)set;
-(UIColor*)fillColorForPolygonInSet:(NSInteger)set;
```

There are of course many features on the road map including text rendering, tapping inside polygons, Metal / Swift implementations and many more.

## History

This library started as a feasibility study on rendering tiled maps on a spherical surface only using OpenGL shaders. It soon turned out that is not optimal performance-wise so the current implementation uses geometry to render map tiles, markers and polygons.

## Scripts

In the Scripts folder there are several Python and Bash scripts that can be used to convert GeoTIFF and GeoPDF files to tiles that are compatible with PlanetaryMaps. There are two examples that outline the usage of these scripts. Run _faa_tac_data_prepare.sh_ and _moon_data_prepare.sh_ scripts inside _Scripts/Examples_.

The following scripts are available:

### tif2vrt.py

Reprojects the supplied GeoTIFF images into WGS84 and adds them to one VRT file. Requires a working GDAL installation.

### gdal2tiles.py

The VRT file generated by tif2vrt.py can be run through this script to generate the tiles needed for PlanetaryMaps. This is a fork of gdal2tiles.py from GDAL, it has been modified to output larger tiles (1024x1024 pixels).

### optimise_tiles.sh

This scripts takes a directory as a parameter and scans the folder for empty png files and removes them.

### png2webp.sh 

Scans a supplied directory and converts all png images to WebP format. Requires an installation of ImageMagick with WebP support.

### geopdf2geotiff.sh

This script simply converts a GeoPDF file to GeoTIFF that can be supplied to tif2vrt.py.

## Author

Seppo Pietarinen, info@unitedgalactic.com

## License

PlanetaryMaps is available under the MIT license. See the LICENSE file for more info.

=======

