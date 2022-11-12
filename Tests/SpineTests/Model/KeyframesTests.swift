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
        XCTAssertEqual(result.count, 6)
        
        XCTAssertEqual(result[0].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].angle, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].curve, .linear)
        
        XCTAssertEqual(result[1].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].angle, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].curve, .linear)
        
        XCTAssertEqual(result[2].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].angle, 12.19, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].curve, .linear)
        
        XCTAssertEqual(result[3].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[3].angle, 12.19, accuracy: .ulpOfOne)
        XCTAssertEqual(result[3].curve, .linear)
        
        XCTAssertEqual(result[4].time, 0.1333, accuracy: .ulpOfOne)
        XCTAssertEqual(result[4].angle, -6.86, accuracy: .ulpOfOne)
        XCTAssertEqual(result[4].curve, .stepped)
        
        XCTAssertEqual(result[5].time, 0.3, accuracy: .ulpOfOne)
        XCTAssertEqual(result[5].angle, -36.86, accuracy: .ulpOfOne)
        XCTAssertEqual(result[5].curve, .bezier(.init(p0: 0.354, p1: -36.61, p2: 0.412, p3: -32.35)))
    }
    
    func testBoneKeyframeTranslateModel_Decoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "translateBoneKeyframes", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([BoneKeyframeTranslateModel].self, from: json)
        
        // then
        XCTAssertEqual(result.count, 6)
        
        XCTAssertEqual(result[0].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].position, .zero)
        XCTAssertEqual(result[0].curve, .linear)
        
        XCTAssertEqual(result[1].time, 0.6333, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].position, .zero)
        XCTAssertEqual(result[1].curve, .linear)
        
        XCTAssertEqual(result[2].time, 0.5, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].position, .init(x: 1.065, y: 0))
        XCTAssertEqual(result[2].curve, .linear)
        
        XCTAssertEqual(result[3].time, 0.5, accuracy: .ulpOfOne)
        XCTAssertEqual(result[3].position, .init(x: 0, y: 0.94))
        XCTAssertEqual(result[3].curve, .linear)
        
        XCTAssertEqual(result[4].time, 0.4667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[4].position, .zero)
        XCTAssertEqual(result[4].curve, .bezier2(.init(p0: 0.469, p1: 1.005, p2: 0.492, p3: 1.065),
                                                 .init(p0: 0.475, p1: 1.018, p2: 0.492, p3: 0.94)))
        
        XCTAssertEqual(result[5].time, 0.5667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[5].position,.init(x: 0.99, y: 1.025))
        XCTAssertEqual(result[5].curve, .bezier2(.init(p0: 0.469, p1: 1.005, p2: 0.492, p3: 1.065),
                                                 .init(p0: 0.475, p1: 1.018, p2: 0.492, p3: 0.94)))
    }
    
    func testBoneKeyframeScaleModel_Decoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "translateBoneKeyframes", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([BoneKeyframeScaleModel].self, from: json)
        
        // then
        XCTAssertEqual(result.count, 6)
        
        XCTAssertEqual(result[0].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].scale, .init(dx: 1, dy: 1))
        XCTAssertEqual(result[0].curve, .linear)
        
        XCTAssertEqual(result[1].time, 0.6333, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].scale, .init(dx: 1, dy: 1))
        XCTAssertEqual(result[1].curve, .linear)
        
        XCTAssertEqual(result[2].time, 0.5, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].scale, .init(dx: 1.065, dy: 1))
        XCTAssertEqual(result[2].curve, .linear)
        
        XCTAssertEqual(result[3].time, 0.5, accuracy: .ulpOfOne)
        XCTAssertEqual(result[3].scale, .init(dx: 1, dy: 0.94))
        XCTAssertEqual(result[3].curve, .linear)
        
        XCTAssertEqual(result[4].time, 0.4667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[4].scale, .init(dx: 1, dy: 1))
        XCTAssertEqual(result[4].curve, .bezier2(.init(p0: 0.469, p1: 1.005, p2: 0.492, p3: 1.065),
                                                 .init(p0: 0.475, p1: 1.018, p2: 0.492, p3: 0.94)))
        
        XCTAssertEqual(result[5].time, 0.5667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[5].scale,.init(dx: 0.99, dy: 1.025))
        XCTAssertEqual(result[5].curve, .bezier2(.init(p0: 0.469, p1: 1.005, p2: 0.492, p3: 1.065),
                                                 .init(p0: 0.475, p1: 1.018, p2: 0.492, p3: 0.94)))
    }
    
    func testBoneKeyframeShearModel_Decoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "translateBoneKeyframes", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([BoneKeyframeShearModel].self, from: json)
        
        // then
        XCTAssertEqual(result.count, 6)
        
        XCTAssertEqual(result[0].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].shear, .zero)
        XCTAssertEqual(result[0].curve, .linear)
        
        XCTAssertEqual(result[1].time, 0.6333, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].shear, .zero)
        XCTAssertEqual(result[1].curve, .linear)
        
        XCTAssertEqual(result[2].time, 0.5, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].shear, .init(dx: 1.065, dy: 0))
        XCTAssertEqual(result[2].curve, .linear)
        
        XCTAssertEqual(result[3].time, 0.5, accuracy: .ulpOfOne)
        XCTAssertEqual(result[3].shear, .init(dx: 0, dy: 0.94))
        XCTAssertEqual(result[3].curve, .linear)
        
        XCTAssertEqual(result[4].time, 0.4667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[4].shear, .zero)
        XCTAssertEqual(result[4].curve, .bezier2(.init(p0: 0.469, p1: 1.005, p2: 0.492, p3: 1.065),
                                                 .init(p0: 0.475, p1: 1.018, p2: 0.492, p3: 0.94)))
        
        XCTAssertEqual(result[5].time, 0.5667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[5].shear,.init(dx: 0.99, dy: 1.025))
        XCTAssertEqual(result[5].curve, .bezier2(.init(p0: 0.469, p1: 1.005, p2: 0.492, p3: 1.065),
                                                 .init(p0: 0.475, p1: 1.018, p2: 0.492, p3: 0.94)))
    }
}
