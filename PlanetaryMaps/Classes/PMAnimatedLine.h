#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "PMColorProgram.h"

@interface PMAnimatedLine : NSObject

-(instancetype)initWithLocations:(NSArray*)locations
                       andLength:(CGFloat)length;

-(BOOL)renderWithCoordinate:(CLLocationCoordinate2D)coordinate
                   distance:(CGFloat)distance
                   andSpeed:(CGFloat)speed
              andMVPMatrix1:(GLKMatrix4)mvp1
              andMVPMatrix2:(GLKMatrix4)mvp2
                 andProgram:(PMColorProgram*)program;

@property (nonatomic, assign) CGFloat maxSpeed;

@end
