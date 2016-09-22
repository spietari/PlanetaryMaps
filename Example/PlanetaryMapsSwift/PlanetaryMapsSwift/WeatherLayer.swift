//
//  WeatherLayer.swift
//  PlanetaryMapsSwift
//
//  Created by Seppo Pietarinen on 22/09/16.
//  Copyright © 2016 United Galactic. All rights reserved.
//

import UIKit

class WeatherLayer: NSObject {

    var palette: [(Int, (UInt8, UInt8, UInt8))]?
    var pixelToIndex: ((UInt8, UInt8, UInt8)->(Float))?
    
    func url(withZoom zoom: UInt, atX x: UInt, andY y: UInt) -> URL?
    {
        return nil
    }
    
    func imageFromData(data: Data) -> UIImage? {
        
        guard let image = UIImage(data: data) else {
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -image.size.height)
        context.draw(image.cgImage!, in: CGRect(origin: CGPoint.zero, size: image.size))
        
        if let data = context.data {
            let pixelData = data.assumingMemoryBound(to: UInt8.self)
            let pixelCount = Int(image.size.width * image.size.height)
            for pixel in 0..<pixelCount {
                
                let color = pixelToColor(r: pixelData[4 * pixel + 0], g: pixelData[4 * pixel + 1], b: pixelData[4 * pixel + 2])
                //let color = pixelToColor(r: UInt8(105), g: UInt8(86), b: 0)
                //let color = pixelToColor(r: UInt8(148), g: UInt8(153), b: 0)
                pixelData[4 * pixel + 0] = color.0
                pixelData[4 * pixel + 1] = color.1
                pixelData[4 * pixel + 2] = color.2
            }
        }
        
        return self.image(image: UIGraphicsGetImageFromCurrentImageContext()!, changeAlphaTo: 0.8)
    }
    
    private func pixelToColor(r: UInt8, g: UInt8, b: UInt8) -> (UInt8, UInt8, UInt8) {
        
        guard let palette = palette else {
            return (UInt8(0), UInt8(0), UInt8(0))
        }
        
        guard let pixelToIndex = pixelToIndex else {
            return (UInt8(0), UInt8(0), UInt8(0))
        }
        
        var index = pixelToIndex(r, g, b)
        
        if index < 0 {
            index = 0
        } else if index > Float(palette.count - 1) {
            index = Float(palette.count - 1)
        }
        
        let baseIndex = Int(index)
        let nextIndex = baseIndex + 1
        
        let baseTuple = palette[baseIndex]
        
        if nextIndex >= palette.count {
            return baseTuple.1
        } else {
            
            let nextTuple = palette[nextIndex]
            
            let factor = 1 - (index - Float(Int(index)))
            
            // TODO potential problem with Pixel Order, now assumes BGR
            return (
                UInt8(factor * Float(baseTuple.1.2) + (1 - factor) * Float(nextTuple.1.2)),
                UInt8(factor * Float(baseTuple.1.1) + (1 - factor) * Float(nextTuple.1.1)),
                UInt8(factor * Float(baseTuple.1.0) + (1 - factor) * Float(nextTuple.1.0))
            )
        }
    }
    
    private func image(image: UIImage, changeAlphaTo alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setAlpha(alpha)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -image.size.height)
        context.draw(image.cgImage!, in: CGRect(origin: CGPoint.zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
}
