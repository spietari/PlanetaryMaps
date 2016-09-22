
#import <GLKit/GLKit.h>
#import <CoreLocation/CoreLocation.h>

#import "PMTileTools.h"
#import "PMTile.h"

#import "PMPolygon.h"
#import "PMMarker.h"
#import "PMScreenMarker.h"

@protocol PMPlanetaryViewDelegate;
@protocol PMTileDataSource;
@protocol PMTileDelegate;
@protocol PMPolygonDataSource;
@protocol PMPolygonDelegate;
@protocol PMMarkerDataSource;
@protocol PMMarkerDelegate;

@interface PMPlanetaryView : GLKView

@property (nonatomic, weak) id<PMPlanetaryViewDelegate> planetaryViewDelegate;

@property (nonatomic, weak) id<PMTileDataSource> tileDataSource;
@property (nonatomic, weak) id<PMTileDelegate> tileDelegate;

@property (nonatomic, weak) id<PMPolygonDataSource> polygonDataSource;
@property (nonatomic, weak) id<PMPolygonDelegate> polygonDelegate;

@property (nonatomic, weak) id<PMMarkerDataSource> markerDataSource;
@property (nonatomic, weak) id<PMMarkerDelegate> markerDelegate;

@property (nonatomic, assign) CLLocationCoordinate2D eye;
@property (nonatomic, assign) CGFloat distance;

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *planetColor;
@property (nonatomic, strong) UIColor *haloColor;
@property (nonatomic, strong) UIColor *lineColor;

@property (nonatomic, assign) CGFloat edgeDimIntensity;
@property (nonatomic, assign) CGFloat haloWidth;

@property (nonatomic, assign) CGFloat lineSpacingInDegrees;
@property (nonatomic, assign) BOOL linesOnTop;

@property (nonatomic, assign) CGFloat minimumDistance;
@property (nonatomic, assign) CGFloat maximumDistance;

-(void)lookAtCoordinate:(CLLocationCoordinate2D)coordinate;
-(void)setLookDistance:(CGFloat)distance;

-(void)reloadPolygons;
-(CLLocationCoordinate2D)coordinateForScreenPoint:(CGPoint)point error:(BOOL*)error;

-(void)reloadMarkers;

-(CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate behind:(BOOL*)behind;

@property (nonatomic, assign) NSInteger cacheSize;
@property (nonatomic, assign) NSInteger maxTiles;
@property (nonatomic, assign) NSInteger maxTilesInDownloadQueue;

-(void)didReceiveMemoryWarning;

@end

@protocol PMPlanetaryViewDelegate <NSObject>
@optional
-(void)planetaryView:(PMPlanetaryView*)view movedToDistance:(CGFloat)distance;
-(void)planetaryView:(PMPlanetaryView*)view movedToCoordinate:(CLLocationCoordinate2D)coordinate;
-(void)planetaryView:(PMPlanetaryView*)view isAboveTileAtZoom:(NSUInteger)zoom x:(NSUInteger)x y:(NSUInteger)y;
-(void)planetaryView:(PMPlanetaryView*)view tappedAt:(CLLocationCoordinate2D)location screenPoint:(CGPoint)screenPoint;
-(void)tilesChangedForPlanetaryView:(PMPlanetaryView*)view;
@end

@protocol PMTileDataSource <NSObject>
-(NSURL*)planetaryView:(PMPlanetaryView*)view urlForTileLayer:(NSUInteger)layer withZoom:(NSUInteger)zoom atX:(NSUInteger)x andY:(NSUInteger)y;
@optional
-(UIImage*)planetaryView:(PMPlanetaryView*)view imageFromData:(NSData*)data forTileLayer:(NSUInteger)layer;
-(NSUInteger)numberOfTileLayersInPlanetaryView:(PMPlanetaryView*)view;
@end

@protocol PMTileDelegate <NSObject>
@optional
-(NSInteger)planetaryView:(PMPlanetaryView*)view segmentsPerSideForTileLayer:(NSUInteger)layer;
@end

@protocol PMPolygonDataSource <NSObject>
-(NSInteger)planetaryView:(PMPlanetaryView*)view numberOfPolygonsInSet:(NSInteger)set;
-(NSArray<CLLocation*>*)planetaryView:(PMPlanetaryView*)view coordinatesForPolygonAtIndex:(NSInteger)index inSet:(NSInteger)set;
@optional
-(NSInteger)numberOfPolygonSetsInPlanetaryView:(PMPlanetaryView*)view;
-(BOOL)planetaryView:(PMPlanetaryView*)view closePolygonAtIndex:(NSInteger)index inSet:(NSInteger)set;
@end

@protocol PMPolygonDelegate <NSObject>
@optional
-(CGFloat)planetaryView:(PMPlanetaryView*)view minimumDistanceForPolygonsInSet:(NSInteger)set;
-(CGFloat)planetaryView:(PMPlanetaryView*)view widthForPolygonOutlinesInSet:(NSInteger)set;
-(UIColor*)planetaryView:(PMPlanetaryView*)view fillColorForPolygonOutlinesInSet:(NSInteger)set;
-(UIColor*)planetaryView:(PMPlanetaryView*)view strokeColorForPolygonOutlinesInSet:(NSInteger)set;
-(UIColor*)planetaryView:(PMPlanetaryView*)view fillColorForPolygonInSet:(NSInteger)set;
-(BOOL)planetaryView:(PMPlanetaryView*)view useScreenSpaceForPolygonsInSet:(NSInteger)set;
-(NSUInteger)planetaryView:(PMPlanetaryView*)view segmentsPerSideForPolygonAtIndex:(NSInteger)index inSet:(NSInteger)set;
@end

@protocol PMMarkerDataSource <NSObject>
-(NSInteger)planetaryView:(PMPlanetaryView*)view numberOfMarkersInSet:(NSInteger)set;
-(CLLocationCoordinate2D)planetaryView:(PMPlanetaryView*)view coordinateForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set;
@optional
-(NSInteger)numberOfMarkerSetsInPlanetaryView:(PMPlanetaryView*)view;
-(GLint)planetaryView:(PMPlanetaryView*)view textureForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set;
-(UIImage*)planetaryView:(PMPlanetaryView*)view imageForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set;
-(CLLocationDegrees)planetaryView:(PMPlanetaryView*)view headingForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set;
@end

@protocol PMMarkerDelegate <NSObject>
@optional
-(CGFloat)planetaryView:(PMPlanetaryView*)view minimumDistanceForMarkersInSet:(NSInteger)set;
-(BOOL)planetaryView:(PMPlanetaryView*)view useScreenSpaceForMarkersInSet:(NSInteger)set;
-(CGSize)planetaryView:(PMPlanetaryView*)view sizeForMarkersInSet:(NSInteger)set;
-(void)planetaryView:(PMPlanetaryView*)view didTapMarkersAtIndices:(NSArray*)indices inSets:(NSArray*)sets;
@end
