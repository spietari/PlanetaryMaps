
#import <GLKit/GLKit.h>

#import "PMTile.h"
#import "PMTileTools.h"

#import "PMPlanetaryView.h"

@interface PMTileManager : NSObject

+ (PMTileManager *) sharedManager;

-(void)setCurrentZoom:(NSUInteger)zoom andCoordinate:(CLLocationCoordinate2D)coordinate;
-(void)addNewTiles:(NSArray*)tiles layerCount:(NSUInteger)layerCount;
-(void)clearTiles;

@property (nonatomic, weak) EAGLSharegroup *shareGroup;

@property (nonatomic, strong) NSMutableArray *tiles;
@property (nonatomic, strong) NSMutableArray *tileCache;

@property (nonatomic, weak) EAGLContext *context;

@property (nonatomic, weak) id<PMTileDataSource> tileDataSource;
@property (nonatomic, weak) id<PMTileDelegate> tileDelegate;
@property (nonatomic, weak) PMPlanetaryView *planetaryView;

@property (nonatomic, assign) CGFloat planetSizeMultiplier;

@end
