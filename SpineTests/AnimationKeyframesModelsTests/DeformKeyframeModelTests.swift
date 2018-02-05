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
            
            XCTAssertEqual(keyframe.time, 0)
            XCTAssertEqual(keyframe.offset, 16)
            if let vertices = keyframe.vertices {
                
                XCTAssertEqual(vertices, [-0.18341, -4.60426, -0.25211, -6.33094])
                
            } else {
                
                XCTFail("Vertices should not be nil")
            }
            XCTAssertEqual(keyframe.curve.name, "bezier")
            XCTAssertEqual(keyframe.curve.bezierValue, [ 0.25, 0, 0.75, 1 ])

        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
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
            
            XCTAssertEqual(keyframe.time, 0.0667)
            XCTAssertEqual(keyframe.offset, 0)
            XCTAssertNil(keyframe.vertices)
            XCTAssertEqual(keyframe.curve.name, "linear")
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
}
