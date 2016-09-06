
#import <CoreLocation/CoreLocation.h>
#import <OpenGLES/ES2/glext.h>

#import "PMPolygonProgram.h"
#import "PMPolygon.h"

#import "PMCartography.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
const NSInteger floatsPerVertex = 6;

@interface PMPolygon() <NSObject>
{
    NSUInteger vertexCount;
    GLfloat* vertices;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}
@property (nonatomic, strong) NSArray* corners;
@property (nonatomic, strong) NSMutableArray* segments;
@property (nonatomic, strong) PMPolygonProgram* program;
@property (nonatomic, assign) BOOL useScreenSpace;
@property (nonatomic, assign) BOOL closed;
@property (nonatomic, assign) NSInteger segmentsPerSide;
@property (nonatomic, assign) CGFloat planetSizeMultiplier;
@end

@implementation PMPolygon

-(instancetype)initWithLocations:(NSArray*)locations useScreenSpace:(BOOL)useScreenSpace closed:(BOOL)closed segmentsPerSide:(NSUInteger)segmentsPerSide width:(CGFloat)width color:(UIColor*)color planetSizeMultiplier:(CGFloat)planetSizeMultiplier
{
    if (self = [super init])
    {
        self.corners = locations;
        self.segments = [[NSMutableArray alloc]init];
        
        self.useScreenSpace = useScreenSpace;
        self.closed = closed;
        
        self.segmentsPerSide = segmentsPerSide;
        
        self.width = width;
        self.color = color;
        
        self.planetSizeMultiplier = planetSizeMultiplier;
        
        self.boundNorth = -90;
        self.boundSouth = 90;
        self.boundEast = -180;
        self.boundWest = 180;
        
        CLLocation* previousLocation = nil;
        for (CLLocation* location in self.corners)
        {
            if (previousLocation)
            {
                [self.segments addObject:[self interpolateLineBetweenOrigin:previousLocation andDestination:location]];
            }
            previousLocation = location;
        }
        if (self.closed)
        {
            [self.segments addObject:[self interpolateLineBetweenOrigin:self.corners.lastObject andDestination:self.corners.firstObject]];
        }
        
        [self tessellate];
        [self setupGL];
    }
    return self;
}

-(void)dealloc
{
    free(vertices);
    vertexCount = 0;
}

-(void)addLocation:(CLLocation*)location toSegment:(NSMutableArray*)segment {
    
    [segment addObject:location];
    
    if (location.coordinate.latitude > self.boundNorth)
    {
        self.boundNorth = location.coordinate.latitude;
    }
    if (location.coordinate.latitude < self.boundSouth)
    {
        self.boundSouth = location.coordinate.latitude;
    }
    if (location.coordinate.longitude > self.boundEast)
    {
        self.boundEast = location.coordinate.longitude;
    }
    if (location.coordinate.longitude < self.boundWest)
    {
        self.boundWest = location.coordinate.longitude;
    }
}

