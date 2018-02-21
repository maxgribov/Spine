//
//  BoneTests.swift
//  SpineTests
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class BoneTests: XCTestCase {
    
    func testInitWithModel() {
        
        //given
        let json = """
        {
            "name": "back-foot-tip",
            "parent": "rear-foot",
            "length": 50.3,
            "rotation": -0.85,
            "x": 51.17,
            "y": 0.24,
            "transform": "noRotationOrReflection",
            "scaleX": 0.785,
            "scaleY": 0.785,
            "shearX": 0.21,
            "shearY": 0.97,
            "inheritScale": false,
            "inheritRotation": false,
            "color": "ff000dff",
        }
        """.data(using: .utf8)!

        let boneModel = try! JSONDecoder().decode(BoneModel.self, from: json)
        
        //when
        let bone = Bone(boneModel)
        
        //then
        XCTAssertEqual(bone.model.name, boneModel.name)
        XCTAssertEqual(bone.name, "bone:\(boneModel.name)")
        
        //for some reason CGFloat.ulpOfOne is too high precision for SKNode... but 0.001 is quite enough
        XCTAssertEqual(bone.position.x, boneModel.position.x, accuracy: 0.001)
        XCTAssertEqual(bone.position.y, boneModel.position.y, accuracy: 0.001)
        XCTAssertEqual(bone.zRotation, boneModel.rotation * degreeToRadiansFactor, accuracy: 0.001)
        XCTAssertEqual(bone.xScale, boneModel.scale.dx, accuracy: 0.001)
        XCTAssertEqual(bone.yScale, boneModel.scale.dy, accuracy: 0.001)
    }
}
