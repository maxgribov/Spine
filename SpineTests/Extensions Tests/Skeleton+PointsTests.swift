//
//  Skeleton+PointsTests.swift
//  SpineTests
//
//  Created by Max Gribov on 21/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class Skeleton_PointsTests: XCTestCase {
    
    var model: SpineModel?
    
    override func setUp() {
        super.setUp()
        
        let json = """
            {
            "skeleton": { "hash": "YnCM1p0MnS2GfM0Hrdlcgd/V2ag", "spine": "3.6.52", "width": 0, "height": 0, "images": "" },
            "bones": [
                { "name": "root" }
            ],
            "slots": [
                { "name": "point1", "bone": "root", "attachment": "point1" },
                { "name": "point2", "bone": "root", "attachment": "point3" }
            ],
            "skins": {
                "default": {
                    "point1": {
                        "point1": { "type": "point" }
                    },
                    "point2": {
                        "point2": { "type": "point" },
                        "point3": { "type": "point" }
                    }
                }
            },
            "animations": {
                "animation": {}
            }
            }
            """.data(using: .utf8)!
        
        model = try? JSONDecoder().decode(SpineModel.self, from: json)
    }
    
    override func tearDown() {
        
        model = nil
        super.tearDown()
    }
    
    func testPoints() {
    
        //given
        guard let model = model else {
            
            XCTFail("model shold not be nil")
            return
        }
        let skeleton = Skeleton(model, atlas: nil)
        skeleton.applySkin()
        
        //when
        guard let points = skeleton.points else {
            
            XCTFail("points should not be nil")
            return
        }
        
        //then
        XCTAssertTrue(points.count == 3)
    }
    
    func testActivePoints() {
        
        //given
        guard let model = model else {
            
            XCTFail("model shold not be nil")
            return
        }
        let skeleton = Skeleton(model, atlas: nil)
        skeleton.applySkin()
        
        //when
        guard let activePoints = skeleton.activePoints else {
            
            XCTFail("points should not be nil")
            return
        }

        //then
        XCTAssertTrue(activePoints.count == 2)
    }
}
