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
        XCTAssertEqual(result[0].lenght, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].transform, .normal)
        XCTAssertEqual(result[0].position, .zero)
        XCTAssertEqual(result[0].rotation, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].scale, .init(dx: 1, dy: 1))
        XCTAssertEqual(result[0].shear, .zero)
        XCTAssertEqual(result[0].inheritScale, true)
        XCTAssertEqual(result[0].inheritRotation, true)
        XCTAssertEqual(result[0].color, .init(value: "989898FF"))
        
        XCTAssertEqual(result[1].name, "front-upper-arm")
        XCTAssertEqual(result[1].parent, "torso")
        XCTAssertEqual(result[1].lenght, 69.45, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].transform, .noRotationOrReflection)
        XCTAssertEqual(result[1].position, .init(x: 103.76, y: 19.33))
        XCTAssertEqual(result[1].rotation, 168.38, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].scale, .init(dx: 0.7, dy: 0.8))
        XCTAssertEqual(result[1].shear, .init(dx: 3.25, dy: 2.5))
        XCTAssertEqual(result[1].inheritScale, false)
        XCTAssertEqual(result[1].inheritRotation, false)
        XCTAssertEqual(result[1].color.value, "00ff04ff")
    }
}
