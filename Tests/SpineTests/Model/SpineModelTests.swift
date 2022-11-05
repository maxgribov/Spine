//
//  SpineModelTests.swift
//  SpineTests
//
//  Created by Max Gribov on 05/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class SpineModelTests: XCTestCase {

    func testDecodable() {
        
        // given
        guard let url = Bundle.module.url(forResource: "spineboy-ess", withExtension: "json") else {
            
            XCTFail("Missing file spineboy-pro.json")
            return
        }
        
        guard let json = try? Data(contentsOf: url) else {
            
            XCTFail("Unable extract data from spineboy-pro.json")
            return
        }
        
        //when
        let model = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        XCTAssertNotNil(model)
        
    }
}
