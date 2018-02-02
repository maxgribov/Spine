//
//  SlotKeyframeColorModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class SlotKeyframeColorModelTests: XCTestCase {
    
    func testLinear() {
        
        //given
        let json = """
            {
                "time": 0,
                "color": "ffffff3e"
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(SlotKeyframeColorModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0)
            XCTAssertEqual(keyframe.curve.name, "linear")
            XCTAssertEqual(keyframe.color.value, "ffffff3e")
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testStepped() {
        
        //given
        let json = """
            {
                "time": 0.0667,
                "color": "ffffff00",
                "curve": "stepped"
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(SlotKeyframeColorModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.0667)
            XCTAssertEqual(keyframe.curve.name, "stepped")
            XCTAssertEqual(keyframe.color.value, "ffffff00")
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testBezier() {
        
        //given
        let json = """
            {
                "time": 0.1333,
                "color": "fffffffe",
                "curve": [0.823, 0.24, 0.867, 0.66]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(SlotKeyframeColorModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.1333)
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertEqual(keyframe.curve.bezierValue, [0.823, 0.24, 0.867, 0.66])
            XCTAssertEqual(keyframe.color.value, "fffffffe")
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
}
