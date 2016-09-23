#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "PMColorProgram.h"

@interface PMAnimatedLine : NSObject

-(instancetype)initWithLocations:(NSArray*)locations andPlanetSizeMultiplier:(CGFloat)planetSizeMultiplier andProgram:(PMColorProgram*)program andVertexArray:(GLuint)vertexArray withSpeed:(CGFloat)speed;
-(BOOL)renderWithCoordinate:(CLLocationCoordinate2D)coordinate distance:(CGFloat)distance viewSize:(CGSize)viewSize andScale:(CGFloat)scale;

@end
