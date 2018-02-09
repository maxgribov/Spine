//
//  DrawOrderKeyframeModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class DrawOrderKeyframeModelTests: XCTestCase {
    
    func testKeyframe() {
        
        //given
        let json = """
            {
                "time": 0.3,
                "offsets": [{
                        "slot": "smoke-puff1-bg2",
                        "offset": 24
                    },
                    {
                        "slot": "smoke-puff1-fg4",
                        "offset": -4
                    }
                ]
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(DrawOrderKeyframeModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0.3, accuracy: TimeInterval.ulpOfOne)
            
            if let offset1 = keyframe.offsets.first(where: { $0.slot == "smoke-puff1-bg2" }){
                
                XCTAssertEqual(offset1.offset, 24)
                
            } else {
                
                XCTFail("offset1 should not be nil")
            }
            
            if let offset2 = keyframe.offsets.first(where: { $0.slot == "smoke-puff1-fg4" }) {
                
                XCTAssertEqual(offset2.offset, -4)
                
            } else {
                
                XCTFail("offset2 should not be nil")
            }
            
            
        } else {
            
            XCTFail("keyframe should not be nil")
        }
    }
    
    func testOffset() {
        
        //given
        let json = """
            {
                "slot": "smoke-puff1-fg4",
                "offset": -4
            }
            """.data(using: .utf8)!
        
        //when
        let offset = try? JSONDecoder().decode(DrawOrderOffsetModel.self, from: json)
        
        //then
        if let offset = offset {
            
            XCTAssertEqual(offset.slot, "smoke-puff1-fg4")
            XCTAssertEqual(offset.offset, -4)
            
        } else {
            
            XCTFail("offset should not be nil")
        }
    }
}
