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

@property (nonatomic, assign) double lifetime;
@property (nonatomic, assign) double birth;

@property (nonatomic, strong) PMColorProgram *program;
@property (nonatomic, assign) CGFloat planetSizeMultiplier;

@end

@implementation PMAnimatedLine

-(instancetype)initWithLocations:(NSArray *)locations andPlanetSizeMultiplier:(CGFloat)planetSizeMultiplier andProgram:(PMColorProgram *)program andVertexArray:(GLuint)vertexArray withSpeed:(CGFloat)speed
{
    if (self = [super init])
    {
        self.locations = locations;
        self.planetSizeMultiplier = planetSizeMultiplier;
        self.program = program;
        
        _vertexArray = vertexArray;
        
        self.birth = CACurrentMediaTime();
        
        self.lifetime = ((double)arc4random() / 0x100000000) / speed;
        
    }
    return self;
}

-(BOOL)renderWithCoordinate:(CLLocationCoordinate2D)eye distance:(CGFloat)distance viewSize:(CGSize)viewSize andScale:(CGFloat)scale
{
    double age = CACurrentMediaTime() - self.birth;
    
    if (age > self.lifetime)
    {
        return NO;
    }
    
    NSInteger index = self.locations.count * age / self.lifetime;
    
    NSArray *tuple = self.locations[index];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([tuple[0] doubleValue], [tuple[1] doubleValue]);
        
    glDisable(GL_DEPTH_TEST);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);
    glEnable(GL_CULL_FACE);
    glDisable(GL_BLEND);
    
    glBindVertexArrayOES(_vertexArray);

    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4MakeOrtho(0, viewSize.width, 0, viewSize.height, -1000 / distance, 1000 / distance);

    modelViewProjectionMatrix = GLKMatrix4Translate(modelViewProjectionMatrix, viewSize.width / 2, viewSize.height / 2, 0);
    
    GLKMatrix4 rot = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(-eye.latitude), 1, 0, 0), GLKMatrix4MakeRotation(RADIANS(-eye.longitude), 0, 1, 0));
    GLKMatrix4 rot2 = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(coordinate.longitude), 0, 1, 0), GLKMatrix4MakeRotation(RADIANS(coordinate.latitude), 1, 0, 0));
    
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, rot);
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, rot2);
    
    // TODO What 92?
    modelViewProjectionMatrix = GLKMatrix4Translate(modelViewProjectionMatrix, 0, 0, _planetSizeMultiplier * 92 / distance);
    
    modelViewProjectionMatrix = GLKMatrix4Scale(modelViewProjectionMatrix, scale / 2, scale / 2, 1);
    
    self.program.modelViewMatrix.value = modelViewProjectionMatrix;
    
    [self.program use];
    
    //glActiveTexture(GL_TEXTURE0);
    //glBindTexture(GL_TEXTURE_2D, self.texture);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    glBindVertexArrayOES(0);
    
    return age < self.lifetime;
}

@end
