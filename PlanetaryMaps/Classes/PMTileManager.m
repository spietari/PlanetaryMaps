
#import "PMTileManager.h"

// This is quite a big cache. Memory is consumed.
const NSInteger CacheSize = 50;
const NSInteger MaxTiles = 50;
const NSInteger MaxTilesInDownloadQueue = 75;

@interface PMTileManager()
{
    BOOL killDownloadThread;
}

@property (nonatomic, assign) NSUInteger currentZoom;
@property (nonatomic, assign) CLLocationCoordinate2D currentCoordinate;

@property (nonatomic, strong) NSOperationQueue* downloadQueue;
@property (nonatomic, strong) NSMutableArray* downloadStack;

@end

@implementation PMTileManager

+ (PMTileManager *) sharedManager
{
    static PMTileManager *_sharedInstance = nil;
    
    @synchronized (self)
    {
        if (_sharedInstance == nil)
        {
            _sharedInstance = [[self alloc] init];
        }
    }
    
    return _sharedInstance;
}

-(id)init
{
    if (self = [super init])
    {
        killDownloadThread = NO;
        
        self.tiles = [[NSMutableArray alloc]init];
        self.tileCache = [[NSMutableArray alloc]init];
        
        self.downloadQueue = [[NSOperationQueue alloc]init];
        self.downloadQueue.maxConcurrentOperationCount = 4;
        self.downloadQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        
        self.downloadStack = [[NSMutableArray alloc]init];
        
        __block PMTileManager* wself = self;
        
        const NSInteger MaxSimultaneousDownloads = 4;
        __block NSInteger simultaneousDownloads = 0;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            while (!killDownloadThread)
            {
                if (wself.downloadStack.count > 0 && simultaneousDownloads < MaxSimultaneousDownloads)
                {
                    @synchronized(wself.downloadStack)
                    {
                        __block PMTile* tile = nil;
                        for (PMTile* t in wself.downloadStack)
                        {
                            if (t.downloading == NO)
                            {
                                tile = t;
                                break;
                            }
                        }
                        
                        if (tile == nil)
                        {
                            continue;
                        }
                        
                        tile.downloading = YES;
                        
                        NSURLRequest* request = [[NSURLRequest alloc]initWithURL:tile.url];
                        
                        __block PMTileManager* wself = self;
                        
                        simultaneousDownloads++;
                        
                        [NSURLConnection sendAsynchronousRequest:request queue:self.downloadQueue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                            
                            simultaneousDownloads--;
                            @synchronized(wself.downloadStack)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [wself removeQueued:tile];
                                });
                            }
                            if ([httpResponse statusCode] != 200 || connectionError || !data) {
                                return;
                            }
                            [wself receivedData:data forTile: tile];
                        }];
                    }
                }
                [NSThread sleepForTimeInterval:0.1];
            }
        });
    }
    return self;
}

-(void)dealloc
{
    killDownloadThread = YES;
}

-(void)setCurrentZoom:(NSUInteger)zoom andCoordinate:(CLLocationCoordinate2D)coordinate
{
    self.currentZoom = zoom;
    self.currentCoordinate = coordinate;
    
    [self optimizeDisplayOrderForTiles: self.tiles];
}

-(void)addToTopOfQueue:(NSObject*)object
{
    @synchronized (self.downloadStack)
    {
        [self.downloadStack insertObject:object atIndex:0];
        for (NSInteger i = self.downloadStack.count - 1; i >= MaxTilesInDownloadQueue; i--)
        {
            [self.downloadStack removeObjectAtIndex:i];
        }
    }
}

-(BOOL)isQueued:(NSObject*)object
{
    for (PMTile* tile in self.downloadStack)
    {
        if ([tile isEqualToTile:object])
        {
            return YES;
        }
    }
    return NO;
}

-(void)removeQueued:(NSObject*)object
{
    @synchronized (self.downloadStack)
    {
        NSArray* itemToRemove = nil;
        for (PMTile* tile in self.downloadStack)
        {
            if ([tile isEqualToTile:object])
            {
                itemToRemove = tile;
            }
        }
        if (itemToRemove)
        {
            [self.downloadStack removeObject:itemToRemove];
        }
    }
}

