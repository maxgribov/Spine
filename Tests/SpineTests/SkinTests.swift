//
//  SkinTests.swift
//  SpineTests
//
//  Created by Max Gribov on 08/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class SkinTests: XCTestCase {

    func testAtlasNameDefault() {

        //{
        //    "head": { "x": 28.55, "y": 12.25, "rotation": -99.95, "width": 103, "height": 66 }
        //}
        
        //given
        let name = "head"
        let actualName: String? = nil
        let path: String? = nil
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "default")
    }
    
    func testAtlasActualNameDefault() {
        
        //{
        //    "head": { "name": "head", "x": 28.55, "y": 12.25, "rotation": -99.95, "width": 103, "height": 66 }
        //}
        
        //given
        let name = "head"
        let actualName: String? = "head"
        let path: String? = nil

        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "default")
    }
    
    func testAtlasNameNotDefault() {
        
        //{
        //    "goblin/head": { "x": 28.55, "y": 12.25, "rotation": -99.95, "width": 103, "height": 66 }
        //}
        
        //given
        let name = "goblin/head"
        let actualName: String? = nil
        let path: String? = nil
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "goblin")
    }
    
    func testAtlasActualNameNotDefault() {
        
        //{
        //    "head": { "name": "goblins/head", "x": 28.55, "y": 12.25, "rotation": -99.95, "width": 103, "height": 66 }
        //}
        
        //given
        let name = "head"
        let actualName: String? = "goblins/head"
        let path: String? = nil
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "goblins")
    }
    
    func testAtlasNameWithPathDefault() {
        
        //{
        //    "dagger": { "path": "dagger", "rotation": 170.46, "width": 26, "height": 108 }
        //}
        
        //given
        let name = "dagger"
        let actualName: String? = nil
        let path = "dagger"
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "default")
    }
    
    func testAtlasNameWithPathNotDefault() {
        
        //{
        //    "pelvis": { "path": "goblin/pelvis", "x": 4, "y": 1, "width": 62, "height": 43 }
        //}
        
        //given
        let name = "pelvis"
        let actualName: String? = nil
        let path = "goblin/pelvis"
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "goblin")
    }
    
    func testAtlasNameNotDefaultLong() {
        
        //{
        //    "goblis/male/top/head": { "x": 28.55, "y": 12.25, "rotation": -99.95, "width": 103, "height": 66 }
        //}
        
        //given
        let name = "goblis/male/top/head"
        let actualName: String? = nil
        let path: String? = nil
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "goblis/male/top")
    }
    
    func testAtlasActualNameNotDefaultLong() {
        
        //{
        //    "head": { "name": "goblis/male/top/head", "x": 28.55, "y": 12.25, "rotation": -99.95, "width": 103, "height": 66 }
        //}
        
        //given
        let name = "head"
        let actualName: String? = "goblis/male/top/head"
        let path: String? = nil
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "goblis/male/top")
    }
    
    func testAtlasNameWithPathNotDefaultLong() {
        
        //{
        //    "pelvis": { "path": "goblis/female/pelvis", "x": 4, "y": 1, "width": 62, "height": 43 }
        //}
        
        //given
        let name = "pelvis"
        let actualName: String? = nil
        let path = "goblis/female/pelvis"
        
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "goblis/female")
    }
    
    func testAtlasActualNameWithPathNotDefaultLong() {
        
        //{
        //    "pelvis": { "name": "goblis/pelvis", "path": "goblis/female/pelvis", "x": 4, "y": 1, "width": 62, "height": 43 }
        //}
        
        //given
        let name = "pelvis"
        let actualName: String? = "goblis/pelvis"
        let path = "goblis/female/pelvis"
        
        
        //when
        let theAtlasName = atlasName(from: name, actualName: actualName, path: path)
        
        //then
        XCTAssertEqual(theAtlasName, "goblis/female")
    }
}
