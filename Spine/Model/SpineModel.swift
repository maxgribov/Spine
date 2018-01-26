//
//  SpineModel.swift
//  Spine
//
//  Created by Max Gribov on 27/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

struct SpineModel {
    
    let skeleton: SkeletonModel
    let bones: [BoneModel]
    let slots: [SlotModel]
    let skins: [SkinModel]
    let ik: [IKConstraintModel]
    let transform: [TransformConstraintModel]
    let path: [PathConstraintModel]
    let events: [EventModel]
    let animations: [AnimationModel]
}

//MARK: - Helpers models

enum CurveModelType {
    
    case linear
    case stepped
    case bezier(BezierCurveModel)
    
    init(_ value: Int) {
        
        if value == 1 {
            
            self = .stepped
            
        } else {
            
            self = .linear
        }
    }
    
    init(_ value: [CGFloat]) {
        
        if let curve = BezierCurveModel(value) {
            
            self = .bezier(curve)
            
        } else {
            
            self = .linear
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
}

enum VerticeModel {
    
    case normal(CGPoint)
    case weighted(CGFloat)
    
    init(_ vertice: [String : CGFloat]) {
        
        guard let x = vertice["x"], let y = vertice["y"] else {
            
            self = .normal(CGPoint.zero)
            return
        }
        
        self = .normal(CGPoint(x: x, y: y))
    }
    
    init(_ vertice: CGFloat) {
        
        self = .weighted(vertice)
    }
}

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
