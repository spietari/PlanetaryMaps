#import <OpenGLES/ES2/glext.h>

#import "PMPlanetaryView.h"

#import "PMCartography.h"

#import "PMTileTools.h"
#import "PMTileManager.h"

#import "PMAnimatedLinesManager.h"

#import "Program/PMDepthProgram.h"
#import "Program/PMPlanetProgram.h"
#import "Program/PMPlanetDimmerProgram.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

GLfloat gPlaneVertexData[30] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     texX, texY
    -0.5, -0.5, 0.5,        -1.0f, -1.0f,
    -0.5,  0.5, 0.5,        -1.0f,  1.0f,
     0.5,  0.5, 0.5,         1.0f,  1.0f,
    -0.5, -0.5, 0.5,        -1.0f, -1.0f,
     0.5,  0.5, 0.5,         1.0f,  1.0f,
     0.5, -0.5, 0.5,         1.0f, -1.0f,
};

@interface PMPlanetaryView() <UIGestureRecognizerDelegate>
{
    GLKMatrix4 _modelViewProjectionMatrix;
    GLuint _vertexBuffer;
}

@property (nonatomic, strong) CADisplayLink *link;

- (void)setupGL;
- (void)tearDownGL;

@property (nonatomic, assign) CGPoint panVelocity;

@property (nonatomic, assign) NSUInteger lastZoom;
@property (nonatomic, assign) NSUInteger lastDoubleTileX;
@property (nonatomic, assign) NSUInteger lastDoubleTileY;

@property (nonatomic, assign) GLKMatrix4 rotation;

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, assign) BOOL blockTileUpdate;

@property (nonatomic, strong) NSMutableArray *greatCircles;

@property (nonatomic, strong) NSMutableDictionary *polygonSets;
@property (nonatomic, strong) NSMutableDictionary *visiblePolygonSets;

@property (nonatomic, strong) NSMutableDictionary *markerSets;
@property (nonatomic, strong) NSMutableDictionary *visibleMarkerSets;

@property (nonatomic, strong) PMDepthProgram *depthProgram;
@property (nonatomic, strong) PMPlanetProgram *planetProgram;
@property (nonatomic, strong) PMPlanetDimmerProgram *planetDimmerProgram;

@property (nonatomic, strong) PMAnimatedLinesManager *animatedLinesManager;

@end

@implementation PMPlanetaryView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        
        if (!self.context) {
            NSLog(@"Failed to create ES context");
        }
        
        self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        
        self.cacheSize = 50;
        self.maxTiles = 50;
        self.maxTilesInDownloadQueue = 75;
        
        self.minimumDistance = 0.01;
        self.maximumDistance = 3;
        self.distance = 1.0;
        self.eye = CLLocationCoordinate2DMake(0, 0);
        
        self.backgroundColor = [UIColor blackColor];
        self.planetColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        self.lineColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        self.haloColor = [[UIColor blueColor] colorWithAlphaComponent:0.2];
        self.haloWidth = 100;
        self.edgeDimIntensity = 0.75;
        self.lineSpacingInDegrees = 10;
        self.linesOnTop = NO;
        
        [PMTileManager sharedManager].planetaryView = self;
        
        self.animatedLinesManager = [[PMAnimatedLinesManager alloc]init];
        self.animatedLinesManager.planetaryView = self;
        
        self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        self.link.frameInterval = 1;
        [self.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
        self.context = nil;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)didReceiveMemoryWarning
{
    [[PMTileManager sharedManager] clearTiles];
}

-(void)setTileDataSource:(id<PMTileDataSource>)tileDataSource
{
    _tileDataSource = tileDataSource;
    [PMTileManager sharedManager].tileDataSource = tileDataSource;
}

-(void)setTileDelegate:(id<PMTileDelegate>)tileDelegate
{
    _tileDelegate = tileDelegate;
    [PMTileManager sharedManager].tileDelegate = tileDelegate;
}

-(void)setAnimatedLinesDataSource:(id<PMAnimatedLinesDataSource>)animatedLinesDataSource
{
    _animatedLinesDataSource = animatedLinesDataSource;
    self.animatedLinesManager.dataSource = animatedLinesDataSource;
}

-(void)setAnimatedLinesDelegate:(id<PMAnimatedLinesDelegate>)animatedLinesDelegate
{
    _animatedLinesDelegate = animatedLinesDelegate;
    self.animatedLinesManager.delegate = animatedLinesDelegate;
}

-(void)setPlanetaryViewDelegate:(id<PMPlanetaryViewDelegate>)planetaryViewDelegate
{
    _planetaryViewDelegate = planetaryViewDelegate;
}

-(void)update
{
    if (!self.initialized)
    {
        self.initialized = YES;
        [self setupRecognizers];
        [self setupGL];
        [self reloadPolygons];
        [self reloadMarkers];
        [self.animatedLinesManager reload];
        self.distance = _distance;
    }
    
    self.eye = CLLocationCoordinate2DMake(self.eye.latitude + self.panVelocity.x, self.eye.longitude + self.panVelocity.y);
    
    [self findVisiblePolygons];
    [self findVisibleMarkers];
    
    self.panVelocity = CGPointMake(0.95 * self.panVelocity.x, 0.95 * self.panVelocity.y);
    
    if (_panVelocity.x * _panVelocity.x + _panVelocity.y * _panVelocity.y > 0.01)
    {
        [self.animatedLinesManager clear];
    }
    
    if (!self.blockTileUpdate)
    {
        [self updateTiles];
    }
    
    [self display];
}