-(NSArray*)interpolateLineBetweenOrigin:(CLLocation*)origin andDestination:(CLLocation*)destination
{
    float bearing = [PMCartography bearingFromOrigin:origin.coordinate toDestination:destination.coordinate];
    float totalDistance = [PMCartography distanceBetweenOrigin:origin.coordinate andDestination:destination.coordinate];

    NSMutableArray* segment = [[NSMutableArray alloc]init];
    [self addLocation:origin toSegment:segment];
    for (NSUInteger i = 1; i < self.segmentsPerSide; i++)
    {
        float d = i * totalDistance / self.segmentsPerSide;
        CLLocationCoordinate2D coordinate = [PMCartography locationAtDistance:d fromOrigin:origin.coordinate toBearing:bearing];
        CLLocation* location = [[CLLocation alloc]initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        [self addLocation:location toSegment:segment];
    }
    [self addLocation:destination toSegment:segment];
    return segment;
}

-(void)tessellateBetweenLocation:(CLLocation*)location1 andLocation:(CLLocation*)location2 sign:(int)sign
{
    float localBearing = [PMCartography bearingFromOrigin:location1.coordinate toDestination:location2.coordinate];
    
    float b1 = localBearing + sign * M_PI / 2;
    float b2 = localBearing - sign * M_PI / 2;
    
    CLLocationCoordinate2D n1 = [PMCartography locationAtDistance:500 fromOrigin:location1.coordinate toBearing:b1];
    CLLocationCoordinate2D n2 = [PMCartography locationAtDistance:500 fromOrigin:location1.coordinate toBearing:b2];
    
    GLKVector3 v1 = [PMCartography vectorFromCoordinate:n1];
    GLKVector3 v2 = [PMCartography vectorFromCoordinate:n2];
    
    if (self.useScreenSpace)
    {
        GLKVector3 v1n = GLKVector3Normalize(GLKVector3Add(v1, GLKVector3Negate(v2)));
        GLKVector3 v2n = GLKVector3Negate(v1n);
        
        // If screen space then we make a degenerate line that is then easy to scale using the normals
        GLKVector3 vl;
        vl = [PMCartography vectorFromCoordinate:location1.coordinate];
        GLfloat v[2 * floatsPerVertex] = {
            vl.x / _planetSizeMultiplier, vl.y / _planetSizeMultiplier, vl.z / _planetSizeMultiplier, v1n.x, v1n.y, v1n.z,
            vl.x / _planetSizeMultiplier, vl.y / _planetSizeMultiplier, vl.z / _planetSizeMultiplier, v2n.x, v2n.y, v2n.z,
        };
        memcpy(vertices + floatsPerVertex * vertexCount, v, 2 * floatsPerVertex * sizeof(GLfloat));
    }
    else
    {
        GLKVector3 v1n = GLKVector3Add(v1, GLKVector3Negate(v2));
        GLKVector3 v2n = GLKVector3Negate(v1n);
        
        GLfloat v[2 * floatsPerVertex] = {
            v1.x / _planetSizeMultiplier, v1.y / _planetSizeMultiplier, v1.z / _planetSizeMultiplier, v1n.x, v1n.y, v1n.z,
            v2.x / _planetSizeMultiplier, v2.y / _planetSizeMultiplier, v2.z / _planetSizeMultiplier, v2n.x, v2n.y, v2n.z,
        };
        memcpy(vertices + floatsPerVertex * vertexCount, v, 2 * floatsPerVertex * sizeof(GLfloat));
    }
    vertexCount += 2;
}

-(void)tessellate
{
    vertices = nil;
    vertexCount = 0;
    
    NSUInteger byteSize = 0;
    
    for (NSArray* segment in self.segments)
    {
        byteSize += 2 * floatsPerVertex * segment.count * sizeof(GLfloat);
        vertices = realloc(vertices, byteSize);
        CLLocation* previousLocation = nil;
        
        for (CLLocation* location in segment)
        {
            CLLocation* targetLocation;
            
            int sign = 1;
            if (previousLocation)
            {
                targetLocation = previousLocation;
            }
            else
            {
                sign = -1;
                targetLocation = segment.lastObject;
            }
            
            [self tessellateBetweenLocation:location andLocation:targetLocation sign:sign];
            
            previousLocation = location;
        }
        
        if (self.closed && segment == self.segments.lastObject)
        {
            byteSize += 2 * floatsPerVertex * sizeof(GLfloat);
            vertices = realloc(vertices, byteSize);
            memcpy(vertices + floatsPerVertex * vertexCount, vertices, 2 * floatsPerVertex * sizeof(GLfloat));
            vertexCount += 2;
        }
    }
}

-(void)setupGL
{
    self.program = [[PMPolygonProgram alloc]initWithName:@"PolygonShader"];
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, floatsPerVertex * vertexCount * sizeof(GLfloat), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, floatsPerVertex * sizeof(GLfloat), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, floatsPerVertex * sizeof(GLfloat), BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
    
    self.segments = nil;
}

-(void)render:(GLKMatrix4*)rotation distance:(CGFloat)distance pixelsPerMeter:(CGFloat)pixelsPerMeter coordinate:(CLLocationCoordinate2D)coordinate viewSize:(CGSize)viewSize
{
    glDisable(GL_DEPTH_TEST);
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);
    glEnable(GL_CULL_FACE);
    
    CGFloat red, green, blue, alpha;
    
    [self.color getRed:&red green:&green blue:&blue alpha:&alpha];

    glBindVertexArrayOES(_vertexArray);
    
    CGFloat aspect = viewSize.width / viewSize.height;
    
    CGFloat w = aspect * distance;//self.bounds.size.width;
    CGFloat h = distance;//self.bounds.size.height;
    
    GLKMatrix4 rot = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(coordinate.latitude), 1, 0, 0), GLKMatrix4MakeRotation(-RADIANS(coordinate.longitude), 0, 1, 0));
    
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4MakeOrtho(-aspect, aspect, -1, 1, 2/distance, -2/distance);
    self.program.modelViewMatrix.value = GLKMatrix4Scale(GLKMatrix4Multiply(modelViewProjectionMatrix, rot), 1/distance, 1/distance, 1/distance);
    self.program.color.value = GLKVector4Make(red, green, blue, alpha);
    
    if (self.useScreenSpace)
    {
        // TODO Where does this magic number come from?
        self.program.scale.value = 3.93 * (pixelsPerMeter * self.width);
    }
    else
    {
        self.program.scale.value = 0.5 * (self.width - 1000.0) / 1000.0;
    }
    
    [self.program use];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, vertexCount);
    
    glBindVertexArrayOES(0);
    
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
}

