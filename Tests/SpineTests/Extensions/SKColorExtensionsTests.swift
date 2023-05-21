//
//  SKColorExtensionsTests.swift
//  
//
//  Created by Max Gribov on 28.04.2023.
//

import XCTest
@testable import Spine
import SpriteKit

final class SKColorExtensionsTests: XCTestCase {

    func test_updated_index_0() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(channel: 1, index: 0)
        
        // then
        XCTAssertEqual(reult, Self.red)
    }
    
    func test_updated_index_1() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(channel: 1, index: 1)
        
        // then
        XCTAssertEqual(reult, Self.green)
    }
    
    func test_updated_index_2() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(channel: 1, index: 2)
        
        // then
        XCTAssertEqual(reult, Self.blue)
    }
    
    func test_updated_index_3() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(channel: 0, index: 3)
        
        // then
        XCTAssertEqual(reult, Self.clear)
    }
    
    func test_updated_index_4() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(channel: 0, index: 4)
        
        // then
        XCTAssertEqual(reult, Self.black)
    }
    
    func test_updated_index_minus1() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(channel: 0, index: -1)
        
        // then
        XCTAssertEqual(reult, Self.black)
    }
    
    func test_updated_red() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(red: 1)
        
        // then
        XCTAssertEqual(reult, Self.red)
    }
    
    func test_updated_green() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(green: 1)
        
        // then
        XCTAssertEqual(reult, Self.green)
    }
    
    func test_updated_blue() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(blue: 1)
        
        // then
        XCTAssertEqual(reult, Self.blue)
    }

    func test_updated_alpha() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.updated(alpha: 0)
        
        // then
        XCTAssertEqual(reult, Self.clear)
    }
    
    func test_updated_rgba() throws {

        // given
        let sut = makeSut()
        
        // when
        let reult = sut.rgba
        
        // then
        XCTAssertEqual(reult.red, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(reult.green, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(reult.blue, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(reult.alpha, 1, accuracy: .ulpOfOne)
    }
}

private extension SKColorExtensionsTests {
    
    func makeSut() -> SKColor { Self.black }
    
    static let clear = SKColor(red: 0, green: 0, blue: 0, alpha: 0)
    static let white = SKColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let black = SKColor(red: 0, green: 0, blue: 0, alpha: 1)
    static let red = SKColor(red: 1, green: 0, blue: 0, alpha: 1)
    static let green = SKColor(red: 0, green: 1, blue: 0, alpha: 1)
    static let blue = SKColor(red: 0, green: 0, blue: 1, alpha: 1)
}
