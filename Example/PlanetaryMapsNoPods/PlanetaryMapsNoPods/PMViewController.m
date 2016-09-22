//
//  PMViewController.m
//  PlanetaryMaps
//
//  Created by Seppo Pietarinen on 06/28/2016.
//  Copyright (c) 2016 Seppo Pietarinen. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "PMViewController.h"
#import "PMPlanetaryView.h"

#import "PMTileManager.h"

#import "PMCartography.h"

#import "YYImage/YYImage.h"

@interface PMViewController() <CLLocationManagerDelegate, PMPlanetaryViewDelegate, PMTileDataSource, PMTileDelegate, PMPolygonDataSource, PMPolygonDelegate, PMMarkerDataSource, PMMarkerDelegate>

@property (weak, nonatomic) IBOutlet PMPlanetaryView *planetaryView;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) CLLocationDegrees track;

@property (nonatomic, assign) BOOL receivedLocation;

@end

@implementation PMViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.planetaryView.planetaryViewDelegate = self;
    self.planetaryView.tileDataSource = self;
    self.planetaryView.tileDelegate = self;
    self.planetaryView.polygonDataSource = self;
    self.planetaryView.polygonDelegate = self;
    self.planetaryView.markerDataSource = self;
    self.planetaryView.markerDelegate = self;
    
    self.planetaryView.minimumDistance = 0.001;
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusRestricted:
            break;
            
        case kCLAuthorizationStatusDenied:
            break;
        
        default:
            self.locationManager = [[CLLocationManager alloc]init];
            self.locationManager.delegate = self;
            [self.locationManager requestWhenInUseAuthorization];
            if ([CLLocationManager locationServicesEnabled])
            {
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
                [self.locationManager startUpdatingLocation];
                [self.locationManager startUpdatingHeading];
            }
            break;
    }
}

-(void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    _coordinate = coordinate;
    ((UILabel*)self.labels[0]).text = [NSString stringWithFormat:@"%.2f %.2f", coordinate.latitude, coordinate.longitude];
    
    if (!self.receivedLocation)
    {
        self.receivedLocation = YES;
        [self.planetaryView reloadPolygons];
    }
}

-(void)setTrack:(CLLocationDegrees)track
{
    _track = track;
    ((UILabel*)self.labels[1]).text = [NSString stringWithFormat:@"%.0f°", track];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    self.coordinate = ((CLLocation*)locations.firstObject).coordinate;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    self.track = newHeading.trueHeading;
}

#pragma mark PMPlanetaryViewDelegate

-(void)tilesChangedForPlanetaryView:(PMPlanetaryView *)view
{
    ((UILabel*)self.labels[2]).text = [NSString stringWithFormat:@"%lu/%lu", [PMTileManager sharedManager].tiles.count, [PMTileManager sharedManager].tileCache.count];
}