-(void)setDistance:(CGFloat)distance
{
    if (distance >= self.minimumDistance && distance <= self.maximumDistance)
    {
        _distance = distance;
        if (self.initialized)
        {
            self.depthProgram.dist.value = distance;
            self.planetProgram.dist.value = distance;
            self.planetDimmerProgram.dist.value = distance;
            if ([self.planetaryViewDelegate respondsToSelector:@selector(planetaryView:movedToDistance:)])
            {
                [self.planetaryViewDelegate planetaryView:self movedToDistance:distance];
            }
        }
    }
}

-(void)setEye:(CLLocationCoordinate2D)eye
{
    if (eye.latitude > 90)
    {
        eye.latitude = 90;
    }
    else if (eye.latitude < -90)
    {
        eye.latitude = -90;
    }
    
    while (eye.latitude < -180) eye.latitude += 360;
    while (eye.latitude >  180) eye.latitude -= 360;
    
    while (eye.longitude < -180) eye.longitude += 360;
    while (eye.longitude >  180) eye.longitude -= 360;
    
    _eye = eye;
    
    if ([self.planetaryViewDelegate respondsToSelector:@selector(planetaryView:movedToCoordinate:)])
    {
        [self.planetaryViewDelegate planetaryView:self movedToCoordinate:eye];
    }
}

-(void)lookAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    self.eye = coordinate;
    self.panVelocity = CGPointZero;
}

-(void)setLookDistance:(CGFloat)distance
{
    self.distance = distance;
    self.panVelocity = CGPointZero;
}

-(void)setHaloWidth:(CGFloat)haloWidth
{
    _haloWidth = haloWidth;
    self.planetSizeMultiplier = (100 + haloWidth) / 100;
    [self reloadMarkers];
    [self reloadPolygons];
    [PMTileManager sharedManager].planetSizeMultiplier = _planetSizeMultiplier;
}

#pragma mark - Tiles

-(void)updateTiles
{
    NSInteger zoom = 2 - log2(self.distance);
    
    if (zoom < 1) zoom = 1;
    if (zoom > 10) zoom = 10;
    
    CGPoint tilePoint = [PMTileTools tileCoordinateWithZoom:zoom andCoordinate:self.eye];
    
    if (zoom != self.lastZoom || (NSUInteger)(2 * tilePoint.x) != (NSUInteger)(self.lastDoubleTileX) || (NSUInteger)(2 * tilePoint.y) != (NSUInteger)(self.lastDoubleTileY))
    {
        NSUInteger x = (NSUInteger)tilePoint.x;
        NSUInteger y = (NSUInteger)tilePoint.y;
        
        self.lastZoom = zoom;
        self.lastDoubleTileX = (NSUInteger)(2 * tilePoint.x);
        self.lastDoubleTileY = (NSUInteger)(2 * tilePoint.y);
        if ([self.planetaryViewDelegate respondsToSelector:@selector(planetaryView:isAboveTileAtZoom:x:y:)])
        {
            [self.planetaryViewDelegate planetaryView:self isAboveTileAtZoom:zoom x:x y:y];
        }
        
        [[PMTileManager sharedManager] setCurrentZoom:zoom andCoordinate:self.eye];
        
        [self addTilesForZoom:zoom andTilePoint:tilePoint];
    }
}

-(void)addTilesForZoom:(NSUInteger)zoom andTilePoint:(CGPoint)tilePoint
{
    NSMutableArray *tiles = [[NSMutableArray alloc]init];
    
    if (zoom > 1)
    {
        CGPoint baseTilePoint = [PMTileTools tileCoordinateWithZoom:1 andCoordinate:self.eye];
        [tiles addObject:@[@(1), @((NSUInteger)baseTilePoint.x), @((NSUInteger)baseTilePoint.y)]];
        NSUInteger underlyingLayer = zoom == 2 ? 1 : zoom - 2;
        CGPoint previousTilePoint = [PMTileTools tileCoordinateWithZoom:underlyingLayer andCoordinate:self.eye];
        [tiles addObjectsFromArray:[self eightNeighborsForTilePoint:previousTilePoint andZoom:underlyingLayer]];
        [tiles addObject:@[@(underlyingLayer), @((NSUInteger)previousTilePoint.x), @((NSUInteger)previousTilePoint.y)]];
    }
    
    [tiles addObjectsFromArray:[self eightNeighborsForTilePoint:tilePoint andZoom:zoom]];
    [tiles addObject:@[@(zoom), @((NSUInteger)tilePoint.x), @((NSUInteger)tilePoint.y)]];
    
    NSUInteger layers = 1;
    if ([self.tileDataSource respondsToSelector:@selector(numberOfTileLayersInPlanetaryView:)])
    {
        layers = [self.tileDataSource numberOfTileLayersInPlanetaryView:self];
    }
    [[PMTileManager sharedManager] addNewTiles:tiles layerCount:layers];
}

