
#import <CoreLocation/CoreLocation.h>

#import "PMTileTools.h"
#import "PMCartography.h"

@implementation PMTileTools

+(void)boundsForTileWithZoom:(NSUInteger)zoom x:(NSUInteger)x y:(NSUInteger)y minCoordinate:(CLLocationCoordinate2D*)minCoordinate maxCoordinate:(CLLocationCoordinate2D*)maxCoordinate
{
    NSUInteger n = [self tilesForZoom:zoom];
    
    CGFloat resolution = 2 * M_PI / n;
        
    CGFloat minLon = -M_PI + x * resolution;
    CGFloat maxLon = -M_PI + (x + 1) * resolution;
    
    // epsg:4326
    
    CGFloat minLat = -M_PI_2 + y * resolution ;
    CGFloat maxLat = -M_PI_2 + (y + 1) * resolution;
    
    *minCoordinate = CLLocationCoordinate2DMake(DEGREES(minLat), DEGREES(minLon));
    *maxCoordinate = CLLocationCoordinate2DMake(DEGREES(maxLat), DEGREES(maxLon));
    
    /* MERCATOR
     CGFloat minLat = tile.y * resolution - M_PI;
     CGFloat maxLat = (tile.y + 1) * resolution - M_PI;
     
     minLat = 2 * atan(exp(minLat)) - M_PI_2;
     maxLat = 2 * atan(exp(maxLat)) - M_PI_2;
     
     tile.minLatMercator = log(tan(M_PI_4 + minLat / 2.0));
     tile.maxLatMercator = log(tan(M_PI_4 + maxLat / 2.0));
     */
}

+(void)setBoundsForTile:(PMTile*)tile
{

}

+(NSUInteger)tilesForZoom:(NSUInteger)zoom
{
    NSUInteger res = 1;
    for (NSUInteger i = 0; i < zoom; i++)
    {
        res *= 2;
    }
    return res;
}

+(CGPoint)tileCoordinateWithZoom:(NSUInteger)zoom andCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSUInteger n = [self tilesForZoom:zoom];
    CGPoint tileCoordinate;
    
    tileCoordinate.x = n * ((coordinate.longitude + 180) / 360);
    // MERCATOR
    //tileCoordinate.y = n * (1-(log(tan(-lat) + 1 / cos(-lat)) / M_PI)) / 2;
    tileCoordinate.y = n / 2 * (coordinate.latitude + 90) / 180 ;
    return tileCoordinate;
}

@end