// When adding a tile check if it's already loaded or in the cache and
// use from there.
-(void)addNewTiles:(NSArray*)newTiles layerCount:(NSUInteger)layerCount
{
    for (NSArray* coords in newTiles)
    {
        for (NSUInteger i = 0; i < layerCount; i++)
        {
            NSUInteger zoom = [coords[0]intValue];
            NSInteger x = [coords[1]intValue];
            NSInteger y = [coords[2]intValue];
            
            NSUInteger tilesPerDimension = [PMTileTools tilesForZoom:zoom];
            NSUInteger horTiles = tilesPerDimension;
            NSUInteger verTiles = tilesPerDimension / 2;
            if (verTiles == 0) verTiles = 1;
            
            while (x < 0) x += horTiles;
            while (y < 0) y += verTiles;
            
            x %= horTiles;
            y %= verTiles;
            
            if (x >= 0 && x < horTiles && y >= 0 && y < verTiles)
            {
                
            }
            else
            {
                continue;
            }
            
            PMTile *existingTile = [self findTileFromArray:self.tiles forZoom:zoom X:x Y:y layer:i];
            if (existingTile)
            {
                [self.tiles removeObject:existingTile];
                [self insertTile:existingTile toTiles:self.tiles];
                continue;
            }
            
            PMTile *cachedTile = [self findTileFromArray:self.tileCache forZoom:zoom X:x Y:y layer:i];
            if (cachedTile)
            {
                [self insertTile:cachedTile toTiles:self.tiles];
                continue;
            }
            
            NSURL *tileUrl = [self.tileDataSource planetaryView:self.planetaryView urlForTileLayer:i withZoom:zoom atX:x andY:y];
            
            if (!tileUrl) continue;

            if ([tileUrl.scheme hasPrefix:@"http"])
            {
                PMTile *tile = [[PMTile alloc] initWithZoom:zoom X:x Y:y layer:i planetSizeMultiplier:self.planetSizeMultiplier];
                if ([self isQueued:tile])
                {
                    continue;
                }
                tile.url = tileUrl;
                [self addToTopOfQueue:tile];
            }
            else
            {
                NSData* data = [NSData dataWithContentsOfURL:tileUrl];
                PMTile *tile = [[PMTile alloc] initWithZoom:zoom X:x Y:y layer:i planetSizeMultiplier:self.planetSizeMultiplier];
                if (!data) continue;
                [self receivedData:data forTile:tile];
            }
        }
    }
    @synchronized (self.downloadStack)
    {
        [self optimizeDownloadOrderForTiles:self.downloadStack];
    }
}

-(void)receivedData:(NSData*)data forTile:(PMTile*)tile
{
    if (tile.zoom > self.currentZoom)
    {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        __block UIImage *image;
        if ([self.tileDataSource respondsToSelector:@selector(planetaryView:imageFromData:)])
        {
            image = [self.tileDataSource planetaryView:self.planetaryView imageFromData:data];
        }
        else
        {
            image = [UIImage imageWithData:data];
        }
            
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.tileDelegate respondsToSelector:@selector(planetaryView:segmentsPerSideForTileLayer:)])
            {
                tile.segmentsPerSide = [self.tileDelegate planetaryView:self.planetaryView segmentsPerSideForTileLayer:tile.layer];
            }
            [tile setImage:image];
            [self insertTile:tile toTiles:self.tiles];
            [self.tileCache insertObject:tile atIndex:0];
            for (NSInteger i = self.tileCache.count - 1; i >= CacheSize; i--)
            {
                [self.tileCache removeObjectAtIndex:i];
            }
        });
    });
}

-(void)insertTile:(PMTile*)tile toTiles:(NSMutableArray*)tiles
{
    [tiles insertObject:tile atIndex:0];
    [self optimizeDisplayOrderForTiles:tiles];
    if ([self.planetaryView.planetaryViewDelegate respondsToSelector:@selector(tilesChangedForPlanetaryView:)])
    {
        [self.planetaryView.planetaryViewDelegate tilesChangedForPlanetaryView:self.planetaryView];
    }
}

