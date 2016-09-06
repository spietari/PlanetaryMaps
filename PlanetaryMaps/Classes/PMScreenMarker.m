
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>

#import "PMScreenMarker.h"

#import "PMCartography.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface PMScreenMarker()

@end

@implementation PMScreenMarker

-(void)makeVertices
{
    vertexCount = 4;
    if (vertices)
    {
        free(vertices);
    }
    vertices = malloc(vertexCount * (3 + 2) * sizeof(GLfloat));
    
    GLfloat v[20] = {
        -1, -1, 0, 0, 0,
         1, -1, 0, 1, 0,
        -1,  1, 0, 0, 1,
         1,  1, 0, 1, 1,
    };
    
    memcpy(vertices, v, vertexCount * (3 + 2) * sizeof(GLfloat));
}

-(void)renderWithCoordinate:(CLLocationCoordinate2D)coordinate distance:(CGFloat)distance viewSize:(CGSize)viewSize
{
    glDisable(GL_DEPTH_TEST);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);
    glEnable(GL_CULL_FACE);
    
    glBindVertexArrayOES(_vertexArray);
    
    CGSize size = CGSizeMake(viewSize.width, viewSize.height);
    
    CGFloat aspect = size.width / size.height;
    
    GLKMatrix4 rot  = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(coordinate.latitude), 1, 0, 0), GLKMatrix4MakeRotation(RADIANS(-coordinate.longitude), 0, 1, 0));
    GLKMatrix4 rot2 = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(self.coordinate.longitude), 0, 1, 0), GLKMatrix4MakeRotation(RADIANS(-self.coordinate.latitude), 1, 0, 0));

    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4MakeOrtho(-aspect, aspect, -1, 1, 2 / distance, -2 / distance);
    
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, rot);
    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix, rot2);
    
    CGFloat relWidth = aspect * self.size.width / size.width;
    CGFloat relHeight = self.size.height / size.height;
    
    modelViewProjectionMatrix = GLKMatrix4Scale(modelViewProjectionMatrix, relWidth, relHeight, 1);
    modelViewProjectionMatrix = GLKMatrix4Translate(modelViewProjectionMatrix, 0, 0, (1 / distance) / self.planetSizeMultiplier);
    modelViewProjectionMatrix = GLKMatrix4Rotate(modelViewProjectionMatrix, RADIANS(self.bearing - 180), 0, 0, -1);
    
    self.program.modelViewMatrix.value = modelViewProjectionMatrix;
    
    [self.program use];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.texture);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)vertexCount);
    
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    glBindVertexArrayOES(0);
}

@end
