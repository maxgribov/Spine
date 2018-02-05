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

    func testModel() {
      
        //given
        let bundle = Bundle(for: type(of: self))
        
        guard let url = bundle.url(forResource: "spineboy-pro", withExtension: "json") else {
            
            XCTFail("Missing file spineboy-pro.json")
            return
        }
        
        guard let json = try? Data(contentsOf: url) else {
            
            XCTFail("Unable extract data from spineboy-pro.json")
            return
        }

        do {
            
            //when
            let model = try JSONDecoder().decode(SpineModel.self, from: json)
            
            //then
            XCTAssertEqual(model.skeleton.hash, "FrNJhva2RVZ1bbIjdNspNttett4")
            XCTAssertEqual(model.skeleton.spine, "3.6.32")
            XCTAssertEqual(model.skeleton.size.width, 419.84)
            XCTAssertEqual(model.skeleton.size.height, 686.08)
            XCTAssertEqual(model.skeleton.path, "./images/")
            
        } catch {
            
            print("\(error)")
            XCTFail("Unanble to decode SpineModel from JSON")
        }
    }
}