-(NSArray*)eightNeighborsForTilePoint:(CGPoint)tilePoint andZoom:(NSUInteger)zoom
{
    if (zoom == 1)
    {
        return @[@[@(1), @(0), @(0)], @[@(1), @(0), @(1)], @[@(1), @(1), @(0)], @[@(1), @(1), @(1)]];
    }
    
    NSUInteger x = (NSUInteger)tilePoint.x;
    NSUInteger y = (NSUInteger)tilePoint.y;
    
    NSMutableArray *array = [[NSMutableArray alloc]init];

    [array addObject:@[@(zoom), @(x + 1), @(y + 1)]];
    [array addObject:@[@(zoom), @(x + 1), @(y - 1)]];
    
    [array addObject:@[@(zoom), @(x - 1), @(y + 1)]];
    [array addObject:@[@(zoom), @(x - 1), @(y - 1)]];
    
    [array addObject:@[@(zoom), @(x + 0), @(y + 1)]];
    [array addObject:@[@(zoom), @(x + 0), @(y - 1)]];
    
    [array addObject:@[@(zoom), @(x + 1), @(y + 0)]];
    [array addObject:@[@(zoom), @(x - 1), @(y + 0)]];
    
    return array;
}

#pragma mark - Gesture Recognizers

-(void)setupRecognizers
{
    UILongPressGestureRecognizer *tap = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
    tap.delegate = self;
    tap.minimumPressDuration = 0.01;
    [self addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
    pan.delegate = self;
    [self addGestureRecognizer:pan];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinch:)];
    pinch.delegate = self;
    [self addGestureRecognizer:pinch];
}

-(void)tap:(UILongPressGestureRecognizer*)tap
{
    switch (tap.state)
    {
        case UIGestureRecognizerStateBegan:
            self.panVelocity = CGPointZero;
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            CGPoint point = [tap locationInView: self];
            
            BOOL error;
            
            CLLocationCoordinate2D coordinate = [self coordinateForScreenPoint:point error:&error];
            
            if (error)
            {
                return;
            }
            
            CGPoint screenPoint = [self screenPointForCoordinate:coordinate];
            
            if ([self.planetaryViewDelegate respondsToSelector:@selector(planetaryView:tappedAt:screenPoint:)])
            {
                [self.planetaryViewDelegate planetaryView:self tappedAt:coordinate screenPoint:screenPoint];
            }
            
            CGFloat minDistance = -1;
            NSNumber* closestMarkerSetIndex;
            NSNumber* closestMarkerIndex;
            
            NSMutableArray* clickedSets = [[NSMutableArray alloc]init];
            NSMutableArray* clickedIndices = [[NSMutableArray alloc]init];
            
            for (NSNumber* markerSetIndex in self.markerSets.allKeys)
            {
                PMMarkerSet* set = self.markerSets[markerSetIndex];
                for (NSNumber* markerIndex in set.visibleMarkers.allKeys)
                {
                    PMMarker* marker = set.visibleMarkers[markerIndex];
                    CGPoint markerScreenPoint = [self screenPointForCoordinate:marker.coordinate];
                    CGFloat d = sqrt((markerScreenPoint.x - screenPoint.x) * (markerScreenPoint.x - screenPoint.x) + (markerScreenPoint.y - screenPoint.y) * (markerScreenPoint.y - screenPoint.y));
                    if (d < 50 /*&& (d < minDistance || minDistance < 0)*/)
                    {
                        [clickedSets addObject:markerSetIndex];
                        [clickedIndices addObject:markerIndex];
                        minDistance = d;
                        closestMarkerSetIndex = markerSetIndex;
                        closestMarkerIndex = markerIndex;
                    }
                }
            }
            
            if (minDistance >= 0)
            {
                if ([self.markerDelegate respondsToSelector:@selector(planetaryView:didTapMarkersAtIndices:inSets:)])
                {
                    [self.markerDelegate planetaryView:self didTapMarkersAtIndices:clickedIndices inSets:clickedSets];
                }
            }
            
            break;
        }
        default:
            break;
    }
}

-(void)pan:(UIPanGestureRecognizer*)pan
{
    switch (pan.state)
    {
        case UIGestureRecognizerStateBegan:
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            [self.animatedLinesManager clear];
            
            CGPoint translation = [pan translationInView:self];
            [pan setTranslation:CGPointZero inView:self];
            
            CGPoint screenPoint = CGPointMake(self.bounds.size.width / 2 - translation.x, self.bounds.size.height / 2 - translation.y);
            
            BOOL error;
            CLLocationCoordinate2D coordinate = [self coordinateForScreenPoint:screenPoint error:&error];
            
            if (!error)
            {
                if (fabs(coordinate.latitude) < 85)
                {
                    self.eye = coordinate;
                }
                else
                {
                    self.eye = CLLocationCoordinate2DMake(coordinate.latitude, self.eye.longitude - translation.x * self.distance);
                }
                
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            CGPoint velocity = [pan velocityInView:self];
            self.panVelocity = CGPointMake(self.distance * velocity.y / 300, -self.distance * velocity.x / 300);
            break;
        }
        default:
            
        break;
    }
}