@end

@interface PMPolygonSet()

@property (nonatomic, strong) NSMutableDictionary *mutablePolygons;

@end

@implementation PMPolygonSet

-(instancetype)init
{
    if (self = [super init])
    {
        self.mutablePolygons = [[NSMutableDictionary alloc]init];
        self.visiblePolygons = [[NSMutableDictionary alloc]init];
    }
    return self;
}

-(NSDictionary *)polygons
{
    return self.mutablePolygons;
}

-(void)addPolygon:(PMPolygon *)polygon forKey:(NSObject *)key
{
    self.mutablePolygons[key] = polygon;
}

-(void)invalidate
{
    BOOL first = YES;
    for (NSNumber* polygonIndex in self.mutablePolygons.allKeys)
    {
        PMPolygon* polygon = self.mutablePolygons[polygonIndex];
        if (first)
        {
            first = NO;
            self.boundNorthWest = CLLocationCoordinate2DMake(polygon.boundNorth, polygon.boundWest);
            self.boundNorthEast = CLLocationCoordinate2DMake(polygon.boundNorth, polygon.boundEast);
            self.boundSouthEast = CLLocationCoordinate2DMake(polygon.boundSouth, polygon.boundEast);
            self.boundSouthWest = CLLocationCoordinate2DMake(polygon.boundSouth, polygon.boundWest);
        }
        else
        {
            if (polygon.boundNorth > self.boundNorthWest.latitude || polygon.boundWest < self.boundNorthWest.longitude)
            {
                self.boundNorthWest = CLLocationCoordinate2DMake(MAX(self.boundNorthWest.latitude, polygon.boundNorth), MIN(self.boundNorthWest.longitude, polygon.boundWest));
            }

            if (polygon.boundNorth > self.boundNorthEast.latitude || polygon.boundEast > self.boundNorthEast.longitude)
            {
                self.boundNorthEast = CLLocationCoordinate2DMake(MAX(self.boundNorthEast.latitude, polygon.boundNorth), MAX(self.boundNorthEast.longitude, polygon.boundEast));
            }

            if (polygon.boundSouth < self.boundSouthEast.latitude || polygon.boundEast > self.boundSouthEast.longitude)
            {
                self.boundSouthEast = CLLocationCoordinate2DMake(MIN(self.boundSouthEast.latitude, polygon.boundSouth), MAX(self.boundSouthEast.longitude, polygon.boundEast));
            }

            if (polygon.boundSouth < self.boundSouthWest.latitude || polygon.boundWest < self.boundSouthWest.longitude)
            {
                self.boundSouthWest = CLLocationCoordinate2DMake(MIN(self.boundSouthWest.latitude, polygon.boundSouth), MIN(self.boundSouthWest.longitude, polygon.boundWest));
            }
        }
    }
}

@end