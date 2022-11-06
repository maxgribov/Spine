//
//  SkinsModelTests.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import XCTest
@testable import Spine

final class SkinsModelTests: XCTestCase {

    func testDecoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "skins", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([SkinModel].self, from: json)
        
        // then
        XCTAssertEqual(result[0].name, "default")

    }

}