-(void)pinch:(UIPinchGestureRecognizer*)pinch
{
    switch (pinch.state)
    {
        case UIGestureRecognizerStateBegan:
            self.blockTileUpdate = YES;
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            [self.animatedLinesManager clear];
            
            CGPoint locationInView = [pinch locationInView:self];
            
            BOOL error1, error2;
            CLLocationCoordinate2D beforePinchCoordinate = [self coordinateForScreenPoint:locationInView error:&error1];
            
            self.distance /= [pinch scale];
            [pinch setScale:1];
            CLLocationCoordinate2D afterPinchCoordinate = [self coordinateForScreenPoint:locationInView error:&error2];
            if (!error1 && !error2)
            {
                self.eye = CLLocationCoordinate2DMake(self.eye.latitude - afterPinchCoordinate.latitude + beforePinchCoordinate.latitude, self.eye.longitude - afterPinchCoordinate.longitude + beforePinchCoordinate.longitude);
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded:
            self.panVelocity = CGPointZero;
            self.blockTileUpdate = NO;
            [self.animatedLinesManager clear];
            break;
            
        default:
            break;
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - OpenGL

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    self.depthProgram = [[PMDepthProgram alloc]initWithName:@"DepthShader"];
    self.planetProgram  = [[PMPlanetProgram alloc]initWithName:@"PlanetShader"];
    self.planetDimmerProgram  = [[PMPlanetDimmerProgram alloc]initWithName:@"PlanetDimmerShader"];
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gPlaneVertexData), gPlaneVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 20, BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 20, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
    
    glFrontFace(GL_CCW);
    glCullFace(GL_BACK);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
}

-(void)drawRect:(CGRect)rect
{
    CGFloat red, green, blue, alpha;
    [self.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    glClearColor(red, green, blue, alpha);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    CGFloat aspect = self.bounds.size.width / self.bounds.size.height;
    
    CGFloat w = aspect * self.distance;
    CGFloat h = self.distance;
    
    _modelViewProjectionMatrix = GLKMatrix4MakeOrtho(-w/2, w/2, h/2, -h/2, -1.0, 0.0);
    
    self.depthProgram.modelViewMatrix.value = _modelViewProjectionMatrix;
    self.planetProgram.modelViewMatrix.value = _modelViewProjectionMatrix;
    self.planetDimmerProgram.modelViewMatrix.value = _modelViewProjectionMatrix;

    self.depthProgram.planetSizeMultiplier.value = _planetSizeMultiplier;
    self.planetProgram.planetSizeMultiplier.value = _planetSizeMultiplier;
    self.planetDimmerProgram.planetSizeMultiplier.value = _planetSizeMultiplier;

    self.rotation = GLKMatrix4MakeRotation(RADIANS(-self.eye.latitude), 0, 1, 0);
    self.rotation = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(self.eye.longitude), 0, 0, 1), self.rotation);
    
    self.planetProgram.rotation.value = self.rotation;
    self.planetDimmerProgram.rotation.value = self.rotation;
    
    [self renderDepth];
    
    if (!self.linesOnTop)
    {
        [self renderPlanet];
    }
    [self renderTiles];
    if (self.linesOnTop)
    {
        [self renderPlanet];
    }

    [self.animatedLinesManager render];
    
    [self renderPlanetDimmer];

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [self renderPolygons];
    [self renderMarkers];
    glDisable(GL_BLEND);

    glBindVertexArrayOES(0);
}

-(void)renderDepth
{
    CGFloat red, green, blue, alpha;
    [self.planetColor getRed:&red green:&green blue:&blue alpha:&alpha];
    self.depthProgram.planetBaseColor.value = GLKVector4Make(red, green, blue, alpha);

    [self.haloColor getRed:&red green:&green blue:&blue alpha:&alpha];
    self.depthProgram.haloBaseColor.value = GLKVector4Make(red, green, blue, alpha);

    // On iOS we can write to depth buffer in the
    // fragment shader only if we use OpenGL ES 3.0 or greater.
    // We write a value of 0 inside the planet and 1 outside.
    // Hence when drawing subsequent triangles at depth 0.5
    // we can control their visibility using a depth test of
    // GL_GREATER for inside the planet and GL_LESS for outside.
    // Note that in order to write to depth buffer in the
    // fragment shader both the depth test and depth mask must
    // be enabled.
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_ALWAYS);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDepthMask(GL_TRUE);
    [self.depthProgram use];
    glBindVertexArrayOES(_vertexArray);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glDepthMask(GL_FALSE);
}

-(void)renderPlanet
{
    CGFloat red, green, blue, alpha;
    [self.lineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    if (alpha > 0.0)
    {
        self.planetProgram.lineColor.value = GLKVector4Make(red, green, blue, alpha);
        self.planetProgram.lineSpacing.value = self.lineSpacingInDegrees;
        
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_GREATER);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_SRC_ALPHA);
        [self.planetProgram use];
        glBindVertexArrayOES(_vertexArray);
        glDrawArrays(GL_TRIANGLES, 0, 6);
    }
}

-(void)renderPlanetDimmer
{
    if (self.edgeDimIntensity > 0)
    {
        self.planetDimmerProgram.edgeDimIntensity.value = self.edgeDimIntensity;
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_GREATER);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_SRC_ALPHA);
        [self.planetDimmerProgram use];
        glBindVertexArrayOES(_vertexArray);
        glDrawArrays(GL_TRIANGLES, 0, 6);
    }
}

-(void)renderTiles
{
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_GREATER);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    for (int t = 0; t < [PMTileManager sharedManager].tiles.count; t++)
    {
        PMTile* tile = [PMTileManager sharedManager].tiles[t];
        [tile renderWithCoordinate:self.eye distance:self.distance viewSize:self.bounds.size];
    }
}

