
#import <UIKit/UIKit.h>

#import "PMTileTools.h"

@interface PMPolygon : NSObject

-(instancetype)initWithLocations:(NSArray*)locations useScreenSpace:(BOOL)useScreenSpace closed:(BOOL)closed segmentsPerSide:(NSUInteger)segmentsPerSide width:(CGFloat)width color:(UIColor*)color planetSizeMultiplier:(CGFloat)planetSizeMultiplier;
-(void)render:(GLKMatrix4*)rotation distance:(CGFloat)distance pixelsPerMeter:(CGFloat)pixelsPerMeter coordinate:(CLLocationCoordinate2D)coordinate viewSize:(CGSize)viewSize;

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, strong) UIColor* color;

@property (nonatomic, assign) CLLocationDegrees boundNorth;
@property (nonatomic, assign) CLLocationDegrees boundEast;
@property (nonatomic, assign) CLLocationDegrees boundSouth;
@property (nonatomic, assign) CLLocationDegrees boundWest;

@end

@interface PMPolygonSet : NSObject

-(void)addPolygon:(PMPolygon*)polygon forKey:(NSObject*)key;
-(void)invalidate;

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, readonly) NSDictionary *polygons;
@property (nonatomic, strong) NSMutableDictionary *visiblePolygons;

@property (nonatomic, assign) CLLocationCoordinate2D boundNorthWest;
@property (nonatomic, assign) CLLocationCoordinate2D boundNorthEast;
@property (nonatomic, assign) CLLocationCoordinate2D boundSouthEast;
@property (nonatomic, assign) CLLocationCoordinate2D boundSouthWest;

@property (nonatomic, assign) BOOL useScreenSpace;

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, strong) UIColor* color;

@end
