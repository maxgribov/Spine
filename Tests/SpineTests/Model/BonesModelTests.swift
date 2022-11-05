//
//  BonesModelTests.swift
//  
//
//  Created by Max Gribov on 05.11.2022.
//

import XCTest
@testable import Spine

final class BonesModelTests: XCTestCase {
    
    func testDecoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "bones", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([BoneModel].self, from: json)
        
        // then
        XCTAssertEqual(result[0].name, "root")
        
        XCTAssertEqual(result[1].name, "hip")
        XCTAssertEqual(result[1].parent, "root")
        XCTAssertEqual(result[1].position, .init(x: 0, y: 247.47))
        
        XCTAssertEqual(result[2].name, "torso")
        XCTAssertEqual(result[2].parent, "hip")
        XCTAssertEqual(result[2].lenght, 127.56, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].rotation, 103.82, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].position, .init(x: -1.62, y: 4.9))
        XCTAssertEqual(result[2].color.value, "e0da19ff")
    }
}
