//
//  SKColor+Extensions.swift
//  
//
//  Created by Max Gribov on 17.11.2022.
//

import SpriteKit

extension SKColor {
    
    func updated(channel: ColorChannel, index: Int) -> SKColor {
        
        guard channel >= 0, channel <= 1 else { return self }
        
        switch index {
        case 0: return updated(red: channel)
        case 1: return updated(green: channel)
        case 2: return updated(blue: channel)
        case 3: return updated(alpha: channel)
        default: return self
        }
    }
    
    func updated(red channel: ColorChannel) -> SKColor {
        
        .init(red: channel, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha)
    }
    
    func updated(green channel: ColorChannel) -> SKColor {
        
        .init(red: rgba.red, green: channel, blue: rgba.blue, alpha: rgba.alpha)
    }
    
    func updated(blue channel: ColorChannel) -> SKColor {
        
        .init(red: rgba.red, green: rgba.green, blue: channel, alpha: rgba.alpha)
    }
    
    func updated(alpha channel: ColorChannel) -> SKColor {
        
        .init(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: channel)
    }
    
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
}