-(CLLocationCoordinate2D)coordinateForScreenPoint:(CGPoint)point error:(BOOL*)error
{
    float sphereDiameter = (self.bounds.size.height / self.distance) / self.planetSizeMultiplier;
    float deltaY = 2 * (self.bounds.size.height / 2 - point.y) / sphereDiameter;
    float deltaX = 2 * (point.x - self.bounds.size.width  / 2) / sphereDiameter;
    
    if (fabs(deltaX) >= 1 || fabs(deltaY) >= 1)
    {
        *error = YES;
        return CLLocationCoordinate2DMake(0, 0);
    }

    float sinLatitude = deltaY;
    float cosLatitude = sqrt(1.0 - sinLatitude * sinLatitude);
    float sinLongitude = deltaX / cosLatitude;
    if (fabs(sinLongitude) >= 1)
    {
        *error = YES;
        return CLLocationCoordinate2DMake(0, 0);
    }
    float cosLongitude = sqrt(1.0 - sinLongitude * sinLongitude);
    
    GLKVector4 rot_eye = GLKMatrix4MultiplyVector4(self.rotation, GLKVector4Make(cosLatitude * cosLongitude, cosLatitude * sinLongitude, sinLatitude, 0));

    float latitude  = atan2(rot_eye.z, sqrt(rot_eye.y * rot_eye.y + rot_eye.x * rot_eye.x));
    float longitude = atan2(rot_eye.y, rot_eye.x);
    if (latitude != latitude || longitude != longitude)
    {
        *error = YES;
        return CLLocationCoordinate2DMake(0, 0);
    }
    *error = NO;
    return CLLocationCoordinate2DMake(DEGREES(latitude), DEGREES(longitude));
}

-(CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    BOOL behind;
    return [self screenPointForCoordinate:coordinate behind:&behind];
}

-(CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate behind:(BOOL*)behind
{
    float sphereDiameter = (self.bounds.size.height / self.distance) / self.planetSizeMultiplier;
    
    // TODO Make the global rotation to be exactly equal to this.
    GLKMatrix4 rot = GLKMatrix4Multiply(GLKMatrix4MakeRotation(RADIANS(self.eye.latitude), 1, 0, 0), GLKMatrix4MakeRotation(-RADIANS(self.eye.longitude), 0, 1, 0));
    CLLocationCoordinate2D l = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude);

    GLKVector3 v = GLKMatrix4MultiplyVector3(rot, [PMCartography vectorFromCoordinate:l]);
    
    float x = v.x * sphereDiameter / 2 + self.bounds.size.width / 2;
    float y = self.bounds.size.height / 2 - v.y * sphereDiameter / 2;
    
    *behind = v.z < 0;

    return CGPointMake(x, y);
}

-(void)reloadPolygons
{
    if (!self.initialized) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.polygonSets = [[NSMutableDictionary alloc]init];
        self.visiblePolygonSets = [[NSMutableDictionary alloc]init];
        
        NSInteger polygonSetCount = 1;
        
        if ([self.polygonDataSource respondsToSelector:@selector(numberOfPolygonSetsInPlanetaryView:)])
        {
            polygonSetCount = [self.polygonDataSource numberOfPolygonSetsInPlanetaryView:self];
        }
        
        for (NSInteger j = 0; j < polygonSetCount; j++)
        {
            PMPolygonSet* set = [[PMPolygonSet alloc]init];
            
            self.polygonSets[@(j)] = set;
            
            NSInteger polygonCount = [self.polygonDataSource planetaryView:self numberOfPolygonsInSet:j];
            
            BOOL useScreenSpace = YES;
            if ([self.polygonDelegate respondsToSelector:@selector(planetaryView:useScreenSpaceForPolygonsInSet:)])
            {
                useScreenSpace = [self.polygonDelegate planetaryView:self useScreenSpaceForPolygonsInSet:j];
            }
            
            if ([self.polygonDelegate respondsToSelector:@selector(planetaryView:widthForPolygonOutlinesInSet:)])
            {
                set.width = [self.polygonDelegate planetaryView:self widthForPolygonOutlinesInSet:j];
            }
            else
            {
                if (useScreenSpace)
                {
                    set.width = 15;
                }
                else
                {
                    set.width = 1852;
                }
            }
            
            if ([self.polygonDelegate respondsToSelector:@selector(planetaryView:fillColorForPolygonOutlinesInSet:)])
            {
                set.color = [self.polygonDelegate planetaryView:self fillColorForPolygonOutlinesInSet:j];
            }
            else
            {
                set.color = [UIColor whiteColor];
            }
            
            for (NSInteger i = 0; i < polygonCount; i++)
            {
                NSArray<CLLocation*>* points = [self.polygonDataSource planetaryView:self coordinatesForPolygonAtIndex:i inSet:j];
                
                
                BOOL closed = NO;
                
                if ([self.polygonDataSource respondsToSelector:@selector(planetaryView:closePolygonAtIndex:inSet:)])
                {
                    closed = [self.polygonDataSource planetaryView:self closePolygonAtIndex:i inSet:j];
                }
                
                NSUInteger segmentsPerSide = 5;
                
                if ([self.polygonDelegate respondsToSelector:@selector(planetaryView:segmentsPerSideForPolygonAtIndex:inSet:)])
                {
                    segmentsPerSide = [self.polygonDelegate planetaryView:self segmentsPerSideForPolygonAtIndex:i inSet:j];
                }
                
                PMPolygon* polygon = [[PMPolygon alloc]initWithLocations:points useScreenSpace:useScreenSpace closed:closed segmentsPerSide:segmentsPerSide width:set.width color:set.color planetSizeMultiplier:self.planetSizeMultiplier];

                [set addPolygon:polygon forKey:@(i)];
            }
            [set invalidate];
        }
    });
}

