
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <GLKit/GLKit.h>

#define DEGREES(radians) ((radians) * (180.0 / M_PI))
#define RADIANS(degrees) ((degrees) * (M_PI / 180.0))

#define PLANET_RADIUS 6371000

@interface PMCartography : NSObject

+(float)bearingFromOrigin:(CLLocationCoordinate2D)origin toDestination:(CLLocationCoordinate2D)destination;
+(float)distanceBetweenOrigin:(CLLocationCoordinate2D)origin andDestination:(CLLocationCoordinate2D)destination;
+(CLLocationCoordinate2D)locationAtDistance:(float)distance fromOrigin:(CLLocationCoordinate2D)origin toBearing:(float)bearing;
+(CLLocationDegrees)latitudeClosestToPoleForLatitude:(CLLocationDegrees)latitude andBearing:(double)bearing;
+(GLKVector3)vectorFromCoordinate:(CLLocationCoordinate2D)coordinate;

@end
