
#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>
#import <CoreLocation/CoreLocation.h>

#import "PMMarkerProgram.h"

@interface PMMarker : NSObject
{
    NSUInteger vertexCount;
    GLfloat* vertices;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}

-(instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate size:(CGSize)size planetSizeMultiplier:(CGFloat)planetSizeMultiplier;
-(void)renderWithCoordinate:(CLLocationCoordinate2D)coordinate distance:(CGFloat)distance viewSize:(CGSize)viewSize;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, assign) GLint texture;
@property (nonatomic, assign) CLLocationDegrees bearing;

@property (nonatomic, strong) PMMarkerProgram *program;
@property (nonatomic, assign) CGFloat planetSizeMultiplier;

-(void)makeVertices;

+(GLint)textureFromImage:(UIImage*)image;

@end

@interface PMMarkerSet : NSObject

-(void)addMarker:(PMMarker*)marker forKey:(NSObject<NSCopying>*)key;
-(void)invalidate;

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, readonly) NSDictionary *markers;
@property (nonatomic, strong) NSMutableDictionary *visibleMarkers;

@property (nonatomic, assign) CLLocationCoordinate2D boundNorthWest;
@property (nonatomic, assign) CLLocationCoordinate2D boundNorthEast;
@property (nonatomic, assign) CLLocationCoordinate2D boundSouthEast;
@property (nonatomic, assign) CLLocationCoordinate2D boundSouthWest;

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) BOOL useScreenSpace;

@end
