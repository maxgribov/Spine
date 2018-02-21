//
//  CGPathExtensionTests.swift
//  SpineTests
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class CGPathExtensionTests: XCTestCase {

    func testPathWithVerticles() {
      
        //given
        let verticles: [CGFloat] = [ -41.2, 255.56, -19.19, 224.41, -27.24, 260.39, -40.13, 266.3 ]
        
        //when
        let path = CGPath.path(with: verticles)
        
        //then
        if let path = path {
            
            let point1 = CGPoint(x: verticles[0], y: verticles[1])
            XCTAssertTrue(path.contains(point1))
            
            let point2 = CGPoint(x: verticles[2], y: verticles[3])
            XCTAssertTrue(path.contains(point2))
            
        } else {
            
            XCTFail("path should not be nil")
        }
    }
}
