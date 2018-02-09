//
//  AnimationTests.swift
//  SpineTests
//
//  Created by Max Gribov on 10/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class AnimationTests: XCTestCase {
    
    func testTimeFunctionLinear() {

        //given
        let model = CurveModelType.linear
        
        //when
        let function = timingFunction(model)
        
        //then
        XCTAssertEqual(function(0), 0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(function(1.0), 1.0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(function(0.5), 0.5, accuracy: Float.ulpOfOne)
    }
    
    func testTimeFunctionStepped() {
        
        //given
        let model = CurveModelType.stepped
        
        //when
        let function = timingFunction(model)
        
        //then
        XCTAssertEqual(function(0), 0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(function(1.0), 1.0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(function(0.5), 0, accuracy: Float.ulpOfOne)
    }
    
    func testTimeFunctionBezier() {
        
        //given
        let bezierValues: [Float] = [0.591, 0, 0.642, 1]
        let time: Float = 0.53
        
        let part1 = pow(1 - time, 3) * bezierValues[0]
        let part2 = 3 * time * pow(1 - time, 2) * bezierValues[1]
        let part3 = 3 * pow(time, 2) * (1 - time) * bezierValues[2]
        let part4 = pow(time, 3) * bezierValues[3]
        let result = part1 + part2 + part3 + part4
        
        let model = CurveModelType.bezier(CurveModelType.BezierCurveModel(bezierValues)!)
        
        //when
        let function = timingFunction(model)
        
        //then
        XCTAssertEqual(function(time), result, accuracy: Float.ulpOfOne)
    }
    

    
}
