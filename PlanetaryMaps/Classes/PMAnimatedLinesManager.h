
#import <Foundation/Foundation.h>

#import "PMPlanetaryView.h"
#import "PMAnimatedLine.h"

@interface PMAnimatedLinesManager : NSObject

+ (PMAnimatedLinesManager *) sharedManager;

@property (nonatomic, weak) id<PMAnimatedLinesDataSource> dataSource;
@property (nonatomic, weak) id<PMAnimatedLinesDelegate> delegate;
@property (nonatomic, weak) PMPlanetaryView *planetaryView;

-(void)reload;
-(void)render;
-(void)clear;

@end
