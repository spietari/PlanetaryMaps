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
import YYImage

class ViewController: UIViewController, PMTileDataSource, PMTileDelegate, PMMarkerDataSource, PMMarkerDelegate, PMPolygonDataSource, PMPolygonDelegate, PMPlanetaryViewDelegate, PMAnimatedLinesDataSource, PMAnimatedLinesDelegate {

    // This is to fool Xcode to display FPS debug gauge.
    private var context: EAGLContext?
    
    @IBOutlet var planetaryView: PMPlanetaryView!
    
    let apollo11 = CLLocation(latitude:  0.67409, longitude:  23.47298)
    let apollo12 = CLLocation(latitude: -3.01381, longitude: -23.41930)
    let apollo14 = CLLocation(latitude: -3.64544, longitude: -17.47139)
    let apollo15 = CLLocation(latitude: 26.13224, longitude:   3.63400)
    let apollo16 = CLLocation(latitude: -8.97341, longitude:  15.49859)
    let apollo17 = CLLocation(latitude: 20.18809, longitude:  30.77475)
    
    private let weatherLayer = WindLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        planetaryView.tileDataSource = self
        planetaryView.tileDelegate = self
        
        planetaryView.markerDataSource = self
        planetaryView.markerDelegate = self
        
        planetaryView.polygonDataSource = self
        planetaryView.polygonDelegate = self
        
        planetaryView.animatedLinesDataSource = self
        planetaryView.animatedLinesDelegate = self
        
        planetaryView.planetaryViewDelegate = self
        
        planetaryView.look(at: apollo11.coordinate)
        planetaryView.setLookDistance(2)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        planetaryView.didReceiveMemoryWarning()
    }
    
    // MARK: Tile Data Source
    
    func numberOfTileLayers(in view: PMPlanetaryView!) -> UInt {
        return 2
    }
    
    public func planetaryView(_ view: PMPlanetaryView!, urlForTileLayer layer: UInt, withZoom zoom: UInt, atX x: UInt, andY y: UInt) -> URL! {
        if layer == 0 {
            return URL(string: "https://dl.dropboxusercontent.com/u/6367136/charts/sec/\(zoom)/\(x)/\(y).webp")
        }
        if zoom == 1 {
            return weatherLayer.url(withZoom: zoom, atX: x, andY: y)
        } else {
            return nil
        }
    }
    
    func planetaryView(_ view: PMPlanetaryView!, imageFrom data: Data!, forTileLayer layer: UInt) -> UIImage! {
        
        if layer == 0 {
            return YYImage(data: data)
        } else {
            return weatherLayer.imageFromData(data: data)
        }
    }
    
    // MARK: Tile Delegate
    
    func planetaryView(_ view: PMPlanetaryView, segmentsPerSideForTileLayer layer: UInt) -> Int {
        return 20
    }
    
    // MARK: Marker Data Source
    
    func numberOfMarkerSets(in: PMPlanetaryView!) -> Int {
        return 0//2
    }
    
    func planetaryView(_ view: PMPlanetaryView, numberOfMarkersInSet set: Int) -> Int {
        return 3
    }
    
    func planetaryView(_ view: PMPlanetaryView, imageForMarkerAt index: Int, inSet set: Int) -> UIImage! {
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 50, height: 50), false, 1.0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        context.clear(CGRect(x: 0, y: 0, width: 50, height: 50))
        
        context.setLineWidth(2.0)
        context.setStrokeColor(red: set == 0 ? 1.0 : 0.0, green: set == 0 ? 0.0 : 1.0, blue: 1.0, alpha: 1.0)
        context.setFillColor  (red: set == 0 ? 1.0 : 0.0, green: set == 0 ? 0.0 : 1.0, blue: 1.0, alpha: 0.5)
        
        context  .fillEllipse(in: CGRect(x: 2, y: 2, width: 46, height:46))
        context.strokeEllipse(in: CGRect(x: 2, y: 2, width: 46, height:46))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func planetaryView(_ view: PMPlanetaryView, coordinateForMarkerAt index: Int, inSet set: Int) -> CLLocationCoordinate2D {
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
    
    func planetaryView(_ view: PMPlanetaryView, sizeForMarkersInSet set: Int) -> CGSize {
        return set == 0 ?  CGSize(width: 50, height: 50) : CGSize(width: 500000, height: 500000)
    }
    
    func planetaryView(_ view: PMPlanetaryView, useScreenSpaceForMarkersInSet set: Int) -> Bool {
        return set == 0
    }
    
    func planetaryView(_ view: PMPlanetaryView, minimumDistanceForMarkersInSet set: Int) -> CGFloat {
        return 3
    }
    
    // MARK: Polygon Data Source
    
    func numberOfPolygonSets(in: PMPlanetaryView!) -> Int {
        return 0//2
    }
    
    func planetaryView(_ view: PMPlanetaryView, numberOfPolygonsInSet set: Int) -> Int {
        return 1
    }
    
    func planetaryView(_ view: PMPlanetaryView, coordinatesForPolygonAt index: Int, inSet set: Int) -> [CLLocation]! {
        if (set == 0)
        {
            return [apollo11, apollo12, apollo14]
        }
        else
        {
            return [apollo15, apollo16, apollo17]
        }
    }
    
    func planetaryView(_ view: PMPlanetaryView, closePolygonAt index: Int, inSet set: Int) -> Bool {
        return true
    }
    
    // MARK: Polygon Delegate
    
    func planetaryView(_ view: PMPlanetaryView, useScreenSpaceForPolygonsInSet set: Int) -> Bool {
        return set == 0
    }
    
    func planetaryView(_ view: PMPlanetaryView, widthForPolygonOutlinesInSet set: Int) -> CGFloat {
        return set == 0 ? 15 : 100000
    }
    
    func planetaryView(_ view: PMPlanetaryView, fillColorForPolygonOutlinesInSet set: Int) -> UIColor! {
        return set == 0 ? UIColor.white.withAlphaComponent(1.0) : UIColor.yellow.withAlphaComponent(1.0)
    }

    func planetaryView(_ view: PMPlanetaryView, minimumDistanceForPolygonsInSet set: Int) -> CGFloat {
        return 3
    }

    func planetaryView(_ view: PMPlanetaryView, segmentsPerSideForPolygonAt index: Int, inSet set: Int) -> UInt {
        return 10
    }
    
    // MARK: Planetary View Delegate
    
    func planetaryView(_ view: PMPlanetaryView, movedToDistance distance: CGFloat) {
        if distance > 1 {
            view.lineSpacingInDegrees = 10
        } else {
            view.lineSpacingInDegrees = 5
        }
    }
    
    // MARK: Animated Lines Data Source
    
    func numberOfAnimatedLines(in view: PMPlanetaryView!) -> Int {
        return 5000
    }
    
    func animatedLineImage(for view: PMPlanetaryView!) -> UIImage! {
        return UIImage(named: "wind.jpg")
    }
    
    // MARK: Animated Lines Delegate
}

