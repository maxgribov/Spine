//
//  KeyframesTests.swift
//  
//
//  Created by Max Gribov on 11.11.2022.
//

import XCTest
@testable import Spine

final class KeyframesTests: XCTestCase {

    func testBoneKeyframeRotateModel_Decoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "rotateBoneKeyframes", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([BoneKeyframeRotateModel].self, from: json)
        
        // then
        XCTAssertEqual(result.count, 5)
        
        XCTAssertEqual(result[0].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].angle, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].curve, .linear)
        
        XCTAssertEqual(result[1].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].angle, 12.19, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].curve, .linear)
        
        XCTAssertEqual(result[2].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].angle, 12.19, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].curve, .linear)
        
        XCTAssertEqual(result[3].time, 0.1333, accuracy: .ulpOfOne)
        XCTAssertEqual(result[3].angle, -6.86, accuracy: .ulpOfOne)
        XCTAssertEqual(result[3].curve, .stepped)
        
        XCTAssertEqual(result[4].time, 0.3, accuracy: .ulpOfOne)
        XCTAssertEqual(result[4].angle, -36.86, accuracy: .ulpOfOne)
        XCTAssertEqual(result[4].curve, .bezier(.init(p0: 0.354, p1: -36.61, p2: 0.412, p3: -32.35)))

    }

}
