//
//  ConstraintsModelsTests.swift
//  SpineTests
//
//  Created by Max Gribov on 29/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class ConstraintsModelsTests: XCTestCase {
    
    //MARK: - IK
    
    func testIKConstraintModel() {
        
        //given
        let json = """
        {
            "name": "left leg",
            "order": 2,
            "bones": [ "left thigh", "left shin" ],
            "target": "left ankle",
            "mix": 0.5,
            "bendPositive": true
        }
        """.data(using: .utf8)!
        
        //when
        let ikConstraint = try? JSONDecoder().decode(IKConstraintModel.self, from: json)
        
        //then
        if let ikConstraint = ikConstraint {
            
            XCTAssertEqual(ikConstraint.name, "left leg")
            XCTAssertEqual(ikConstraint.order, 2)
            XCTAssertEqual(ikConstraint.bones, ["left thigh", "left shin"])
            XCTAssertEqual(ikConstraint.target, "left ankle")
            XCTAssertEqual(ikConstraint.mix, 0.5, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.blendPositive, true)

        } else {
            
            XCTFail("ikConstraint should not be nil")
        }
    }
    
    func testIKConstraintModelOmitted() {
        
        //given
        let json = """
        {
            "name": "left leg",
            "order": 2,
            "bones": [ "left thigh", "left shin" ],
            "target": "left ankle"
        }
        """.data(using: .utf8)!
        
        //when
        let ikConstraint = try? JSONDecoder().decode(IKConstraintModel.self, from: json)
        
        //then
        if let ikConstraint = ikConstraint {
            
            XCTAssertEqual(ikConstraint.name, "left leg")
            XCTAssertEqual(ikConstraint.order, 2)
            XCTAssertEqual(ikConstraint.bones, ["left thigh", "left shin"])
            XCTAssertEqual(ikConstraint.target, "left ankle")
            XCTAssertEqual(ikConstraint.mix, 1, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.blendPositive, false)
            
        } else {
            
            XCTFail("ikConstraint should not be nil")
        }
    }
    
    //MARK: - Transform
    
    func testTransformConstraintModel() {
        
        //given
        let json = """
        {
            "name": "weapon to hip",
            "order": 1,
            "bones": [ "front-foot-tip", "back-foot-tip" ],
            "target": "hip",
            "rotation": 0.5,
            "x": 125.4,
            "y": -24.5,
            "scaleX": 0.463,
            "scaleY": 0.813,
            "shearY": 0.94,
            "rotateMix": 0.55,
            "translateMix": 0.9,
            "scaleMix": 0.1,
            "shearMix": 0.6,
            "local": true,
            "relative": true
        }
        """.data(using: .utf8)!
        
        //when
        let TransformConstraint = try? JSONDecoder().decode(TransformConstraintModel.self, from: json)
        
        //then
        if let ikConstraint = TransformConstraint {
            
            XCTAssertEqual(ikConstraint.name, "weapon to hip")
            XCTAssertEqual(ikConstraint.order, 1)
            XCTAssertEqual(ikConstraint.bones, [ "front-foot-tip", "back-foot-tip" ])
            XCTAssertEqual(ikConstraint.target, "hip")
            XCTAssertEqual(ikConstraint.rotation, 0.5, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.offset.dx, 125.4, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.offset.dy, -24.5, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.scale.dx, 0.463, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.scale.dy, 0.813, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.rotateMix, 0.55, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.translateMix, 0.9, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.scaleMix, 0.1, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.shearMix, 0.6, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.local, true)
            XCTAssertEqual(ikConstraint.relative, true)
            
        } else {
            
            XCTFail("TransformConstraint should not be nil")
        }
    }
    
    func testTransformConstraintModelOmitted() {
        
        //given
        let json = """
        {
            "name": "weapon to hip",
            "order": 1,
            "bones": [ "rear-foot-ik" ],
            "target": "hip"
        }
        """.data(using: .utf8)!
        
        //when
        let TransformConstraint = try? JSONDecoder().decode(TransformConstraintModel.self, from: json)
        
        //then
        if let ikConstraint = TransformConstraint {
            
            XCTAssertEqual(ikConstraint.name, "weapon to hip")
            XCTAssertEqual(ikConstraint.order, 1)
            XCTAssertEqual(ikConstraint.bones, [ "rear-foot-ik" ])
            XCTAssertEqual(ikConstraint.target, "hip")
            XCTAssertEqual(ikConstraint.rotation, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.offset.dx, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.offset.dy, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.scale.dx, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.scale.dy, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.rotateMix, 1.0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.translateMix, 1.0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.scaleMix, 1.0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.shearMix, 1.0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(ikConstraint.local, false)
            XCTAssertEqual(ikConstraint.relative, false)
            
        } else {
            
            XCTFail("TransformConstraint should not be nil")
        }
    }
    
    //MARK: - Path
    
    func testPathConstraintModel() {
        
        //given
        let json = """
        {
          "name": "constraintName",
          "order": 0,
          "bones": [ "boneName1", "boneName2" ],
          "target": "slotName",
          "positionMode": "fixed",
          "spacingMode": "percent",
          "rotateMode": "chainScale",
          "rotation": 45,
          "position": 204,
          "spacing": 10,
          "rotateMix": 0,
          "translateMix": 0.5
        }
        """.data(using: .utf8)!
        
        //when
        let pathConstraint = try? JSONDecoder().decode(PathConstraintModel.self, from: json)
        
        //then
        if let pathConstraint = pathConstraint {
            
            XCTAssertEqual(pathConstraint.name, "constraintName")
            XCTAssertEqual(pathConstraint.order, 0)
            XCTAssertEqual(pathConstraint.bones, ["boneName1", "boneName2"])
            XCTAssertEqual(pathConstraint.target, "slotName")
            XCTAssertEqual(pathConstraint.positionMode, .fixed)
            XCTAssertEqual(pathConstraint.spacingMode, .percent)
            XCTAssertEqual(pathConstraint.rotateMode, .chainScale)
            XCTAssertEqual(pathConstraint.rotation, 45, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(pathConstraint.position, 204, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(pathConstraint.spacing, 10, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(pathConstraint.rotateMix, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(pathConstraint.translateMix, 0.5, accuracy: CGFloat.ulpOfOne)

        } else {
            
            XCTFail("pathConstraint should not be nil")
        }
    }
    
    func testPathConstraintModelOmitted() {
        
        //given
        let json = """
        {
          "name": "constraintName",
          "order": 0,
          "bones": [ "boneName1", "boneName2" ],
          "target": "slotName"
        }
        """.data(using: .utf8)!
        
        //when
        let pathConstraint = try? JSONDecoder().decode(PathConstraintModel.self, from: json)
        
        //then
        if let pathConstraint = pathConstraint {
            
            XCTAssertEqual(pathConstraint.name, "constraintName")
            XCTAssertEqual(pathConstraint.order, 0)
            XCTAssertEqual(pathConstraint.bones, ["boneName1", "boneName2"])
            XCTAssertEqual(pathConstraint.target, "slotName")
            XCTAssertEqual(pathConstraint.positionMode, .percent)
            XCTAssertEqual(pathConstraint.spacingMode, .length)
            XCTAssertEqual(pathConstraint.rotateMode, .tangent)
            XCTAssertEqual(pathConstraint.rotation, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(pathConstraint.position, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(pathConstraint.spacing, 0, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(pathConstraint.rotateMix, 1, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(pathConstraint.translateMix, 1, accuracy: CGFloat.ulpOfOne)
            
        } else {
            
            XCTFail("pathConstraint should not be nil")
        }
    }
}
