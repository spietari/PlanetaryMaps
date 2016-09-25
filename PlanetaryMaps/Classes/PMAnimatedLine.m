#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>

#import "PMAnimatedLine.h"
#import "PMCartography.h"

@interface PMAnimatedLine()
{    
    GLuint _vertexArray;
}

@property (nonatomic, strong) NSMutableArray* points;
@property (nonatomic, strong) NSMutableArray* locations;

@property (nonatomic, assign) CFTimeInterval birthTime;
@property (nonatomic, assign) CGFloat age;
@property (nonatomic, assign) CGFloat lifetime;
@property (nonatomic, assign) CFTimeInterval lastRenderTime;

@property (nonatomic, strong) PMColorProgram *program;
@property (nonatomic, assign) CGFloat planetSizeMultiplier;

@end

@implementation PMAnimatedLine

-(instancetype)initWithLocations:(NSArray *)locations andPlanetSizeMultiplier:(CGFloat)planetSizeMultiplier andProgram:(PMColorProgram *)program andVertexArray:(GLuint)vertexArray andLength:(CGFloat)length
{
    if (self = [super init])
    {
        self.locations = locations;
        self.planetSizeMultiplier = planetSizeMultiplier;
        self.program = program;
        
        self.lifetime = length;
        
        _vertexArray = vertexArray;
        
        self.birthTime = CACurrentMediaTime();
    }
    return self;
}

-(BOOL)renderWithCoordinate:(CLLocationCoordinate2D)eye distance:(CGFloat)distance viewSize:(CGSize)viewSize andScale:(CGFloat)scale andSpeed:(CGFloat)speed
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
    
    CGFloat relativeAge = self.age / self.lifetime;
    
    if (relativeAge < 0.2)
    {
        GLKVector4 color = self.program.color.value;
        self.program.color.value = GLKVector4Make(color.x, color.y, color.z, relativeAge * 5  * color.w);
    }
//    else if (relativeAge > 0.9)
//    {
//        GLKVector4 color = self.program.color.value;
//        self.program.color.value = GLKVector4Make(color.x, color.y, color.z, (1 - relativeAge) * 10  * color.w);
//    }
    
    NSInteger index1 = floorf(self.locations.count * relativeAge);
    NSInteger index2 =  ceilf(self.locations.count * relativeAge);
    
    if (index1 >= self.locations.count)
    {
        index1 = self.locations.count - 1;
    }
    
    if (index2 >= self.locations.count)
    {
        index2 = self.locations.count - 1;
    }
    
    NSArray *tuple1 = self.locations[index1];
    NSArray *tuple2 = self.locations[index2];
    
    CLLocationCoordinate2D coordinate1 = CLLocationCoordinate2DMake([tuple1[0] doubleValue], [tuple1[1] doubleValue]);
    CLLocationCoordinate2D coordinate2 = CLLocationCoordinate2DMake([tuple2[0] doubleValue], [tuple2[1] doubleValue]);
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake((coordinate1.latitude + coordinate1.latitude) / 2, (coordinate1.longitude + coordinate1.longitude) / 2);
    
    glDisable(GL_DEPTH_TEST);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);
    glEnable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    
    glBindVertexArrayOES(_vertexArray);

    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4MakeOrtho(0, viewSize.width, 0, viewSize.height, -1000 / distance, 1000 / distance);

    modelViewProjectionMatrix = GLKMatrix4Translate(modelViewProjectionMatrix, viewSize.width / 2, viewSize.height / 2, 0);
    
    GLKMatrix4 rot = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(-eye.latitude), 1, 0, 0), GLKMatrix4MakeRotation(RADIANS(-eye.longitude), 0, 1, 0));
    GLKMatrix4 rot2 = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(coordinate.longitude), 0, 1, 0), GLKMatrix4MakeRotation(RADIANS(coordinate.latitude), 1, 0, 0));
    
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, rot);
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, rot2);
    
    // TODO What 82?
    modelViewProjectionMatrix = GLKMatrix4Translate(modelViewProjectionMatrix, 0, 0, _planetSizeMultiplier * 82 / distance);
    
    modelViewProjectionMatrix = GLKMatrix4Scale(modelViewProjectionMatrix, scale / 2, scale / 2, 1);
    
    self.program.modelViewMatrix.value = modelViewProjectionMatrix;
    
    [self.program use];
    
    //glActiveTexture(GL_TEXTURE0);
    //glBindTexture(GL_TEXTURE_2D, self.texture);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    glBindVertexArrayOES(0);
    
    return YES;
}

@end
