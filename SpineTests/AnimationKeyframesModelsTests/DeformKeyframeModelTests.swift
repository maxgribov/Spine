//
//  DeformKeyframeModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class DeformKeyframeModelTests: XCTestCase {
    
    func testNormal() {
        
        //given
        let json = """
            {
                "time": 0,
                "offset": 16,
                "vertices": [-0.18341, -4.60426, -0.25211, -6.33094],
                "curve": [ 0.25, 0, 0.75, 1 ]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(DeformKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.offset, 16)
            if let vertices = keyframe.vertices {
                
                XCTAssertTrue(vertices.count == 4)
                XCTAssertEqual(vertices[0], -0.18341, accuracy: CGFloat.ulpOfOne)
                XCTAssertEqual(vertices[1], -4.60426, accuracy: CGFloat.ulpOfOne)
                XCTAssertEqual(vertices[2], -0.25211, accuracy: CGFloat.ulpOfOne)
                XCTAssertEqual(vertices[3], -6.33094, accuracy: CGFloat.ulpOfOne)
                
            } else {
                
                XCTFail("Vertices should not be nil")
            }
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertTrue(keyframe.curve.bezierValue.count == 4)
            XCTAssertEqual(keyframe.curve.bezierValue[0], 0.25, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[1], 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[2], 0.75, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(keyframe.curve.bezierValue[3], 1, accuracy: CGFloat.ulpOfOne)

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
        let keyframe = try? JSONDecoder().decode(DeformKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.0667, accuracy: TimeInterval.ulpOfOne)
            XCTAssertEqual(keyframe.offset, 0)
            XCTAssertNil(keyframe.vertices)
            XCTAssertEqual(keyframe.curve.name, "linear")
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
}
