//
//  BoneKeyframeTranslateModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class BoneKeyframeTranslateModelTests: XCTestCase {
    
    func testLinear() {
        
        //given
        let json = """
            {
                "time": 0,
                "x": -69.06,
                "y": 0
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeTranslateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.position.x, -69.06)
            XCTAssertEqual(keyframe.position.y, 0)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testStepped() {
        
        //given
        let json = """
            {
                "time": 0.5,
                "curve": "stepped",
                "x": -88.4,
                "y": 123.6
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeTranslateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.5)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.position.x, -88.4)
            XCTAssertEqual(keyframe.position.y, 123.6)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testBezier() {
        
        //given
        let json = """
            {
                "time": 1.33,
                "curve": [0.591, 0, 0.642, 1],
                "x": -88.4,
                "y": 123.6
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeTranslateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.33)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertEqual(keyframe.curve.bezierValue, [0.591, 0, 0.642, 1])
            XCTAssertEqual(keyframe.position.x, -88.4)
            XCTAssertEqual(keyframe.position.y, 123.6)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testLinearOmitted() {
        
        //given
        let json = """
            {
                "time": 2.45
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeTranslateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 2.45)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.position.x, 0)
            XCTAssertEqual(keyframe.position.y, 0)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testSteppedOmitted() {
        
        //given
        let json = """
            {
                "time": 3.5,
                "curve": "stepped"
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeTranslateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 3.5)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.position.x, 0)
            XCTAssertEqual(keyframe.position.y, 0)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testBezierOmitted() {
        
        //given
        let json = """
            {
                "time": 4.345,
                "curve": [0.591, 0, 0.642, 1]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(BoneKeyframeTranslateModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 4.345)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertEqual(keyframe.curve.bezierValue, [0.591, 0, 0.642, 1])
            XCTAssertEqual(keyframe.position.x, 0)
            XCTAssertEqual(keyframe.position.y, 0)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
}
