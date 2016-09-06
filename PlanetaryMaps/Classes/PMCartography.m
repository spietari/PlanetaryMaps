
#import "PMCartography.h"

@implementation PMCartography

+(float)bearingFromOrigin:(CLLocationCoordinate2D)origin toDestination:(CLLocationCoordinate2D)destination
{
    float φ1 = RADIANS(origin.latitude);
    float λ1 = RADIANS(origin.longitude);
    
    float φ2 = RADIANS(destination.latitude);
    float λ2 = RADIANS(destination.longitude);
    
    float y = sin(λ2 - λ1) * cos(φ2);
    float x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(λ2 - λ1);
    float bearing = atan2(y, x);
    return bearing;
}

+(float)distanceBetweenOrigin:(CLLocationCoordinate2D)origin andDestination:(CLLocationCoordinate2D)destination
{
    float φ1 = RADIANS(origin.latitude);
    float λ1 = RADIANS(origin.longitude);
    
    float φ2 = RADIANS(destination.latitude);
    float λ2 = RADIANS(destination.longitude);
    
    float R = PLANET_RADIUS; // meters
    float Δφ = φ2 - φ1;
    float Δλ = λ2 - λ1;
    
    float a = sin(Δφ / 2) * sin(Δφ / 2) + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2);
    float c = 2 * atan2(sqrt(a), sqrt(1 - a));
    float distance = R * c;
    
    return distance;
}

+(CLLocationCoordinate2D)locationAtDistance:(float)distance fromOrigin:(CLLocationCoordinate2D)origin toBearing:(float)bearing
{
    float R = PLANET_RADIUS; // meters
    
    float φ1 = RADIANS(origin.latitude);
    float λ1 = RADIANS(origin.longitude);
    
    float φ = asin(sin(φ1) * cos(distance / R) + cos(φ1) * sin(distance / R) * cos(bearing) );
    float λ = λ1 + atan2(sin(bearing) * sin(distance / R) * cos(φ1), cos(distance / R) - sin(φ1) * sin(φ));
    
    return CLLocationCoordinate2DMake(DEGREES(φ), DEGREES(λ));
}

+(CLLocationDegrees)latitudeClosestToPoleForLatitude:(CLLocationDegrees)latitude andBearing:(double)bearing
{
    double φ = RADIANS(latitude);
    double θ = bearing;
    double latitudeMax = acos(fabs(sin(θ)*cos(φ)));
    return DEGREES(latitudeMax);
}

+(GLKVector3)vectorFromCoordinate:(CLLocationCoordinate2D)coordinate
{
    GLfloat latitude = RADIANS(coordinate.latitude);
    GLfloat longitude = RADIANS(coordinate.longitude);
    
    float tx = cos(latitude) * sin(longitude);
    float ty = sin(latitude);
    float tz = cos(latitude) * cos(longitude);
    
    return GLKVector3Make(tx, ty, tz);
}

@end
