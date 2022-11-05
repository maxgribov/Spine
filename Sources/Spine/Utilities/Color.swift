//
//  Color.swift
//  Spine
//
//  Created by Max Gribov on 17/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

#if os(OSX)
    
    func createColor(with model: ColorModel) -> NSColor {
    
        return NSColor(srgbRed: model.red, green: model.green, blue: model.blue, alpha: model.alpha)
    }

#else
    
    func createColor(with model: ColorModel) -> UIColor {
        
        return UIColor(red: model.red, green: model.green, blue: model.blue, alpha: model.alpha)
    }

#endif
