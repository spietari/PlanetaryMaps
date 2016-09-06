
#import <GLKit/GLKit.h>

#import "PMMarker.h"

@interface PMTile : PMMarker

typedef UIImage* (^ConvertBlock)(NSData* data);

-(id)initWithZoom:(NSUInteger)zoom X:(NSUInteger)x Y:(NSUInteger)y layer:(NSUInteger)layer planetSizeMultiplier:(CGFloat)planetSizeMultiplier;
-(void)renderWithCoordinate:(CLLocationCoordinate2D)coordinate distance:(CGFloat)distance viewSize:(CGSize)viewSize;
-(BOOL)isEqualToTile:(PMTile*) tile;

@property (nonatomic, assign) NSUInteger zoom;
@property (nonatomic, assign) NSUInteger x;
@property (nonatomic, assign) NSUInteger y;
@property (nonatomic, assign) NSUInteger layer;

@property (nonatomic, assign) NSInteger segmentsPerSide;
@property (nonatomic, strong) NSURL* url;

@property (nonatomic, assign) BOOL downloading;

@end