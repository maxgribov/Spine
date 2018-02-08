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
    
    var json: Data?
    
    override func setUp() {
        super.setUp()
        
        let bundle = Bundle(for: type(of: self))
        
        guard let url = bundle.url(forResource: "spineboy-pro", withExtension: "json") else {
            
            XCTFail("Missing file spineboy-pro.json")
            return
        }
        
        guard let json = try? Data(contentsOf: url) else {
            
            XCTFail("Unable extract data from spineboy-pro.json")
            return
        }
        
        self.json = json
    }

    func testSkeleton() {
      
        //given
        let json = self.json!

        do {
            
            //when
            let model = try JSONDecoder().decode(SpineModel.self, from: json)
            
            //then
            XCTAssertEqual(model.skeleton.hash, "FrNJhva2RVZ1bbIjdNspNttett4")
            XCTAssertEqual(model.skeleton.spine, "3.6.32")
            XCTAssertEqual(model.skeleton.size.width, 419.84, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(model.skeleton.size.height, 686.08, accuracy: CGFloat.ulpOfOne)
            XCTAssertEqual(model.skeleton.path, "./images/")
            
        } catch {
            
            print("\(error)")
            XCTFail("Unanble to decode SpineModel from JSON")
        }
    }
    
    func testBones() {
        
        //given
        let json = self.json!
        
        do {
            
            //when
            let model = try JSONDecoder().decode(SpineModel.self, from: json)
            
            //then
            if let bones = model.bones {
                
                XCTAssertTrue(bones.count == 65)
                
                if let bone = bones.first(where: { $0.name == "aim-constraint-target" }) {
                    
                    XCTAssertEqual(bone.parent, "hip")
                    XCTAssertEqual(bone.position.x, 1.02, accuracy: CGFloat.ulpOfOne)
                    XCTAssertEqual(bone.position.y, 5.62, accuracy: CGFloat.ulpOfOne)
                    XCTAssertEqual(bone.color.value, "abe323ff")
                    XCTAssertEqual(bone.lenght, 26.24, accuracy: CGFloat.ulpOfOne)
                    XCTAssertEqual(bone.rotation, 19.61, accuracy: CGFloat.ulpOfOne)
                    
                } else {
                    
                    XCTFail("Bone should not be nil")
                }
                
            } else {
                
               XCTFail("Bones should not be nil")
            }
            
        } catch {
            
            print("\(error)")
            XCTFail("Unanble to decode SpineModel from JSON")
        }
    }
}
