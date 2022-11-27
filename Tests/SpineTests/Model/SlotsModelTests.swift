//
//  SlotsModelTests.swift
//  
//
//  Created by Max Gribov on 05.11.2022.
//

import XCTest
@testable import Spine

final class SlotsModelTests: XCTestCase {
    
    func testDecoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "slots", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([SlotModel].self, from: json)
        
        // then
        XCTAssertEqual(result[0].name, "rear-upper-arm")
        XCTAssertEqual(result[0].bone, "rear-upper-arm")
        XCTAssertEqual(result[0].attachment, "rear-upper-arm")
        
        XCTAssertEqual(result[1].name, "head-bb")
        XCTAssertEqual(result[1].bone, "head")
        XCTAssertNil(result[1].attachment)
    }
}
