//
//  WindLayer.swift
//  PlanetaryMapsSwift
//
//  Created by Seppo Pietarinen on 22/09/16.
//  Copyright © 2016 United Galactic. All rights reserved.
//

import UIKit

class WindLayer: WeatherLayer {
    
    private static let windPalette = [
        ( 0, (UInt8( 88), UInt8( 83), UInt8(114))),
        ( 5, (UInt8( 84), UInt8( 85), UInt8(158))),
        (10, (UInt8( 69), UInt8(108), UInt8(181))),
        (15, (UInt8( 67), UInt8(145), UInt8(170))),
        (20, (UInt8( 79), UInt8(174), UInt8(125))),
        (25, (UInt8( 72), UInt8(189), UInt8( 70))),
        (30, (UInt8(131), UInt8(198), UInt8( 77))),
        (35, (UInt8(183), UInt8(209), UInt8( 64))),
        (40, (UInt8(214), UInt8(206), UInt8( 60))),
        (45, (UInt8(214), UInt8(180), UInt8( 60))),
        (50, (UInt8(214), UInt8(152), UInt8( 68))),
        (60, (UInt8(204), UInt8( 88), UInt8( 98))),
        (70, (UInt8(161), UInt8( 43), UInt8( 89))),
        (80, (UInt8(104), UInt8( 26), UInt8( 36))),
        (90, (UInt8( 43), UInt8(  0), UInt8(  1))),
    ]
    
    override init() {
        super.init()
        palette = WindLayer.windPalette
        pixelToIndex = { r, g, b in
            
            let x = Float(g) - 127
            let y = Float(b) - 127
            let speed = sqrtf(x * x + y * y)
            
            // Calibration: NW of Iceland 60MPH==105,86==11, S of Iceland 1MPH==127,127==0, Helsinki 14MPH=122,122=3
            // Actually the indices are not linear but this is a close enough approximation.
            return speed * 11 / 46
        }
    }
    
    override func url(withZoom zoom: UInt, atX x: UInt, andY y: UInt) -> URL? {
        return URL(string: "https://dl.dropboxusercontent.com/u/6367136/charts/weather/wind/\(zoom)/\(x)/\(y).jpg")
    }
    
}
