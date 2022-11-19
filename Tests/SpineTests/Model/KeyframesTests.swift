//
//  KeyframesTests.swift
//  
//
//  Created by Max Gribov on 11.11.2022.
//

import XCTest
@testable import Spine

final class KeyframesTests: XCTestCase {}

//MARK: - Bone

extension KeyframesTests {
    
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

//MARK: - Slot

extension KeyframesTests {
    
    func testSlotKeyframeAttachmentModel_Decoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "slotAttachmentKeyframes", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([SlotKeyframeAttachmentModel].self, from: json)
        
        // then
        XCTAssertEqual(result.count, 4)
        
        XCTAssertEqual(result[0].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].name, nil)
        
        XCTAssertEqual(result[1].time, 1, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].name, nil)
        
        XCTAssertEqual(result[2].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].name, "hoverglow-small")
        
        XCTAssertEqual(result[3].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[3].name, "hoverglow-small")
    }
    
    func testSlotKeyframeColorModel_Decoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "slotColorKeyframes", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([SlotKeyframeColorModel].self, from: json)
        
        // then
        XCTAssertEqual(result.count, 3)
        
        //TODO: Update 
        /*
        XCTAssertEqual(result[0].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].color, .init(value: "ffffffff"))
        XCTAssertEqual(result[0].curve, .linear)
        
        XCTAssertEqual(result[1].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].color, .init(value: "ffffff62"))
        XCTAssertEqual(result[1].curve, .linear)
        
        XCTAssertEqual(result[2].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].color, .init(value: "ffffff62"))
        XCTAssertEqual(result[2].curve, .bezier(.init(p0: 0.232, p1: 0.65, p2: 0.249, p3: -2.15)))
         */
    }
}

//MARK: - Event

extension KeyframesTests {
    
    func testEventKeyframeModel_Decoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "eventKeyframes", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([EventKeyfarameModel].self, from: json)
        
        // then
        XCTAssertEqual(result.count, 3)
        
        XCTAssertEqual(result[0].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].event, "footstep")
        XCTAssertEqual(result[0].int, nil)
        XCTAssertEqual(result[0].float, nil)
        XCTAssertEqual(result[0].string, nil)
        XCTAssertEqual(result[0].volume, nil)
        XCTAssertEqual(result[0].balance, nil)
        
        XCTAssertEqual(result[1].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].event, "footstep")
        XCTAssertEqual(result[1].int, nil)
        XCTAssertEqual(result[1].float, nil)
        XCTAssertEqual(result[1].string, nil)
        XCTAssertEqual(result[1].volume, nil)
        XCTAssertEqual(result[1].balance, nil)
        
        XCTAssertEqual(result[2].time, 0.0667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].event, "footstep")
        XCTAssertEqual(result[2].int, 4)
        XCTAssertEqual(result[2].float!, 5.23, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].string, "six")
        XCTAssertEqual(result[2].volume!, 0.7, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].balance!, -0.5, accuracy: .ulpOfOne)
    }
}

//MARK: - Draw Order

extension KeyframesTests {
    
    func testDrawOrderKeyframeModel_Decoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "drawOrderKeyframes", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode([DrawOrderKeyframeModel].self, from: json)
        
        // then
        XCTAssertEqual(result.count, 3)
        
        XCTAssertEqual(result[0].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[0].offsets?.count, 0)
        
        XCTAssertEqual(result[1].time, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result[1].offsets?.count, 1)
        XCTAssertEqual(result[1].offsets?[0], .init(slot: "splat01", offset: 5))
        
        XCTAssertEqual(result[2].time, 1.3667, accuracy: .ulpOfOne)
        XCTAssertEqual(result[2].offsets?.count, 1)
        XCTAssertEqual(result[2].offsets?[0], .init(slot: "splat01", offset: 5))
    }
}
