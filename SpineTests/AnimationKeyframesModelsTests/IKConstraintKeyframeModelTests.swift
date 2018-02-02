//
//  IKConstraintKeyframeModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class IKConstraintKeyframeModelTests: XCTestCase {
    
    func testNormal() {
        
        //given
        let json = """
            {
                "time": 0,
                "mix": 0.75,
                "blendPositive": true
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(IKConstraintKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0)
            XCTAssertEqual(keyframe.mix, 0.75)
            XCTAssertEqual(keyframe.blendPositive, true)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testOmitted() {
        
        //given
        let json = """
            {
                "time": 0.1333
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(IKConstraintKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.1333)
            XCTAssertEqual(keyframe.mix, 1.0)
            XCTAssertEqual(keyframe.blendPositive, false)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
}
