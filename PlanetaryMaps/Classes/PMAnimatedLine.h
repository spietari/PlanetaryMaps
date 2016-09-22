#import <Foundation/Foundation.h>

@interface PMAnimatedLine : NSObject

-(instancetype)initWithScreenPoints:(NSArray*)points;
-(void)renderFrame:(NSInteger)frame toContext:(CGContextRef)context withScreenSize:(CGSize)screenSize;

@end
