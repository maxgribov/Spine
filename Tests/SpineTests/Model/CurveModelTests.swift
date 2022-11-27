//
//  CurveModelTests.swift
//  
//
//  Created by Max Gribov on 20.11.2022.
//

import XCTest
@testable import Spine

final class CurveModelTests: XCTestCase {}

//MARK: - Timing Function

extension CurveModelTests {
    
    func testTimingFunction_Linear() throws {
        
        // given
        let curve: CurveModel = .linear
        let timingFunction = curve.timingFunction
        
        // when
        var results = [Float]()
        for time in stride(from: 0, to: 1.2, by: 0.2) {
            
            results.append(timingFunction(Float(time)))
        }
        
        // then
        XCTAssertEqual(results[0], 0, accuracy: .ulpOfOne)
        XCTAssertEqual(results[1], 0.2, accuracy: .ulpOfOne)
        XCTAssertEqual(results[2], 0.4, accuracy: .ulpOfOne)
        XCTAssertEqual(results[3], 0.6, accuracy: .ulpOfOne)
        XCTAssertEqual(results[4], 0.8, accuracy: .ulpOfOne)
        XCTAssertEqual(results[5], 1, accuracy: .ulpOfOne)
    }
    
    func testTimingFunction_Stepped() throws {
        
        // given
        let curve: CurveModel = .stepped
        let timingFunction = curve.timingFunction
        
        // when
        var results = [Float]()
        for time in stride(from: 0, to: 1.2, by: 0.2) {
            
            results.append(timingFunction(Float(time)))
        }
        
        // then
        XCTAssertEqual(results[0], 0, accuracy: .ulpOfOne)
        XCTAssertEqual(results[1], 0, accuracy: .ulpOfOne)
        XCTAssertEqual(results[2], 0, accuracy: .ulpOfOne)
        XCTAssertEqual(results[3], 0, accuracy: .ulpOfOne)
        XCTAssertEqual(results[4], 0, accuracy: .ulpOfOne)
        XCTAssertEqual(results[5], 1, accuracy: .ulpOfOne)
    }
    
    func testTimingFunction_Bezier() throws {
        
        // given
        let curve: CurveModel = .bezier(.init(p0: 0.3, p1: 0, p2: 0.6, p3: 1))
        let timingFunction = curve.timingFunction
        
        // when
        var results = [Float]()
        for time in stride(from: 0, to: 1.2, by: 0.2) {
            
            results.append(timingFunction(Float(time)))
        }
        
        // then
        XCTAssertEqual(results[0], 0, accuracy: .ulpOfOne)
        XCTAssertEqual(results[1], 0.12495855, accuracy: .ulpOfOne)
        XCTAssertEqual(results[2], 0.40346342, accuracy: .ulpOfOne)
        XCTAssertEqual(results[3], 0.7015142, accuracy: .ulpOfOne)
        XCTAssertEqual(results[4], 0.91989845, accuracy: .ulpOfOne)
        XCTAssertEqual(results[5], 1, accuracy: .ulpOfOne)
    }
}