-(void)findVisiblePolygons
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for (NSNumber* polygonSetIndex in self.polygonSets.allKeys)
        {
            PMPolygonSet* set = self.polygonSets[polygonSetIndex];
            
            NSUInteger setIndex = [polygonSetIndex intValue];

            CGFloat minimumDistance = 3;
            if ([self.polygonDelegate respondsToSelector:@selector(planetaryView:minimumDistanceForPolygonsInSet:)])
            {
                minimumDistance = [self.polygonDelegate planetaryView:self minimumDistanceForPolygonsInSet:setIndex];
            }
            
            BOOL visible;
            
            if (self.distance > minimumDistance)
            {
                visible = false;
            }
            else
            {
                visible = [self quadIsVisibleInScreenSpace:set.useScreenSpace size:CGSizeMake(set.width, set.width) boundNorthWest:set.boundNorthWest boundNorthEast:set.boundNorthEast boundSouthEast:set.boundSouthEast boundSouthWest:set.boundSouthWest];
            }
            
            if (!visible)
            {
                
                [self.visiblePolygonSets removeObjectForKey:polygonSetIndex];
                [set.visiblePolygons removeAllObjects];
                continue;
            }
            
            self.visiblePolygonSets[polygonSetIndex] = set;
            
            for (NSNumber* polygonIndex in set.polygons.allKeys)
            {
                PMPolygon* polygon = set.polygons[polygonIndex];
                
                CLLocationCoordinate2D boundNorthWest = CLLocationCoordinate2DMake(polygon.boundNorth, polygon.boundWest);
                CLLocationCoordinate2D boundNorthEast = CLLocationCoordinate2DMake(polygon.boundNorth, polygon.boundEast);
                CLLocationCoordinate2D boundSouthEast = CLLocationCoordinate2DMake(polygon.boundSouth, polygon.boundEast);
                CLLocationCoordinate2D boundSouthWest = CLLocationCoordinate2DMake(polygon.boundSouth, polygon.boundWest);
                
                BOOL visible = [self quadIsVisibleInScreenSpace:set.useScreenSpace size:CGSizeMake(set.width, set.width) boundNorthWest:boundNorthWest boundNorthEast:boundNorthEast boundSouthEast:boundSouthEast boundSouthWest:boundSouthWest];
                
                if (visible)
                {
                    if (!set.visiblePolygons[polygonIndex])
                    {
                        set.visiblePolygons[polygonIndex] = polygon;
                    }
                }
                else
                {
                    [set.visiblePolygons removeObjectForKey:polygonIndex];
                }
            }
            
        }
    });
}


-(void)renderPolygons
{
    for (NSNumber* polygonSetIndex in self.polygonSets.allKeys)
    {
        PMPolygonSet* set = self.polygonSets[polygonSetIndex];
        for (NSNumber* polygonIndex in set.visiblePolygons.allKeys)
        {
            PMPolygon* polygon = set.visiblePolygons[polygonIndex];
            CGFloat pixelsPerMeter = [UIScreen mainScreen].scale * self.distance * self.bounds.size.height / (PLANET_RADIUS);
            [polygon render:&_rotation distance:self.distance pixelsPerMeter:pixelsPerMeter coordinate:self.eye viewSize:self.bounds.size];
        }
    }
}

-(void)reloadMarkers
{
    if (!self.initialized || !self.markerDataSource) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.markerSets = [[NSMutableDictionary alloc]init];
        self.visibleMarkerSets = [[NSMutableDictionary alloc]init];
        
        NSInteger markerSetCount;
        
        if ([self.markerDataSource respondsToSelector:@selector(numberOfMarkerSetsInPlanetaryView:)])
        {
            markerSetCount = [self.markerDataSource numberOfMarkerSetsInPlanetaryView:self];
        }
        else
        {
            markerSetCount = 1;
        }
        
        for (NSInteger j = 0; j < markerSetCount; j++)
        {
            PMMarkerSet* set = [[PMMarkerSet alloc]init];
            
            set.useScreenSpace = YES;
            if ([self.markerDelegate respondsToSelector:@selector(planetaryView:useScreenSpaceForMarkersInSet:)])
            {
                set.useScreenSpace = [self.markerDelegate planetaryView:self useScreenSpaceForMarkersInSet:j];
            }
            
            if ([self.markerDelegate respondsToSelector:@selector(planetaryView:sizeForMarkersInSet:)])
            {
                set.size = [self.markerDelegate planetaryView:self sizeForMarkersInSet:j];
            }
            else {
                set.size = set.useScreenSpace ? CGSizeMake(50, 50) : CGSizeMake(10000, 10000);
            }
            
            self.markerSets[@(j)] = set;
            
            NSInteger markerCount = [self.markerDataSource planetaryView:self numberOfMarkersInSet:j];
            
            for (NSInteger i = 0; i < markerCount; i++)
            {
                CLLocationCoordinate2D coordinate = [self.markerDataSource planetaryView:self coordinateForMarkerAtIndex:i inSet:j];
                
                PMMarker* marker;
                if (set.useScreenSpace)
                {
                    marker = [[PMScreenMarker alloc]initWithCoordinate:coordinate size:set.size planetSizeMultiplier:self.planetSizeMultiplier];
                }
                else
                {
                    marker = [[PMMarker alloc]initWithCoordinate:coordinate size:set.size planetSizeMultiplier:self.planetSizeMultiplier];
                }
                
                [set addMarker:marker forKey:@(i)];
            }
            [set invalidate];
        }
    });
}

