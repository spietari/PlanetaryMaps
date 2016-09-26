#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>

#import "PMAnimatedLine.h"
#import "PMCartography.h"

@interface PMAnimatedLine()

@property (nonatomic, strong) NSMutableArray* points;
@property (nonatomic, strong) NSMutableArray* locations;

@property (nonatomic, assign) CFTimeInterval birthTime;
@property (nonatomic, assign) CGFloat age;
@property (nonatomic, assign) CGFloat lifetime;
@property (nonatomic, assign) CFTimeInterval lastRenderTime;

@end

@implementation PMAnimatedLine

-(instancetype)initWithLocations:(NSArray *)locations
                       andLength:(CGFloat)length
{
    if (self = [super init])
    {
        self.locations = locations;
        self.lifetime = length;
        self.birthTime = CACurrentMediaTime();
    }
    return self;
}

-(BOOL)renderWithCoordinate:(CLLocationCoordinate2D)eye
                   distance:(CGFloat)distance
                   andSpeed:(CGFloat)speed
              andMVPMatrix1:(GLKMatrix4)mvp1
              andMVPMatrix2:(GLKMatrix4)mvp2
                 andProgram:(PMColorProgram*)program
{
    if (self.lastRenderTime != 0)
    {
        self.age += (distance < 1 ? sqrt(distance) : 1) * speed * (CACurrentMediaTime() - self.lastRenderTime);
    }
    self.lastRenderTime = CACurrentMediaTime();
    
    if (self.age >= self.lifetime)
    {
        return NO;
    }
    
    CGFloat f = (self.maxSpeed - 5) / 35;
    if (f > 1) f = 1;
    
    GLKVector4 color = program.color.value;
    color = GLKVector4Make(color.x, (1 - f) * color.y, (1 - f) * color.z, color.w);
    
    CGFloat relativeAge = self.age / self.lifetime;
    
    if (relativeAge < 0.2)
    {
        program.color.value = GLKVector4Make(color.x, color.y, color.z, relativeAge * 5 * color.w);
    }
    else
    {
        program.color.value = color;
    }
    
//    else if (relativeAge > 0.9)
//    {
//        GLKVector4 color = self.program.color.value;
//        self.program.color.value = GLKVector4Make(color.x, color.y, color.z, (1 - relativeAge) * 10  * color.w);
//    }
    
    NSInteger locationCount = self.locations.count;
    
    NSInteger index1 = floorf(locationCount * relativeAge);
    NSInteger index2 =  ceilf(locationCount * relativeAge);
    
    if (index1 >= locationCount)
    {
        index1 = locationCount - 1;
    }
    
    if (index2 >= locationCount)
    {
        index2 = locationCount - 1;
    }
    
    NSArray *tuple1 = self.locations[index1];
    NSArray *tuple2 = self.locations[index2];
    
    CLLocationCoordinate2D coordinate1 = CLLocationCoordinate2DMake([tuple1[0] doubleValue], [tuple1[1] doubleValue]);
    CLLocationCoordinate2D coordinate2 = CLLocationCoordinate2DMake([tuple2[0] doubleValue], [tuple2[1] doubleValue]);
    
    // TODO Add proper interpolation:
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake((coordinate1.latitude + coordinate1.latitude) / 2, (coordinate1.longitude + coordinate1.longitude) / 2);
    
    GLKMatrix4 rot2 = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(coordinate.longitude), 0, 1, 0), GLKMatrix4MakeRotation(RADIANS(coordinate.latitude), 1, 0, 0));
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(mvp1, rot2);
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, mvp2);
    
    program.modelViewMatrix.value = modelViewProjectionMatrix;
    
    [program bindUniforms];
    
    //glActiveTexture(GL_TEXTURE0);
    //glBindTexture(GL_TEXTURE_2D, self.texture);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    return YES;
}

@end
