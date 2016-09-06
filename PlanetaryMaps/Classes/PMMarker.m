
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>

#import "PMMarker.h"

#import "PMCartography.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface PMMarker()

@end

@implementation PMMarker

-(instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate size:(CGSize)size planetSizeMultiplier:(CGFloat)planetSizeMultiplier
{
    if (self = [super init])
    {
        self.coordinate = coordinate;
        self.size = size;
        self.planetSizeMultiplier = planetSizeMultiplier;
        vertices = nil;
    }
    return self;
}

- (void)dealloc
{
    if (vertices)
    {
        free(vertices);
    }
    glDeleteTextures(1, (const GLuint*)&_texture);
}

+(GLint)textureFromImage:(UIImage*)image
{
    GLint textureID;
    
    GLubyte* textureData = malloc(image.size.width * image.size.height * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * image.size.width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(textureData, image.size.width, image.size.height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextClearRect(context, CGRectMake(0, 0, image.size.width, image.size.height));
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    CGContextRelease(context);
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(1, (GLuint*)&textureID);
    
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    
    free(textureData);

    return textureID;
}

-(void)setImage:(UIImage *)image
{
    if (_image == image)
    {
        return;
    }
    _image = image;
    self.texture = [PMMarker textureFromImage:image];
}

-(void)setTexture:(GLint)texture
{
    _texture = texture;
    [self makeVertices];
    [self setupGL];
}

-(void)setupGL
{
    self.program = [[PMMarkerProgram alloc]initWithName:@"MarkerShader"];
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, (3 + 2) * vertexCount * sizeof(GLfloat), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, (3 + 2) * sizeof(GLfloat), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, (3 + 2) * sizeof(GLfloat), BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
}

-(void)makeVertices
{
    vertexCount = 4;
    if (vertices)
    {
        free(vertices);
    }
    vertices = malloc(vertexCount * (3 + 2) * sizeof(GLfloat));

    // TODO Redo with vectors only.
    CLLocationCoordinate2D top = [PMCartography locationAtDistance:self.size.height / 2 fromOrigin:self.coordinate toBearing:0];
    
    CLLocationCoordinate2D l1 = [PMCartography locationAtDistance:self.size.width / 2 fromOrigin:top toBearing:RADIANS(-90)];
    CLLocationCoordinate2D l2 = [PMCartography locationAtDistance:self.size.width     fromOrigin:l1  toBearing:RADIANS( 90)];
    CLLocationCoordinate2D l3 = [PMCartography locationAtDistance:self.size.height    fromOrigin:l2  toBearing:RADIANS(180)];
    CLLocationCoordinate2D l4 = [PMCartography locationAtDistance:self.size.width     fromOrigin:l3  toBearing:RADIANS(-90)];
    
    GLKVector3 v1 = [PMCartography vectorFromCoordinate:l1];
    GLKVector3 v2 = [PMCartography vectorFromCoordinate:l2];
    GLKVector3 v3 = [PMCartography vectorFromCoordinate:l3];
    GLKVector3 v4 = [PMCartography vectorFromCoordinate:l4];
      
    GLfloat v[20] = {
        v1.x / _planetSizeMultiplier, v1.y / _planetSizeMultiplier, v1.z / _planetSizeMultiplier, 0, 0,
        v4.x / _planetSizeMultiplier, v4.y / _planetSizeMultiplier, v4.z / _planetSizeMultiplier, 0, 1,
        v2.x / _planetSizeMultiplier, v2.y / _planetSizeMultiplier, v2.z / _planetSizeMultiplier, 1, 0,
        v3.x / _planetSizeMultiplier, v3.y / _planetSizeMultiplier, v3.z / _planetSizeMultiplier, 1, 1,
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
    
    CGFloat aspect = viewSize.width / viewSize.height;
    
    GLKMatrix4 rot = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(coordinate.latitude), 1, 0, 0), GLKMatrix4MakeRotation(-RADIANS(coordinate.longitude), 0, 1, 0));
    
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4MakeOrtho(-aspect, aspect, -1, 1, 3/distance, -3/distance);
    self.program.modelViewMatrix.value = GLKMatrix4Scale(GLKMatrix4Multiply(modelViewProjectionMatrix, rot), 1 / distance, 1 / distance, 1 / distance);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.texture);
    
    [self.program use];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)vertexCount);
    
    glBindVertexArrayOES(0);
    
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
}

@end

@interface PMMarkerSet()

@property (nonatomic, strong) NSMutableDictionary *mutableMarkers;

@end

@implementation PMMarkerSet

-(instancetype)init
{
    if (self = [super init])
    {
        self.mutableMarkers = [[NSMutableDictionary alloc]init];
        self.visibleMarkers = [[NSMutableDictionary alloc]init];
    }
    return self;
}

-(NSDictionary *)markers
{
    return self.mutableMarkers;
}

-(void)addMarker:(PMMarker *)marker forKey:(NSObject<NSCopying>*)key
{
    self.mutableMarkers[key] = marker;
}

-(void)invalidate
{
    BOOL first = YES;
    for (NSNumber* markerIndex in self.mutableMarkers.allKeys)
    {
        PMMarker* marker = self.mutableMarkers[markerIndex];
        if (first) {
            first = NO;
            self.boundNorthWest = marker.coordinate;
            self.boundNorthEast = marker.coordinate;
            self.boundSouthEast = marker.coordinate;
            self.boundSouthWest = marker.coordinate;
        } else {
            
            if (self.boundNorthWest.latitude < marker.coordinate.latitude || self.boundNorthWest.longitude > marker.coordinate.longitude)
            {
                self.boundNorthWest = CLLocationCoordinate2DMake(MAX(self.boundNorthWest.latitude, marker.coordinate.latitude), MIN(self.boundNorthWest.longitude, marker.coordinate.longitude));
            }
            
            if (self.boundNorthEast.latitude < marker.coordinate.latitude || self.boundNorthWest.longitude < marker.coordinate.longitude)
            {
                self.boundNorthEast = CLLocationCoordinate2DMake(MAX(self.boundNorthEast.latitude, marker.coordinate.latitude), MAX(self.boundNorthEast.longitude, marker.coordinate.longitude));
            }
            
            if (self.boundSouthEast.latitude > marker.coordinate.latitude || self.boundSouthEast.longitude < marker.coordinate.longitude)
            {
                self.boundSouthEast = CLLocationCoordinate2DMake(MIN(self.boundSouthEast.latitude, marker.coordinate.latitude), MAX(self.boundSouthEast.longitude, marker.coordinate.longitude));
            }
            
            if (self.boundSouthWest.latitude > marker.coordinate.latitude || self.boundSouthWest.longitude > marker.coordinate.longitude)
            {
                self.boundSouthWest = CLLocationCoordinate2DMake(MIN(self.boundSouthWest.latitude, marker.coordinate.latitude), MIN(self.boundSouthWest.longitude, marker.coordinate.longitude));
            }
        }
    }
}

@end