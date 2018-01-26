//
//  Model+Structs.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

struct ColorModel {
    
    let value: String
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(_ color: String) {
        
        //TODO: create real implementation later
        
        value = color
        red = 0
        green = 0
        blue = 0
        alpha = 0
    }
    
    init?(_ color: String?) {
        
        //TODO: create real implementation later
        
        if let color = color {
            
            value = color
            red = 0
            green = 0
            blue = 0
            alpha = 0
            
        } else {
            
            return nil
        }
    }
}

struct EventModel {
    
    let name: String
    let int: Int
    let float: CGFloat
    let string: String?
    
    init(_ name: String, _ int: Int = 0, _ float: CGFloat = 0, _ string: String?) {
        
        self.name = name
        self.int = int
        self.float = float
        self.string = string
    }
}

struct BezierCurveModel {
    
    let c1: CGFloat
    let c2: CGFloat
    let c3: CGFloat
    let c4: CGFloat
    
    init?(_ values: [CGFloat]) {
        
        guard values.count == 4 else {
            
            return nil
        }
        
        self.c1 = values[0]
        self.c2 = values[1]
        self.c3 = values[2]
        self.c4 = values[3]
    }
}
