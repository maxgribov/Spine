//
//  TransformConstraintKeyframeModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class TransformConstraintKeyframeModelTests: XCTestCase {
    
    func testNormal() {
        
        //given
        let json = """
            {
                "time": 0,
                "rotateMix": 0.784,
                "translateMix": 0.659,
                "scaleMix": 0.423,
                "shearMix": 0.358
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(TransformConstraintKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.rotateMix, 0.784, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.translateMix, 0.659, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.scaleMix, 0.423, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shearMix, 0.358, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testOmitted() {
        
        //given
        let json = """
            {
                "time": 0.0667
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(TransformConstraintKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.0667, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.rotateMix, 1.0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.translateMix, 1.0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.scaleMix, 1.0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.shearMix, 1.0, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
}
