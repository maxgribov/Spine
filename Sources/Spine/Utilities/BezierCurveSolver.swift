//
//  BezierCurveSolver.swift
//  Spine
//
//  Created by Max Gribov on 13/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

//
// inspired by the source: https://github.com/AriaMinaei/timing-function
// by Aria Minaei
//

import SpriteKit

struct BezierCurveSolver {
    
    let cx: Float
    let bx: Float
    let ax: Float
    let cy: Float
    let by: Float
    let ay: Float
    let isLinear: Bool
    
    init(_ curve: CurveModelType.BezierCurveModel) {
        
        self.init(curve.p0, curve.p1, curve.p2, curve.p3)
    }
    
    init(_ values: [Float]) {
        
        self.init(values[0], values[1], values[2], values[3])
    }
    
    init(_ point1x: Float, _ point1y: Float, _ point2x: Float, _ point2y: Float) {
        
        self.cx = 3.0 * point1x
        self.bx = 3.0 * (point2x - point1x) - cx
        self.ax = 1.0 - cx - bx
        self.cy = 3.0 * point1y
        self.by = 3.0 * (point2y - point1y) - cy
        self.ay = 1.0 - cy - by
        
        self.isLinear = point1x == point1y && point2x == point2y ? true : false
    }
    
    func sampleCurveX(time: Float) -> Float {
        
        return ((ax * time + bx) * time + cx) * time
    }
    
    func sampleCurveY(time: Float) -> Float {
        
        return ((ay * time + by) * time + cy) * time
    }
    
    func sampleCurveDerivativeX(time: Float) -> Float {
        
        return (3.0 * ax * time + 2.0 * bx) * time + cx
    }
    
    func solveCurveX(x: Float) -> Float {
        
        var t0: Float
        var t1: Float
        var t2: Float
        var x2: Float
        var d2: Float
        
        // newton
        t2 = x
        
        for _ in stride(from: 0, to: 7, by: 1) {
            
            x2 = sampleCurveX(time: t2) - x
            if  abs(x2) < Float.ulpOfOne {
                return t2
            }
            
            d2 = sampleCurveDerivativeX(time: t2)
            if abs(d2) < Float.ulpOfOne {
                break
            }
            
            t2 = t2 - x2 / d2
        }
        
        // bi-section
        t0 = 0
        t1 = 1
        t2 = x
        
        if t2 < t0 {
            
            return t0
            
        } else if t2 > t1 {
            
            return t1
        }
        
        while t0 < t1 {
            
            x2 = sampleCurveX(time: t2)
            
            if abs(x2 - x) < Float.ulpOfOne {
                
                return t2
            }
            
            if x > x2 {
                
                t0 = t2
                
            } else {
                
                t1 = t2
            }
            
            t2 = (t1 - t0) * 0.5 + t0
        }
        
        return t2
    }
    
    func solve(x: Float) -> Float {
        
        return sampleCurveY(time: solveCurveX(x: x))
    }
    
    func timingFunction() -> SKActionTimingFunction {
        
        if isLinear {
            
            return { time in time }
            
        } else {
            
            return { time in return self.solve(x: time) }
        }
    }
}
