//
//  AnimationTests.swift
//  SpineTests
//
//  Created by Max Gribov on 10/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
import SpriteKit
@testable import Spine

class AnimationTests: XCTestCase {
    
    func testTimeFunctionLinear() {

        //given
        let model = CurveModelType.linear
        let action = SKAction()
        
        //when
        setTiming(action, model)
        
        //then
        XCTAssertEqual(action.timingMode, .linear)
        //TODO: figure out how to test it later
        //XCTAssertNil(action.timingFunction)

    }
    
    func testTimeFunctionStepped() {
        
        //given
        let model = CurveModelType.stepped
        let action = SKAction()
        
        //when
        setTiming(action, model)

        //then
        XCTAssertEqual(action.timingFunction(0), 0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(action.timingFunction(1.0), 1.0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(action.timingFunction(0.5), 0, accuracy: Float.ulpOfOne)
    }
    
    func testTimeFunctionBezier() {
        
        //given
        
        let bezierValues: [Float] = [1, 0, 0, 1]
        let model = CurveModelType.bezier(CurveModelType.BezierCurveModel(bezierValues)!)
        let action = SKAction()
        
        //when
        setTiming(action, model)

        //then
        XCTAssertEqual(action.timingFunction(0), 0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(action.timingFunction(0.5), 0.5, accuracy: Float.ulpOfOne)
        XCTAssertEqual(action.timingFunction(1.0), 1.0, accuracy: Float.ulpOfOne)
    }
}

