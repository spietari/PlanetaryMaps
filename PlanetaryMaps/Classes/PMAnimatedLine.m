#import "PMAnimatedLine.h"

#import <CoreLocation/CoreLocation.h>

@interface PMAnimatedLine()
@property (nonatomic, strong) NSMutableArray* points;
@property (nonatomic, assign) NSInteger startFrame;

@end

@implementation PMAnimatedLine

-(instancetype)initWithScreenPoints:(NSArray*)points
{
    if (self = [super init])
    {
        self.points = points;
        self.startFrame = arc4random() % self.points.count;
    }
    return self;
}

-(void)renderFrame:(NSInteger)frame toContext:(CGContextRef)context withScreenSize:(CGSize)screenSize
{
    NSInteger index = self.startFrame + frame;
    index %= self.points.count - 1;
    NSValue* value = self.points[index];
    CGPoint point = [value CGPointValue];
    
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextFillRect(context, CGRectMake(point.x - 1, point.y - 1, 1, 1));
    
//    for (NSInteger i = 0; i < self.points.count - 1; i++)
//    {
//        CGContextBeginPath(context);
//        
//        NSInteger index = self.startFrame + i + frame;
//        
//        index %= self.points.count - 1;
//        
//        NSValue* value = self.points[index];
//        CGPoint point = [value CGPointValue];
//        
//        NSValue* nextValue = self.points[index + 1];
//        CGPoint nextPoint = [nextValue CGPointValue];
//        
//        CGContextMoveToPoint(context, point.x, point.y);
//        CGContextAddLineToPoint(context, nextPoint.x, nextPoint.y);
//        
//        CGFloat alpha = i / (CGFloat)(self.points.count - 1);
//        
//        CGContextSetStrokeColorWithColor(context, [[UIColor yellowColor] colorWithAlphaComponent:alpha].CGColor);
//        CGContextSetLineWidth(context, 1);
//        CGContextStrokePath(context);
//    }
}

@end
