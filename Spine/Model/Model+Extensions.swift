//
//  Model+Extensions.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

extension CGPoint {
    
    init(_ point: [String: CGFloat]) {
        
        guard let x = point["x"], let y = point["y"] else {
            
            self = CGPoint.zero
            return
        }
        
        self = CGPoint(x: x, y: y)
    }
}

extension CGSize {
    
    init?(_ width: CGFloat?, _ height: CGFloat?) {
        
        guard let width = width, let height = height else {
            
            return nil
        }
        
        self = CGSize(width: width, height: height)
    }
}
