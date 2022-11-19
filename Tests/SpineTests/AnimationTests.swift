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
        let model = CurveModel.linear
        let action = SKAction()
        
        //when
        Animation.setTiming(action, model)
        
        //then
        XCTAssertEqual(action.timingMode, .linear)
        //TODO: figure out how to test it later
        //XCTAssertNil(action.timingFunction)

    }
    
    func testTimeFunctionStepped() {
        
        //given
        let model = CurveModel.stepped
        let action = SKAction()
        
        //when
        Animation.setTiming(action, model)

        //then
        XCTAssertEqual(action.timingFunction(0), 0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(action.timingFunction(1.0), 1.0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(action.timingFunction(0.5), 0, accuracy: Float.ulpOfOne)
    }
    
    func testTimeFunctionBezier() {
        
        //given
        
        let model = CurveModel.bezier(BezierCurveModel(p0: 1, p1: 0, p2: 0, p3: 1))
        let action = SKAction()
        
        //when
        Animation.setTiming(action, model)

        //then
        XCTAssertEqual(action.timingFunction(0), 0, accuracy: Float.ulpOfOne)
        XCTAssertEqual(action.timingFunction(0.5), 0.5, accuracy: Float.ulpOfOne)
        XCTAssertEqual(action.timingFunction(1.0), 1.0, accuracy: Float.ulpOfOne)
    }
}

