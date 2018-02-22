//
//  CGPath+Spine.swift
//  Spine
//
//  Created by Max Gribov on 17/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension CGPath {
    
    class func path(with vertices: [CGFloat]) -> CGPath? {
        
        guard vertices.count % 2 == 0 else {
            
            return nil
        }
        
        var points = [CGPoint]()
        
        for i in stride(from: 0, to: vertices.count, by: 2) {

            let point = CGPoint(x: vertices[i], y: vertices[i+1])
            points.append(point)
        }
        
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        
        return path
    }
}
