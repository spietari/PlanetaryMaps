#import <OpenGLES/ES2/glext.h>

#import "PMAnimatedLinesManager.h"

#import "Program/PMPlanetaryViewProgram.h"
#import "PMCartography.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface PMAnimatedLinesManager()
{
    UInt8* animatedLinesDataImage;
    CGSize animatedLinesDataImageSize;

    GLuint animatedLinesFrameBuffer;
    GLuint animatedLinesRenderBuffer;
    GLuint animatedLinesRenderToTexture;
    
    NSUInteger vertexCount;
    GLfloat* vertices;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}

@property (nonatomic, strong) PMColorProgram *animatedLineProgram;
@property (nonatomic, strong) PMPlanetaryViewProgram *hudProgram;

@property (nonatomic, strong) NSMutableArray<PMAnimatedLine*> *animatedLines;
@property (nonatomic, assign) NSInteger maxAnimatedLines;
@property (nonatomic, strong) dispatch_queue_t animatedLinesQueue;

@end

@implementation PMAnimatedLinesManager

+ (PMAnimatedLinesManager *) sharedManager
{
    static PMAnimatedLinesManager *_sharedInstance = nil;
    @synchronized (self)
    {
        if (_sharedInstance == nil)
        {
            _sharedInstance = [[self alloc] init];
        }
    }
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self startAnimatedLinesEmitter];
        self.animatedLinesQueue = dispatch_queue_create("PlanetaryMapsAnimatedLines", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

-(void)dealloc
{
    free(animatedLinesDataImage);
}

-(void)reload
{
    if (!self.dataSource) return;
    
    if (!animatedLinesDataImage)
    {
        self.animatedLineProgram = [[PMColorProgram alloc]initWithName:@"AnimatedLineShader"];
        self.hudProgram = [[PMPlanetaryViewProgram alloc]initWithName:@"HUDShader"];
        [self makeParticle];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if ([self.dataSource respondsToSelector:@selector(numberOfAnimatedLinesInPlanetaryView:)] &&
            [self.dataSource respondsToSelector:@selector(animatedLineImageForPlanetaryView:)])
        {
            self.maxAnimatedLines = [self.dataSource numberOfAnimatedLinesInPlanetaryView: self];
            if (self.maxAnimatedLines == 0)
            {
                self.animatedLines = nil;
                return;
            }
            
            if (!animatedLinesDataImage)
            {
                UIImage* dataImage = [self.dataSource animatedLineImageForPlanetaryView:self];
                
                NSInteger dataWidth = dataImage.size.width;
                NSInteger dataHeight = dataImage.size.height;
                
                UIGraphicsBeginImageContext(dataImage.size);
                CGContextRef context = UIGraphicsGetCurrentContext();
                
                CGContextScaleCTM(context, 1, -1);
                CGContextTranslateCTM(context, 0, -dataImage.size.height);
                CGContextDrawImage(context, CGRectMake(0, 0, dataWidth, dataHeight), dataImage.CGImage);
                
                animatedLinesDataImage = calloc(dataImage.size.width * dataImage.size.height, 4 * sizeof(UInt8));
                
                UInt8 *data = (UInt8*)CGBitmapContextGetData(context);
                memcpy(animatedLinesDataImage, data, 4 * dataImage.size.width * dataImage.size.height * sizeof(UInt8));
                
                animatedLinesDataImageSize = dataImage.size;
                
                UIGraphicsEndImageContext();
                
                dispatch_barrier_async(self.animatedLinesQueue, ^{
                    _animatedLines = [[NSMutableArray alloc]init];
                });
            }
        }
    });
}