-(void)findVisibleMarkers
{
    dispatch_async(dispatch_get_main_queue(), ^{
            
        for (NSNumber* markerSetIndex in self.markerSets.allKeys)
        {
            PMMarkerSet* set = self.markerSets[markerSetIndex];
            
            for (NSNumber* markerIndex in set.markers.allKeys)
            {
                PMMarker* marker = set.markers[markerIndex];
                if ([self.markerDataSource respondsToSelector:@selector(planetaryView:headingForMarkerAtIndex:inSet:)])
                {
                    marker.bearing = [self.markerDataSource planetaryView:self headingForMarkerAtIndex:[markerIndex intValue] inSet:[markerSetIndex intValue]];
                }
                marker.coordinate = [self.markerDataSource planetaryView:self coordinateForMarkerAtIndex:[markerIndex intValue] inSet:[markerSetIndex intValue]];
                
            }
            [set invalidate];
            
            NSUInteger setIndex = [markerSetIndex intValue];
            
            CGFloat minimumDistance;
            
            if ([self.markerDelegate respondsToSelector:@selector(planetaryView:minimumDistanceForMarkersInSet:)])
            {
                minimumDistance = [self.markerDelegate planetaryView:self minimumDistanceForMarkersInSet:setIndex];
            }
            else
            {
                minimumDistance = 3;
            }
            
            BOOL visible;
            
            if (self.distance > minimumDistance)
            {
                visible = false;
            }
            else
            {
                visible = [self quadIsVisibleInScreenSpace:set.useScreenSpace size:set.size boundNorthWest:set.boundNorthWest boundNorthEast:set.boundNorthEast boundSouthEast:set.boundSouthEast boundSouthWest:set.boundSouthWest];
            }
            
            if (!visible)
            {
                
                [self.visibleMarkerSets removeObjectForKey:markerSetIndex];
                [set.visibleMarkers removeAllObjects];
                continue;
            }
            
            self.visibleMarkerSets[markerSetIndex] = set;
            
            for (NSNumber* markerIndex in set.markers.allKeys)
            {
                PMMarker* marker = set.markers[markerIndex];
                NSUInteger index = [markerIndex intValue];

                BOOL visible = [self pointIsVisibleInScreenSpace:set.useScreenSpace size:set.size coordinate:marker.coordinate];
                
                if (visible)
                {
                    if (!set.visibleMarkers[markerIndex])
                    {
                        GLuint texture = 0;
                        UIImage* image = nil;
                        if ([self.markerDataSource respondsToSelector:@selector(planetaryView:textureForMarkerAtIndex:inSet:)])
                        {
                            texture = [self.markerDataSource planetaryView:self textureForMarkerAtIndex:index inSet:setIndex];
                        }
                        if ([self.markerDataSource respondsToSelector:@selector(planetaryView:imageForMarkerAtIndex:inSet:)])
                        {
                            image = [self.markerDataSource planetaryView:self imageForMarkerAtIndex:index inSet:setIndex];
                        }
                        if (texture > 0)
                        {
                            marker.texture = texture;
                        }
                        else
                        {
                            marker.image = image;
                        }
                        set.visibleMarkers[markerIndex] = marker;
                    }
                }
                else
                {
                    [set.visibleMarkers removeObjectForKey:markerIndex];
                }
            }
        }
    });
}

-(void)renderMarkers
{
    for (NSNumber* markerSetIndex in self.visibleMarkerSets.allKeys)
    {
        PMMarkerSet* set = self.visibleMarkerSets[markerSetIndex];
        for (NSNumber* markerIndex in set.visibleMarkers.allKeys)
        {
            PMMarker* marker = set.visibleMarkers[markerIndex];
            [marker renderWithCoordinate:self.eye distance:self.distance viewSize:self.bounds.size];
        }
    }
}