-(void)planetaryView:(PMPlanetaryView *)view isAboveTileAtZoom:(NSUInteger)zoom x:(NSUInteger)x y:(NSUInteger)y
{
    ((UILabel*)self.labels[3]).text = [NSString stringWithFormat:@"%lu: %lu,%lu", (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
}

#pragma mark PMTileDataSource

-(NSUInteger)numberOfTileLayersInPlanetaryView:(PMPlanetaryView *)view
{
    return 2;
}

-(NSURL *)planetaryView:(PMPlanetaryView *)view urlForTileLayer:(NSUInteger)layer withZoom:(NSUInteger)zoom atX:(NSUInteger)x andY:(NSUInteger)y
{
    switch (layer)
    {
        case 0:
        {
            NSString *baseURL = @"https://dl.dropboxusercontent.com/u/6367136/charts/sec/%lu/%lu/%lu.webp";
            return [NSURL URLWithString:[NSString stringWithFormat:baseURL, (unsigned long)zoom, (unsigned long)x, (unsigned long)y]];
        }
         
        case 1:
        {
            NSString *baseURL = @"https://dl.dropboxusercontent.com/u/6367136/charts/tac/%lu/%lu/%lu.webp";
            return [NSURL URLWithString:[NSString stringWithFormat:baseURL, (unsigned long)zoom, (unsigned long)x, (unsigned long)y]];
        }
            
        default:
            break;
    }
    
    return nil;
}

-(UIImage *)planetaryView:(PMPlanetaryView *)view imageFromData:(NSData *)data
{
    return [YYImage imageWithData:data];
}

#pragma mark PMTileDelegate

//-(NSInteger)planetaryView:(PMPlanetaryView *)view segmentsPerSideForTileLayer:(NSUInteger)layer
//{
//    return 10;
//}

#pragma mark PMPolygonDataSource

-(NSInteger)planetaryView:(PMPlanetaryView *)view numberOfPolygonsInSet:(NSInteger)set
{
    return self.receivedLocation ? 1 : 0;
}

-(NSArray<CLLocation *> *)planetaryView:(PMPlanetaryView *)view coordinatesForPolygonAtIndex:(NSInteger)index inSet:(NSInteger)set
{
    return @[[[CLLocation alloc]initWithLatitude:37.6213 longitude:-122.3790], [[CLLocation alloc]initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude]];
}

#pragma mark PMPolygonDelegate

-(BOOL)planetaryView:(PMPlanetaryView *)view useScreenSpaceForPolygonsInSet:(NSInteger)set
{
    return YES;
}

-(CGFloat)planetaryView:(PMPlanetaryView *)view widthForPolygonOutlinesInSet:(NSInteger)set
{
    return 20;
}

-(UIColor *)planetaryView:(PMPlanetaryView *)view fillColorForPolygonOutlinesInSet:(NSInteger)set
{
    return [[UIColor magentaColor] colorWithAlphaComponent:0.5];
}

-(CGFloat)planetaryView:(PMPlanetaryView *)view minimumDistanceForPolygonsInSet:(NSInteger)set
{
    return 3;
}

-(BOOL)planetaryView:(PMPlanetaryView *)view closePolygonAtIndex:(NSInteger)index inSet:(NSInteger)set
{
    return YES;
}

-(NSUInteger)planetaryView:(PMPlanetaryView *)view segmentsPerSideForPolygonAtIndex:(NSInteger)index inSet:(NSInteger)set
{
    return 10;
}

#pragma mark PMMarkerDataSource

-(NSInteger)numberOfMarkerSetsInPlanetaryView:(PMPlanetaryView *)view
{
    return 2;
}

-(NSInteger)planetaryView:(PMPlanetaryView *)view numberOfMarkersInSet:(NSInteger)set
{
    return 1;
}

-(CLLocationCoordinate2D)planetaryView:(PMPlanetaryView *)view coordinateForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set
{
    if (set == 0)
        return self.coordinate;
    else
        return CLLocationCoordinate2DMake(37.6213, -122.3790);
}

#pragma mark PMMarkerDelegate

-(CGSize)planetaryView:(PMPlanetaryView *)view sizeForMarkersInSet:(NSInteger)set
{
    return CGSizeMake(50, 50);
}

-(UIImage *)planetaryView:(PMPlanetaryView *)view imageForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set
{
    // Icon made by Freepik (http://www.freepik.com) from www.flaticon.com
    return [UIImage imageNamed:@"aeroplane.png"];
}

-(CGFloat)planetaryView:(PMPlanetaryView *)view minimumDistanceForMarkersInSet:(NSInteger)set
{
    return 3;
}

-(BOOL)planetaryView:(PMPlanetaryView *)view useScreenSpaceForMarkersInSet:(NSInteger)set
{
    return YES;
}

-(CLLocationDegrees)planetaryView:(PMPlanetaryView *)view headingForMarkerAtIndex:(NSInteger)index inSet:(NSInteger)set
{
    if (set == 0)
        return self.track;
    else
        return 0;
}

-(void)planetaryView:(PMPlanetaryView *)view didTapMarkersAtIndices:(NSArray *)indices inSets:(NSArray *)sets
{
    NSLog(@"Tapped marker %d", [indices.firstObject intValue]);
}

@end