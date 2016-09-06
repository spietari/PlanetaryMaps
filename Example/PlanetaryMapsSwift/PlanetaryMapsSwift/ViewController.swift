//
//  ViewController.swift
//  PlanetaryMapsSwift
//
//  Created by Seppo Pietarinen on 21/08/16.
//  Copyright © 2016 United Galactic. All rights reserved.
//

import UIKit
import CoreLocation

import PlanetaryMaps

class ViewController: UIViewController, PMTileDataSource, PMTileDelegate, PMMarkerDataSource, PMMarkerDelegate, PMPolygonDataSource, PMPolygonDelegate, PMPlanetaryViewDelegate {

    // This is to fool Xcode to display FPS debug gauge.
    private var context: EAGLContext?
    
    @IBOutlet var planetaryView: PMPlanetaryView!
    
    let apollo11 = CLLocation(latitude:  0.67409, longitude:  23.47298)
    let apollo12 = CLLocation(latitude: -3.01381, longitude: -23.41930)
    let apollo14 = CLLocation(latitude: -3.64544, longitude: -17.47139)
    let apollo15 = CLLocation(latitude: 26.13224, longitude:   3.63400)
    let apollo16 = CLLocation(latitude: -8.97341, longitude:  15.49859)
    let apollo17 = CLLocation(latitude: 20.18809, longitude:  30.77475)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        planetaryView.tileDataSource = self
        planetaryView.tileDelegate = self
        
        planetaryView.markerDataSource = self
        planetaryView.markerDelegate = self
        
        planetaryView.polygonDataSource = self
        planetaryView.polygonDelegate = self
        
        planetaryView.planetaryViewDelegate = self
        
        planetaryView.lookAtCoordinate(apollo11.coordinate)
        planetaryView.setLookDistance(2)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        planetaryView.didReceiveMemoryWarning()
    }

    // MARK: Tile Data Source
    
    func planetaryView(view: PMPlanetaryView, urlForTileLayer layer: UInt, withZoom zoom: UInt, atX x: UInt, andY y: UInt) -> NSURL! {
        return NSURL(string: "https://dl.dropboxusercontent.com/u/6367136/charts/Moon/Tiles/\(zoom)/\(x)/\(y).png")
    }
    
    // MARK: Tile Delegate
    
    func planetaryView(view: PMPlanetaryView, segmentsPerSideForTileLayer layer: UInt) -> Int {
        return 20
    }
    
    // MARK: Marker Data Source
    
    func numberOfMarkerSetsInPlanetaryView(view: PMPlanetaryView!) -> Int {
        return 2
    }
    
    func planetaryView(view: PMPlanetaryView, numberOfMarkersInSet set: Int) -> Int {
        return 3
    }
    
    func planetaryView(view: PMPlanetaryView, imageForMarkerAtIndex index: Int, inSet set: Int) -> UIImage! {
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(50, 50), false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextClearRect(context, CGRectMake(0, 0, 50, 50))
        
        CGContextSetLineWidth(context, 2.0);
        CGContextSetRGBStrokeColor(context, set == 0 ? 1.0 : 0.0, set == 0 ? 0.0 : 1.0, 1.0, 1.0)
        CGContextSetRGBFillColor  (context, set == 0 ? 1.0 : 0.0, set == 0 ? 0.0 : 1.0, 1.0, 0.5)
        
        CGContextFillEllipseInRect(context, CGRectMake(2, 2, 46, 46))
        CGContextStrokeEllipseInRect(context, CGRectMake(2, 2, 46, 46))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func planetaryView(view: PMPlanetaryView, coordinateForMarkerAtIndex index: Int, inSet set: Int) -> CLLocationCoordinate2D {
        if set == 0 {
            switch index {
            case 0:
                return apollo11.coordinate
            case 1:
                return apollo12.coordinate
            case 2:
                return apollo14.coordinate
            default:
                return CLLocationCoordinate2DMake(0, 0)
            }
        } else {
            switch index {
            case 0:
                return apollo15.coordinate
            case 1:
                return apollo16.coordinate
            case 2:
                return apollo17.coordinate
            default:
                return CLLocationCoordinate2DMake(0, 0)
            }
        }
    }
    
    // MARK: Marker Delegate
    
    func planetaryView(view: PMPlanetaryView, sizeForMarkersInSet set: Int) -> CGSize {
        return set == 0 ?  CGSizeMake(50, 50) : CGSizeMake(500000, 500000)
    }
    
    func planetaryView(view: PMPlanetaryView, useScreenSpaceForMarkersInSet set: Int) -> Bool {
        return set == 0
    }
    
    func planetaryView(view: PMPlanetaryView, minimumDistanceForMarkersInSet set: Int) -> CGFloat {
        return 3
    }
    
    // MARK: Polygon Data Source
    
    func numberOfPolygonSetsInPlanetaryView(view: PMPlanetaryView!) -> Int {
        return 2
    }
    
    func planetaryView(view: PMPlanetaryView, numberOfPolygonsInSet set: Int) -> Int {
        return 1
    }
    
    func planetaryView(view: PMPlanetaryView, coordinatesForPolygonAtIndex index: Int, inSet set: Int) -> [CLLocation]! {
        if (set == 0)
        {
            return [apollo11, apollo12, apollo14]
        }
        else
        {
            return [apollo15, apollo16, apollo17]
        }
    }
    
    func planetaryView(view: PMPlanetaryView, closePolygonAtIndex index: Int, inSet set: Int) -> Bool {
        return true
    }
    
    // MARK: Polygon Delegate
    
    func planetaryView(view: PMPlanetaryView, useScreenSpaceForPolygonsInSet set: Int) -> Bool {
        return set == 0
    }
    
    func planetaryView(view: PMPlanetaryView, widthForPolygonOutlinesInSet set: Int) -> CGFloat {
        return set == 0 ? 15 : 100000
    }
    
    func planetaryView(view: PMPlanetaryView, fillColorForPolygonOutlinesInSet set: Int) -> UIColor! {
        return set == 0 ? UIColor.whiteColor().colorWithAlphaComponent(1.0) : UIColor.yellowColor().colorWithAlphaComponent(1.0)
    }

    func planetaryView(view: PMPlanetaryView, minimumDistanceForPolygonsInSet set: Int) -> CGFloat {
        return 3
    }

    func planetaryView(view: PMPlanetaryView, segmentsPerSideForPolygonAtIndex index: Int, inSet set: Int) -> UInt {
        return 10
    }
    
    // MARK: Planetary View Delegate
    
    func planetaryView(view: PMPlanetaryView, movedToDistance distance: CGFloat) {
        if distance > 1 {
            view.lineSpacingInDegrees = 10
        } else {
            view.lineSpacingInDegrees = 5
        }
    }
    
}

