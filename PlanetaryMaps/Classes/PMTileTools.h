
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "PMTile.h"

@interface PMTileTools : NSObject

+(NSUInteger)tilesForZoom:(NSUInteger)zoom;
+(void)boundsForTileWithZoom:(NSUInteger)zoom x:(NSUInteger)x y:(NSUInteger)y minCoordinate:(CLLocationCoordinate2D*)minCoordinate maxCoordinate:(CLLocationCoordinate2D*)maxCoordinate;
+(void)setBoundsForTile:(PMTile*)tile;
+(CGPoint)tileCoordinateWithZoom:(NSUInteger)zoom andCoordinate:(CLLocationCoordinate2D)coordinate;

@end