-(BOOL)quadIsVisibleInScreenSpace:(BOOL)screenSpace size:(CGSize)size boundNorthWest:(CLLocationCoordinate2D)boundNorthWest boundNorthEast:(CLLocationCoordinate2D)boundNorthEast boundSouthEast:(CLLocationCoordinate2D)boundSouthEast boundSouthWest:(CLLocationCoordinate2D)boundSouthWest
{
    
    CGPoint screenPointNorthWest, screenPointNorthEast, screenPointSouthEast, screenPointSouthWest;
    BOOL behindNorthWest, behindNorthEast, behindSouthEast, behindSouthWest;
    
    if (screenSpace)
    {
        screenPointNorthWest = [self screenPointForCoordinate:boundNorthWest behind:&behindNorthWest];
        screenPointNorthEast = [self screenPointForCoordinate:boundNorthEast behind:&behindNorthEast];
        screenPointSouthEast = [self screenPointForCoordinate:boundSouthEast behind:&behindSouthEast];
        screenPointSouthWest = [self screenPointForCoordinate:boundSouthWest behind:&behindSouthWest];
        
        screenPointNorthWest.x -= size.width  / 2;
        screenPointNorthWest.y -= size.height / 2;
        screenPointNorthEast.x += size.width  / 2;
        screenPointNorthEast.y -= size.height / 2;
        
        screenPointSouthEast.x += size.width  / 2;
        screenPointSouthEast.y += size.height / 2;
        screenPointSouthWest.x -= size.width  / 2;
        screenPointSouthWest.y += size.height / 2;
    }
    else
    {
        CLLocationCoordinate2D origin    = boundNorthWest;
        CLLocationCoordinate2D west      = [PMCartography locationAtDistance:size.width  / 2 fromOrigin:origin toBearing:RADIANS(270)];
        CLLocationCoordinate2D northWest = [PMCartography locationAtDistance:size.height / 2 fromOrigin:west   toBearing:RADIANS(  0)];
        screenPointNorthWest = [self screenPointForCoordinate:northWest behind:&behindNorthWest];
        
        origin    = boundNorthEast;
        CLLocationCoordinate2D east      = [PMCartography locationAtDistance:size.width  / 2 fromOrigin:origin toBearing:RADIANS( 90)];
        CLLocationCoordinate2D northEast = [PMCartography locationAtDistance:size.height / 2 fromOrigin:east   toBearing:RADIANS(  0)];
        screenPointNorthEast = [self screenPointForCoordinate:northEast behind:&behindNorthEast];
        
        origin    = boundSouthEast;
        east      = [PMCartography locationAtDistance:size.width  / 2 fromOrigin:origin toBearing:RADIANS( 90)];
        CLLocationCoordinate2D southEast = [PMCartography locationAtDistance:size.height / 2 fromOrigin:east   toBearing:RADIANS(180)];
        screenPointSouthEast = [self screenPointForCoordinate:southEast behind:&behindSouthEast];
        
        origin    = boundSouthWest;
        west      = [PMCartography locationAtDistance:size.width  / 2 fromOrigin:origin toBearing:RADIANS(270)];
        CLLocationCoordinate2D southWest = [PMCartography locationAtDistance:size.height / 2 fromOrigin:west   toBearing:RADIANS(180)];
        screenPointSouthWest = [self screenPointForCoordinate:southWest behind:&behindSouthWest];
    }
    
    return !((screenPointNorthEast.x < 0 && screenPointSouthEast.x < 0) ||
             (screenPointSouthEast.y < 0 && screenPointSouthWest.y < 0) ||
             (screenPointNorthWest.x > self.bounds.size.width  && screenPointSouthWest.x > self.bounds.size.width) ||
             (screenPointNorthEast.y > self.bounds.size.height && screenPointNorthWest.y > self.bounds.size.height) ||
             (behindNorthWest && behindNorthEast && behindSouthEast && behindSouthWest));
}

-(BOOL)pointIsVisibleInScreenSpace:(BOOL)screenSpace size:(CGSize)size coordinate:(CLLocationCoordinate2D)coordinate
{
    CGPoint screenPointNorthWest, screenPointNorthEast, screenPointSouthWest, screenPointSouthEast;
    BOOL behind;
    
    CGPoint screenPoint = [self screenPointForCoordinate:coordinate behind:&behind];
    
    if (!behind)
    {
        if (screenSpace)
        {
            if (screenPoint.x < self.bounds.size.width / 2)
            {
                screenPoint.x += size.width / 2;
            }
            else
            {
                screenPoint.x -= size.width / 2;
            }
            if (screenPoint.y < self.bounds.size.height / 2)
            {
                screenPoint.y += size.height / 2;
            }
            else
            {
                screenPoint.y -= size.height / 2;
            }
            return CGRectContainsPoint(self.bounds, screenPoint);
        }
        else
        {
            CLLocationCoordinate2D origin    = coordinate;
            CLLocationCoordinate2D west      = [PMCartography locationAtDistance:size.width  / 2 fromOrigin:origin toBearing:RADIANS(270)];
            CLLocationCoordinate2D northWest = [PMCartography locationAtDistance:size.height / 2 fromOrigin:west   toBearing:RADIANS(  0)];
            CLLocationCoordinate2D southWest = [PMCartography locationAtDistance:size.height / 2 fromOrigin:west   toBearing:RADIANS(180)];
            
            CLLocationCoordinate2D east      = [PMCartography locationAtDistance:size.width  / 2 fromOrigin:origin toBearing:RADIANS( 90)];
            CLLocationCoordinate2D northEast = [PMCartography locationAtDistance:size.height / 2 fromOrigin:east   toBearing:RADIANS(  0)];
            CLLocationCoordinate2D southEast = [PMCartography locationAtDistance:size.height / 2 fromOrigin:east   toBearing:RADIANS(180)];
            
            screenPointNorthWest = [self screenPointForCoordinate:northWest];
            screenPointNorthEast = [self screenPointForCoordinate:northEast];
            screenPointSouthWest = [self screenPointForCoordinate:southWest];
            screenPointSouthEast = [self screenPointForCoordinate:southEast];
            
            //                    _helper1.transform = CGAffineTransformMakeTranslation(screenPointNorthWest.x, screenPointNorthWest.y);
            //                    _helper2.transform = CGAffineTransformMakeTranslation(screenPointNorthEast.x, screenPointNorthEast.y);
            //                    _helper3.transform = CGAffineTransformMakeTranslation(screenPointSouthEast.x, screenPointSouthEast.y);
            //                    _helper4.transform = CGAffineTransformMakeTranslation(screenPointSouthWest.x, screenPointSouthWest.y);
            
            return (CGRectContainsPoint(self.bounds, screenPointNorthWest) ||
                    CGRectContainsPoint(self.bounds, screenPointNorthEast) ||
                    CGRectContainsPoint(self.bounds, screenPointSouthEast) ||
                    CGRectContainsPoint(self.bounds, screenPointSouthWest));
            
        }
    }
    return NO;
}

-(void)reloadTiles
{
    self.lastZoom = 0;
    [[PMTileManager sharedManager] clearTiles];
}

-(void)reloadAnimatedLines
{
    [self.animatedLinesManager reload];
}

@end
