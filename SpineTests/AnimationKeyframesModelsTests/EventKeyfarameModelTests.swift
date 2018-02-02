//
//  EventKeyfarameModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class EventKeyfarameModelTests: XCTestCase {
    
    func testNormal() {
        
        //given
        let json = """
            {
                "time": 0,
                "name": "footstep",
                "int": -3,
                "float": 0.123,
                "string": "some-string"
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(EventKeyfarameModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 0)
            XCTAssertEqual(keyframe.event, "footstep")
            XCTAssertEqual(keyframe.int, -3)
            XCTAssertEqual(keyframe.float, 0.123)
            XCTAssertEqual(keyframe.string, "some-string")
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
    
    func testOmitted() {
        
        //given
        let json = """
            {
                "time": 1.1333,
                "name": "footstep"
            }
            """.data(using: .utf8)!
        
        //when
        let keyframe = try? JSONDecoder().decode(EventKeyfarameModel.self, from: json)
        
        //then
        if let keyframe = keyframe {
            
            XCTAssertEqual(keyframe.time, 1.1333)
            XCTAssertEqual(keyframe.event, "footstep")
            XCTAssertNil(keyframe.int)
            XCTAssertNil(keyframe.float)
            XCTAssertNil(keyframe.string)
            
        } else {
            
            XCTAssertNotNil(nil, "keyframe should not be nil")
        }
    }
}
