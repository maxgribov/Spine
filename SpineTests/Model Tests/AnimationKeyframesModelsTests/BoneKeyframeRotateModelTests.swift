//
//  BoneKeyframeRotateModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class BoneKeyframeRotateModelTests: XCTestCase {
    
    func testLinear() {
        
        //given
        let json = """
            {
                "time": 0,
                "angle": 55.63
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeRotateModel.self, from: json)
        
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.angle, 55.63, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testStepped() {
        
        //given
        let json = """
            {
                "time": 0.8,
                "curve": "stepped",
                "angle": -70.59
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeRotateModel.self, from: json)
        
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.8, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.angle, -70.59, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testBezier() {
        
        //given
        let json = """
            {
                "time": 0.96,
                "curve": [0.98, -0.26, 0.717, 1],
                "angle": -80.61
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeRotateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.96, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertTrue(keyframe.curve.bezierValue.count == 4)
            XCTAssertEqual(keyframe.curve.bezierValue[0], 0.98, accuracy: Float.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[1], -0.26, accuracy: Float.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[2], 0.717, accuracy: Float.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[3], 1, accuracy: Float.ulpOfOne)
            XCTAssertEqual(keyframe.angle, -80.61, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testLinearOmitted() {
        
        //given
        let json = """
            {
                "time": 1.2333
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeRotateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.2333, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.angle, 0, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testSteppedOmitted() {
        
        //given
        let json = """
            {
                "time": 1.6,
                "curve": "stepped"
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeRotateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.6, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.angle, 0, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testBezierOmitted() {
        
        //given
        let json = """
            {
                "time": 1.9667,
                "curve": [0.98, -0.26, 0.717, 1]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeRotateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.9667, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertTrue(keyframe.curve.bezierValue.count == 4)
            XCTAssertEqual(keyframe.curve.bezierValue[0], 0.98, accuracy: Float.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[1], -0.26, accuracy: Float.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[2], 0.717, accuracy: Float.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[3], 1, accuracy: Float.ulpOfOne)
            XCTAssertEqual(keyframe.angle, 0, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
}
