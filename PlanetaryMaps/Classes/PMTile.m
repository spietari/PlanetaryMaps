
#import <OpenGLES/ES2/glext.h>

#import "PMTile.h"

#import "PMTileTools.h"
#import "PMTileManager.h"

#import "PMCartography.h"

@interface PMTile()
@property (nonatomic, assign) CLLocationCoordinate2D minCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D maxCoordinate;
@end

@implementation PMTile

-(id)initWithZoom:(NSUInteger)zoom X:(NSUInteger)x Y:(NSUInteger)y layer:(NSUInteger)layer planetSizeMultiplier:(CGFloat)planetSizeMultiplier
{
    if (self = [super init])
    {
        self.downloading = NO;
        self.zoom = zoom;
        self.x = x;
        self.y = y;
        self.layer = layer;
        self.segmentsPerSide = 45;
        self.planetSizeMultiplier = planetSizeMultiplier;
        
        vertices = nil;
        [PMTileTools boundsForTileWithZoom:zoom x:x y:y minCoordinate:&_minCoordinate maxCoordinate:&_maxCoordinate];
    }
    return self;
}

-(void)makeVertices
{
    NSInteger count = self.segmentsPerSide;
    
    vertexCount = 6 * count * count;
    
    if (vertices)
    {
        free(vertices);
    }
    vertices = malloc(vertexCount * 5 * sizeof(GLfloat));
    
    CLLocationDegrees deltaLat = (self.maxCoordinate.latitude  - self.minCoordinate.latitude ) / count;
    CLLocationDegrees deltaLon = (self.maxCoordinate.longitude - self.minCoordinate.longitude) / count;
    
    NSInteger c = 0;
    
    for (NSInteger j = 0; j < count; j++)
    {
        for (NSInteger i = 0; i < count; i++)
        {
            CLLocationDegrees lat = self.minCoordinate.latitude  + j * deltaLat;
            CLLocationDegrees lon = self.minCoordinate.longitude + i * deltaLon;
            
            CLLocationCoordinate2D l1 = CLLocationCoordinate2DMake(lat + deltaLat, lon);
            CLLocationCoordinate2D l2 = CLLocationCoordinate2DMake(lat + deltaLat, lon + deltaLon);
            CLLocationCoordinate2D l3 = CLLocationCoordinate2DMake(lat           , lon + deltaLon);
            CLLocationCoordinate2D l4 = CLLocationCoordinate2DMake(lat           , lon);
            
            GLKVector3 v1 = [PMCartography vectorFromCoordinate:l1];
            GLKVector3 v2 = [PMCartography vectorFromCoordinate:l2];
            GLKVector3 v3 = [PMCartography vectorFromCoordinate:l3];
            GLKVector3 v4 = [PMCartography vectorFromCoordinate:l4];
            
            CGFloat mult = self.planetSizeMultiplier;
            
            GLfloat v[30] = {
                v1.x / mult, v1.y / mult, v1.z / mult, (i + 0) / (GLfloat)count, 1-(j + 1) / (GLfloat)count,
                v4.x / mult, v4.y / mult, v4.z / mult, (i + 0) / (GLfloat)count, 1-(j + 0) / (GLfloat)count,
                v2.x / mult, v2.y / mult, v2.z / mult, (i + 1) / (GLfloat)count, 1-(j + 1) / (GLfloat)count,
                v4.x / mult, v4.y / mult, v4.z / mult, (i + 0) / (GLfloat)count, 1-(j + 0) / (GLfloat)count,
                v3.x / mult, v3.y / mult, v3.z / mult, (i + 1) / (GLfloat)count, 1-(j + 0) / (GLfloat)count,
                v2.x / mult, v2.y / mult, v2.z / mult, (i + 1) / (GLfloat)count, 1-(j + 1) / (GLfloat)count,
            };
        
            memcpy(vertices + c * 30, v, 30 * sizeof(GLfloat));
            c++;
        }
    }
}

-(void)renderWithCoordinate:(CLLocationCoordinate2D)coordinate distance:(CGFloat)distance viewSize:(CGSize)viewSize
{
//    glDisable(GL_DEPTH_TEST);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);
    glEnable(GL_CULL_FACE);
    
    glBindVertexArrayOES(_vertexArray);
    
    CGFloat aspect = viewSize.width / viewSize.height;
    
    GLKMatrix4 rot = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(coordinate.latitude), 1, 0, 0), GLKMatrix4MakeRotation(-RADIANS(coordinate.longitude), 0, 1, 0));
    
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4MakeOrtho(-aspect, aspect, -1, 1, 3/distance, -3/distance);
    self.program.modelViewMatrix.value = GLKMatrix4Scale(GLKMatrix4Multiply(modelViewProjectionMatrix, rot), 1 / distance, 1 / distance, 1 / distance);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.texture);
    
    [self.program use];
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)vertexCount);
    
    glBindVertexArrayOES(0);
    
//    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
}

-(BOOL)isEqualToTile:(PMTile *)tile
{
    return self.layer == tile.layer && self.zoom == tile.zoom && self.x == tile.x && self.y == tile.y;
}

@end
