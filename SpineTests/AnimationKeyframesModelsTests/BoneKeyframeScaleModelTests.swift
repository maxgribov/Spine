//
//  BoneKeyframeScaleModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class BoneKeyframeScaleModelTests: XCTestCase {
    
    func testLinear() {
        
        //given
        let json = """
            {
                "time": 0,
                "x": 0.645,
                "y": 1.426
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeScaleModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.scale.dx, 0.645)
            XCTAssertEqual(keyframe.scale.dy, 1.426)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testStepped() {
        
        //given
        let json = """
            {
                "time": 0.4,
                "curve": "stepped",
                "x": 0.685,
                "y": 1.516
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeScaleModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.4)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.scale.dx, 0.685)
            XCTAssertEqual(keyframe.scale.dy, 1.516)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testBezier() {
        
        //given
        let json = """
            {
                "time": 1,
                "curve": [0.823, 0.24, 0.867, 0.66],
                "x": 0.67,
                "y": 1.481
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeScaleModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertEqual(keyframe.curve.bezierValue, [0.823, 0.24, 0.867, 0.66])
            XCTAssertEqual(keyframe.scale.dx, 0.67)
            XCTAssertEqual(keyframe.scale.dy, 1.481)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
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
        let keyframe = try? JSONDecoder().decode(BoneKeyframeScaleModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.2333)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.scale.dx, 0)
            XCTAssertEqual(keyframe.scale.dy, 0)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
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
        let keyframe = try? JSONDecoder().decode(BoneKeyframeScaleModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.6)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.scale.dx, 0)
            XCTAssertEqual(keyframe.scale.dy, 0)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testBezierOmitted() {
        
        //given
        let json = """
            {
                "time": 1.9667,
                "curve": [0.823, 0.24, 0.867, 0.66]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeScaleModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.9667)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertEqual(keyframe.curve.bezierValue, [0.823, 0.24, 0.867, 0.66])
            XCTAssertEqual(keyframe.scale.dx, 0)
            XCTAssertEqual(keyframe.scale.dy, 0)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
}
