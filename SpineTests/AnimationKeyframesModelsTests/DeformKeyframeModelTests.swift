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
                "vertices": [-0.18341, -4.60426, -0.25211, -6.33094]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(DeformKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0)
            XCTAssertEqual(keyframe.offset, 16)
            XCTAssertEqual(keyframe.vertices, [-0.18341, -4.60426, -0.25211, -6.33094])
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testOmitted() {
        
        //given
        let json = """
            {
                "time": 0.0667,
                "vertices": [-0.18341, -4.60426, -0.25211, -6.33094]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(DeformKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.0667)
            XCTAssertEqual(keyframe.offset, 0)
            XCTAssertEqual(keyframe.vertices, [-0.18341, -4.60426, -0.25211, -6.33094])
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
}
