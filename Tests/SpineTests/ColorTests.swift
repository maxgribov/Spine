//
//  ColorTests.swift
//  SpineTests
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class ColorTests: XCTestCase {

    func testCreateColor() {
        
        //given
        let colorModel = ColorModel(value: "db00f0ff")
        
        //when
        let color = createColor(with: colorModel)
        
        //then
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        XCTAssertEqual(red, colorModel.red, accuracy: CGFloat.ulpOfOne)
        XCTAssertEqual(green, colorModel.green, accuracy: CGFloat.ulpOfOne)
        XCTAssertEqual(blue, colorModel.blue, accuracy: CGFloat.ulpOfOne)
        XCTAssertEqual(alpha, colorModel.alpha, accuracy: CGFloat.ulpOfOne)
    }
}
