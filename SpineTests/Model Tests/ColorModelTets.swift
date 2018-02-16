//
//  ColorModelTets.swift
//  SpineTests
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class ColorModelTets: XCTestCase {
    
    func testWhiteColor() {
        
        //given
        let colorValue = "ffffffff"
        
        //when
        let colorModel = ColorModel(colorValue)
        
        //then
        XCTAssertEqual(colorModel.red, 1.0)
        XCTAssertEqual(colorModel.green, 1.0)
        XCTAssertEqual(colorModel.blue, 1.0)
        XCTAssertEqual(colorModel.alpha, 1.0)
    }
    
    func testBlackColor() {
        
        //given
        let colorValue = "000000ff"
        
        //when
        let colorModel = ColorModel(colorValue)
        
        //then
        XCTAssertEqual(colorModel.red, 0)
        XCTAssertEqual(colorModel.green, 0)
        XCTAssertEqual(colorModel.blue, 0)
        XCTAssertEqual(colorModel.alpha, 1.0)
    }
    
    func testClearWhiteColor() {
        
        //given
        let colorValue = "ffffff00"
        
        //when
        let colorModel = ColorModel(colorValue)
        
        //then
        XCTAssertEqual(colorModel.red, 1.0)
        XCTAssertEqual(colorModel.green, 1.0)
        XCTAssertEqual(colorModel.blue, 1.0)
        XCTAssertEqual(colorModel.alpha, 0)
    }

    func testRandomColor() {
    
        //given
        let colorValue = "ff000dff"
        
        //when
        let colorModel = ColorModel(colorValue)
        
        //then
        XCTAssertEqual(colorModel.red, 0xFF / 255.0)
        XCTAssertEqual(colorModel.green, 0x00 / 255.0)
        XCTAssertEqual(colorModel.blue, 0x0D / 255.0)
        XCTAssertEqual(colorModel.alpha, 0xFF / 255.0)
    }
    
    func testWrongValue() {
        
        //given
        let colorValue = "lsjdflj;sdf"
        
        //when
        let colorModel = ColorModel(colorValue)
        
        //then
        XCTAssertEqual(colorModel.red, 0)
        XCTAssertEqual(colorModel.green, 0)
        XCTAssertEqual(colorModel.blue, 0)
        XCTAssertEqual(colorModel.alpha, 0)
    }
}
