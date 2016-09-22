//
//  TemperatureLayer.swift
//  PlanetaryMapsSwift
//
//  Created by Seppo Pietarinen on 22/09/16.
//  Copyright © 2016 United Galactic. All rights reserved.
//

import UIKit

class TemperatureLayer: WeatherLayer {
    
    private static let temperaturePalette = [
        (-40, (UInt8(226), UInt8(226), UInt8(226))),
        (-20, (UInt8(243), UInt8(126), UInt8(243))),
        (-10, (UInt8(195), UInt8(  8), UInt8(195))),
        (  0, (UInt8(115), UInt8( 16), UInt8(115))),
        ( 10, (UInt8( 84), UInt8( 74), UInt8(138))),
        ( 20, (UInt8( 72), UInt8(101), UInt8(185))),
        ( 30, (UInt8( 72), UInt8(165), UInt8(161))),
        ( 40, (UInt8( 80), UInt8(198), UInt8( 72))),
        ( 50, (UInt8(183), UInt8(218), UInt8( 64))),
        ( 60, (UInt8(224), UInt8(202), UInt8( 56))),
        ( 70, (UInt8(223), UInt8(149), UInt8( 67))),
        ( 80, (UInt8(213), UInt8( 88), UInt8( 98))),
        ( 90, (UInt8(170), UInt8( 51), UInt8( 91))),
        (100, (UInt8(114), UInt8( 22), UInt8( 56))),
        (120, (UInt8( 53), UInt8(  4), UInt8( 11))),
    ]
    
    override init() {
        super.init()
        palette = TemperatureLayer.temperaturePalette
        pixelToIndex = { r, g, b in
            let floatValue = Float(r)
            // Calibration: Greenland -25F==96==0.75, Sahara 100F==167==13
            // Actually the indices are not linear but this is a close enough approximation.
            return 0.75 + (floatValue - 96) * (13 - 0.75) / (167 - 96)
        }
    }

    override func url(withZoom zoom: UInt, atX x: UInt, andY y: UInt) -> URL? {
        return URL(string: "https://dl.dropboxusercontent.com/u/6367136/charts/weather/temperature/\(zoom)/\(x)/\(y).jpg")
    }

}