-(void)startAnimatedLinesEmitter
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        // TODO
        while (true)
        {
            if (!self.animatedLines)
            {
                continue;
            }
            
            NSInteger segments = 100;
            if ([self.delegate respondsToSelector:@selector(planetaryView:segmentsForAnimatedLinesInSet:)])
            {
                segments = [self.delegate planetaryView:self.planetaryView segmentsForAnimatedLinesInSet:0];
            }
            
            CGFloat length = 1;
            if ([self.delegate respondsToSelector:@selector(planetaryView:lengthForAnimatedLinesInSet:)])
            {
                length = [self.delegate planetaryView:self.planetaryView lengthForAnimatedLinesInSet:0];
            }
            
            for (NSInteger i = self.animatedLines.count; i < self.maxAnimatedLines; i++)
            {
                CGPoint point = CGPointMake(-20 + arc4random() % (NSInteger)(self.planetaryView.bounds.size.width  + 40),
                                            -20 + arc4random() % (NSInteger)(self.planetaryView.bounds.size.height + 40));
                
                BOOL error;
                CLLocationCoordinate2D coordinate = [self.planetaryView coordinateForScreenPoint:point error:&error];
                if (error)
                {
                    continue;
                }
                
                NSInteger dataWidth  = (NSInteger)animatedLinesDataImageSize.width;
                NSInteger dataHeight = (NSInteger)animatedLinesDataImageSize.height;
                
                NSMutableArray* locations = [[NSMutableArray alloc]init];
                CGFloat maxSpeed = 0, speed, heading;
                
                for (NSInteger j = 0; j < segments; j++)
                {
                    [locations addObject:@[@(coordinate.latitude), @(coordinate.longitude)]];
                    
                    NSInteger x = dataWidth  * (coordinate.longitude + 180) / 360;
                    NSInteger y = dataHeight * (1 - (coordinate.latitude + 90) / 180);
                    
                    CGFloat u = animatedLinesDataImage[4 * (y * dataWidth + x) + 1] - 127;
                    CGFloat v = animatedLinesDataImage[4 * (y * dataWidth + x) + 2] - 127;
                    
                    speed = sqrtf(u * u + v * v);
                    if (speed > 40) speed = 40;
                    if (speed > maxSpeed) maxSpeed = speed;
                    
                    heading = atan2(v, u);
                    
                    CGFloat delta = length * speed * 100000 * sqrt(self.planetaryView.distance) / segments;
                    
                    coordinate = [PMCartography locationAtDistance:delta fromOrigin:coordinate toBearing:heading];
                    BOOL behind;
                    point = [self.planetaryView screenPointForCoordinate:coordinate behind:&behind];
                    if (behind)
                    {
                        break;
                    }
                }
                [locations addObject:@[@(coordinate.latitude), @(coordinate.longitude)]];
                PMAnimatedLine* animatedLine = [[PMAnimatedLine alloc]initWithLocations:locations
                                                                andPlanetSizeMultiplier:self.planetaryView.planetSizeMultiplier
                                                                             andProgram:self.animatedLineProgram
                                                                         andVertexArray:self->_vertexArray
                                                                              andLength:length];
                animatedLine.maxSpeed = maxSpeed;
                
                dispatch_barrier_async(self.animatedLinesQueue, ^{
                    if (maxSpeed > 5)
                    {
                        [self.animatedLines addObject:animatedLine];
                    }
                });
            }
            [NSThread sleepForTimeInterval:0.1];
        }
    });
}

-(void)clear
{
    GLuint old_fbo;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &old_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, animatedLinesFrameBuffer);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
}

