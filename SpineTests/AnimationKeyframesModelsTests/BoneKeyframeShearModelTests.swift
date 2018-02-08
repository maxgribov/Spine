//
//  BoneKeyframeShearModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class BoneKeyframeShearModelTests: XCTestCase {
    
    func testLinear() {
        
        //given
        let json = """
            {
                "time": 0,
                "x": 0,
                "y": 4.63
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeShearModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.shear.dx, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shear.dy, 4.63, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testStepped() {
        
        //given
        let json = """
            {
                "time": 0.43,
                "curve": "stepped",
                "x": -5.74,
                "y": 4.63
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeShearModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.43, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.shear.dx, -5.74, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shear.dy, 4.63, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testBezier() {
        
        //given
        let json = """
            {
                "time": 1.123,
                "curve": [0.823, 0.24, 0.867, 0.66],
                "x": 1.67,
                "y": 34.481
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeShearModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.123, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertTrue(keyframe.curve.bezierValue.count == 4)
            XCTAssertEqual(keyframe.curve.bezierValue[0], 0.823, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[1], 0.24, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[2], 0.867, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[3], 0.66, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shear.dx, 1.67, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shear.dy, 34.481, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testLinearOmitted() {
        
        //given
        let json = """
            {
                "time": 1.28
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeShearModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.28, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.shear.dx, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shear.dy, 0, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testSteppedOmitted() {
        
        //given
        let json = """
            {
                "time": 1.667,
                "curve": "stepped"
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeShearModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.667, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.shear.dx, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shear.dy, 0, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testBezierOmitted() {
        
        //given
        let json = """
            {
                "time": 1.923,
                "curve": [0.823, 0.24, 0.867, 0.66]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeShearModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.923, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertTrue(keyframe.curve.bezierValue.count == 4)
            XCTAssertEqual(keyframe.curve.bezierValue[0], 0.823, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[1], 0.24, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[2], 0.867, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[3], 0.66, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shear.dx, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shear.dy, 0, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
}