-(CGPoint)errorsForTile:(PMTile*)tile
{
    CGFloat deltaZoom = fabs(self.currentZoom - tile.zoom);
    CGPoint currentPoint = [PMTileTools tileCoordinateWithZoom:tile.zoom andCoordinate:self.currentCoordinate];
    NSUInteger currentX = (NSUInteger)currentPoint.x;
    NSUInteger currentY = (NSUInteger)currentPoint.y;
    
    NSUInteger tilesPerDimension = [PMTileTools tilesForZoom:tile.zoom];
    NSUInteger horTiles = tilesPerDimension;
    NSUInteger verTiles = tilesPerDimension / 2;
    
    CGFloat deltaX = fmin(fabs(tile.x - currentX), horTiles - fabs(tile.x - currentX) - 1);
    CGFloat deltaY = fmin(fabs(tile.y - currentY), verTiles - fabs(tile.y - currentY) - 1);
    CGFloat deltaLocation = deltaX + deltaY;
    
    return CGPointMake(deltaZoom, deltaLocation);
}

-(CGFloat)errorForDownloadingTile:(PMTile*)tile
{
    CGPoint errors = [self errorsForTile:tile];
    return errors.x + errors.y;
}

-(void)optimizeDownloadOrderForTiles:(NSMutableArray*)tiles
{
    [tiles sortUsingComparator:^NSComparisonResult(PMTile* tile1, PMTile* tile2) {
        
//        if (tile1.layer != tile2.layer)
//        {
//            return tile1.layer < tile2.layer ? NSOrderedAscending : NSOrderedDescending;
//        }
        
        CGFloat error1 = [self errorForDownloadingTile:tile1];
        CGFloat error2 = [self errorForDownloadingTile:tile2];
        return error1 < error2 ? NSOrderedAscending : NSOrderedDescending;
    }];

    // Never download anything that's on a higher zoom level than we are currently at.
    for (NSInteger i = tiles.count - 1; i >= 0; i--)
    {
        PMTile* tile = (PMTile*)tiles[i];
        if (tile.zoom > self.currentZoom)
        {
            [tiles removeObjectAtIndex:i];
        }
    }

    for (NSInteger i = tiles.count - 1; i >= MaxTilesInDownloadQueue; i--)
    {
        [tiles removeObjectAtIndex:i];
    }
}

-(CGFloat)errorForDisplayingTile:(PMTile*)tile
{
    // In calculating error for displaying a tile we pay more attention to lateral distance from the
    // current coordinate. 
    CGPoint errors = [self errorsForTile:tile];
    return (errors.x + 1) * errors.y;
}

-(void)optimizeDisplayOrderForTiles:(NSMutableArray*)tiles
{
    for (NSInteger i = 0; i < tiles.count; i++)
    {
        CGFloat error = [self errorForDisplayingTile:tiles[i]];
        if (error > 2)
        {
            [tiles removeObjectAtIndex:i];
        }
    }
    
    [tiles sortUsingComparator:^NSComparisonResult(PMTile* tile1, PMTile* tile2) {
        if (tile1.layer != tile2.layer)
        {
            return tile1.layer < tile2.layer ? NSOrderedAscending : NSOrderedDescending;
        }
        if (tile1.zoom != tile2.zoom)
        {
            return tile1.zoom < tile2.zoom ? NSOrderedAscending : NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    while (tiles.count > MaxTiles)
    {
        [tiles removeObjectAtIndex:0];
    }
    
    for (NSInteger i = 0; i < tiles.count; i++)
    {
        PMTile* tile = tiles[i];
        if (tile.zoom > self.currentZoom)
        {
            [tiles removeObjectAtIndex:i];
        }
    }
}

-(void)clearTiles
{
//    [self.tiles removeAllObjects];
    [self.tileCache removeAllObjects];
}

-(PMTile*)findTileFromArray:(NSArray*)tiles forZoom:(NSUInteger)zoom X:(NSUInteger)x Y:(NSUInteger)y layer:(NSUInteger)layer
{
    for (PMTile *tile in tiles)
    {
        if (tile.zoom == zoom && tile.x == x && tile.y == y && tile.layer == layer)
        {
            return tile;
        }
    }
    return nil;
}

@end
