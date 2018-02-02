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
            
            XCTAssertEqual(keyframe.time, 0.3)
            
            if let offset1 = keyframe.offsets.filter({ $0.slot == "smoke-puff1-bg2" }).first {
                
                XCTAssertEqual(offset1.offset, 24)
                
            } else {
                
                XCTAssertNotNil(nil, "offset1 should not be nil")
            }
            
            if let offset2 = keyframe.offsets.filter({ $0.slot == "smoke-puff1-fg4" }).first {
                
                XCTAssertEqual(offset2.offset, -4)
                
            } else {
                
                XCTAssertNotNil(nil, "offset2 should not be nil")
            }
            
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
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
            
            XCTAssertNotNil(nil, "offset should not be nil")
        }
    }
}
