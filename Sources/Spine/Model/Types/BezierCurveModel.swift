//
//  BezierCurveModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

public struct BezierCurveModel: Equatable {

    let p0: Float
    let p1: Float
    let p2: Float
    let p3: Float
    
    /// Initializes the Bezier curve data model
    /// - Parameters:
    ///   - p0: control point one time
    ///   - p1: control point one value
    ///   - p2: control point two time
    ///   - p3: control point two value
    public init(p0: Float, p1: Float, p2: Float, p3: Float) {
        
        self.p0 = p0
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
    }
    
    //TODO: tests
    /// Normalizes parameter values (puts them in the range between 0 and 1) based on time and the value for the current and previous keyframes
    /// - Parameters:
    ///   - timeStart: previous keyframe absolute time
    ///   - timeEnd: current keyframe absolute time
    ///   - valueStart: previous keyframe absolute value
    ///   - valueEnd: current keyframe absolute value
    /// - Returns: BezierCurveModel with normalized parameter values
    public func normalazed(timeStart: Float, timeEnd: Float, valueStart: Float, valueEnd: Float) -> BezierCurveModel {
        
        let timeRange = abs(timeEnd - timeStart)
        let p0normal = timeRange > 0 ? abs(p0 - timeStart) / timeRange : 0
        let p2normal = timeRange > 0 ? abs(p2 - timeStart) / timeRange : 0
        
        let valueRange = valueEnd - valueStart
        let p1normal = valueRange != 0 ? (p1 - valueStart) / valueRange : 0
        let p3normal = valueRange != 0 ? (p3 - valueStart) / valueRange : 0
        
        return BezierCurveModel(p0: p0normal.rounded(places: 3),
                                p1: p1normal.rounded(places: 3),
                                p2: p2normal.rounded(places: 3),
                                p3: p3normal.rounded(places: 3))
    }
}

extension BezierCurveModel: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        
        return "p0: \(p0), p1: \(p1), p2: \(p2), p3: \(p3)"
    }
}