-(void)render
{
    if (!animatedLinesFrameBuffer)
    {
        glGenFramebuffers(1, &animatedLinesFrameBuffer);
        glGenTextures(1, &animatedLinesRenderToTexture);
        
        glBindTexture(GL_TEXTURE_2D, animatedLinesRenderToTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
        CGFloat screenScale = [UIScreen mainScreen].scale;
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, screenScale * self.planetaryView.bounds.size.width, screenScale * self.planetaryView.bounds.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        
        glBindFramebuffer(GL_FRAMEBUFFER, animatedLinesFrameBuffer);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, animatedLinesRenderToTexture, 0);
        
        glBindFramebuffer(GL_FRAMEBUFFER, animatedLinesFrameBuffer);
        
        GLenum status=glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE)
        {
            NSLog(@"Framebuffer is not complete");
        }
        
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
    
    dispatch_barrier_sync(self.animatedLinesQueue, ^{
        
        GLuint old_fbo;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &old_fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, animatedLinesFrameBuffer);
        
        GLint old_viewport[4];
        glGetIntegerv(GL_VIEWPORT, old_viewport);
        
        CGFloat screenScale = [UIScreen mainScreen].scale;
        glViewport(0, 0, screenScale * self.planetaryView.bounds.size.width, screenScale * self.planetaryView.bounds.size.height);
        
        NSMutableArray *toBeRemoved = [[NSMutableArray alloc]init];
        
        CGFloat scale = 1;
        if ([self.delegate respondsToSelector:@selector(planetaryView:scaleForAnimatedLinesInSet:)])
        {
            scale = [self.delegate planetaryView:self.planetaryView scaleForAnimatedLinesInSet:0];
        }
        
        GLKVector4 colorVector;
        if ([self.delegate respondsToSelector:@selector(planetaryView:colorForAnimatedLinesInSet:)])
        {
            UIColor *color = [self.delegate planetaryView:self.planetaryView colorForAnimatedLinesInSet:0];
            CGFloat red, green, blue, alpha;
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
            colorVector = GLKVector4Make(red, green, blue, alpha);
        }
        else
        {
            colorVector = GLKVector4Make(1, 1, 1, 1);
        }
        
        CGFloat animationSpeed = 1.0;
        if ([self.delegate respondsToSelector:@selector(planetaryView:speedForAnimatedLinesInSet:)])
        {
            animationSpeed = [self.delegate planetaryView:self.planetaryView speedForAnimatedLinesInSet:0];
        }
        
        for (PMAnimatedLine* animatedLine in self.animatedLines)
        {
            float f = (animatedLine.maxSpeed - 5) / 35;
            if (f > 1) f = 1;
            
            self.animatedLineProgram.color.value = GLKVector4Make(colorVector.x, (1 - f) * colorVector.y, (1 - f) * colorVector.z, colorVector.w);//0.5 + 0.5 * colorVector.w * f);
            
            BOOL alive = [animatedLine renderWithCoordinate:self.planetaryView.eye
                                                   distance:self.planetaryView.distance
                                                   viewSize:self.planetaryView.bounds.size
                                                   andScale:scale
                                                   andSpeed:animationSpeed];
            if (!alive)
            {
                [toBeRemoved addObject:animatedLine];
            }
        }
        
        [self.animatedLines removeObjectsInArray:toBeRemoved];
        
        [self renderDimmer];
        
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, old_fbo);
        glViewport(old_viewport[0], old_viewport[1], old_viewport[2], old_viewport[3]);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, animatedLinesRenderToTexture);

        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_GREATER);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4MakeOrtho(-0.5, 0.5, 0.5, -0.5, -1.0, 0.0);
        
        self.hudProgram.modelViewMatrix.value = modelViewProjectionMatrix;
        [self.hudProgram use];
        
        glBindVertexArrayOES(self.planetaryView->_vertexArray);
        glDrawArrays(GL_TRIANGLES, 0, 6);
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

-(void)renderDimmer
{
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4MakeOrtho(-0.5, 0.5, 0.5, -0.5, -1.0, 0.0);
    self.animatedLineProgram.modelViewMatrix.value = modelViewProjectionMatrix;
    
    CGFloat dimmer = 0.95;
    if ([self.delegate respondsToSelector:@selector(planetaryView:dimmerForAnimatedLinesInSet:)])
    {
        dimmer = [self.delegate planetaryView:self.planetaryView dimmerForAnimatedLinesInSet:0];
    }
    self.animatedLineProgram.color.value = GLKVector4Make(0, 0, 0, dimmer);
    [self.animatedLineProgram use];
    glEnable(GL_BLEND);
    glBlendFuncSeparate(GL_ZERO, GL_ONE, GL_DST_ALPHA, GL_ZERO);
    glBindVertexArrayOES(self.planetaryView->_vertexArray);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glBindTexture(GL_TEXTURE_2D, 0);
}

-(void)makeParticle
{
    [self makeVertices];
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, 3 * vertexCount * sizeof(GLfloat), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), BUFFER_OFFSET(0));
    
    glBindVertexArrayOES(0);
}

-(void)makeVertices
{
    vertexCount = 4;
    if (vertices)
    {
        free(vertices);
    }
    vertices = malloc(vertexCount * 3 * sizeof(GLfloat));
    
    GLfloat v[12] = {
        
        -1,  1, 0,
        -1, -1, 0,
         1,  1, 0,
         1, -1, 0,
    };

    memcpy(vertices, v, vertexCount * 3 * sizeof(GLfloat));
}


@end
