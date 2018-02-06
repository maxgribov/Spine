//
//  UIColor+Extensions.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

extension UIColor {
    
    convenience init(_ model: ColorModel) {
        
        self.init(red: model.red, green: model.green, blue: model.blue, alpha: model.alpha)
    }
}
