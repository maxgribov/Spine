//
//  KeyframeModelTests.swift
//  
//
//  Created by Max Gribov on 19.11.2022.
//

import XCTest
@testable import Spine

final class KeyframeModelTests: XCTestCase {}

//MARK: - Adjusted Curves

extension KeyframeModelTests {
    
    func testAdjustedCurves_SingleValue() throws {
        
        // given
        let keyframes: [SingleValueKeyframe] =
        [.init(time: 0, value: 0, curve: .bezier(.init(p0: 0.333, p1: 0, p2: 0.667, p3: 100))),
         .init(time: 1, value: 100, curve: .bezier(.init(p0: 1.667, p1: 100, p2: 2.333, p3: -100))),
         .init(time: 3, value: -100, curve: .bezier(.init(p0: 3.333, p1: -100, p2: 3.667, p3: 0))),
         .init(time: 4, value: 0, curve: .linear)]
        
        let expected: [SingleValueKeyframe] =
        [.init(time: 0, value: 0, curve: .linear),
         .init(time: 1, value: 100, curve: .bezier(.init(p0: 0.333, p1: 0, p2: 0.667, p3: 1))),
         .init(time: 3, value: -100, curve: .bezier(.init(p0: 0.334, p1: 0, p2: 0.667, p3: 1))),
         .init(time: 4, value: 0, curve: .bezier(.init(p0: 0.333, p1: 0, p2: 0.667, p3: 1)))]
        
        // when
        let result = try adjustedCurves(keyframes)
        
        //then
        XCTAssertEqual(result, expected)
    }
    
    func testAdjustedCurves_DoubleValue() throws {
        
        // given
        let keyframes: [DoubleValueKeyframe] =
        [.init(time: 0, valueOne: 0, valueTwo: 0, curve: .bezier2(.init(p0: 0.333, p1: 0, p2: 0.667, p3: 100),
                                                                  .init(p0: 0.333, p1: 0, p2: 0.667, p3: 0))),
         .init(time: 1, valueOne: 100, valueTwo: 0, curve: .bezier2(.init(p0: 1.667, p1: 100, p2: 2.333, p3: -100),
                                                                    .init(p0: 1.667, p1: 0, p2: 2.333, p3: 0))),
         .init(time: 3, valueOne: -100, valueTwo: 0, curve: .bezier2(.init(p0: 3.333, p1: -100, p2: 3.667, p3: 0),
                                                                     .init(p0: 3.333, p1: 0, p2: 3.667, p3: 0))),
         .init(time: 4, valueOne: 0, valueTwo: 0, curve: .linear)]
        
        let expected: [DoubleValueKeyframe] =
        [.init(time: 0, valueOne: 0, valueTwo: 0, curve: .linear),
         .init(time: 1, valueOne: 100, valueTwo: 0, curve: .bezier2(.init(p0: 0.333, p1: 0, p2: 0.667, p3: 1),
                                                                    .init(p0: 0.333, p1: 0, p2: 0.667, p3: 0))),
         .init(time: 3, valueOne: -100, valueTwo: 0, curve: .bezier2(.init(p0: 0.334, p1: 0, p2: 0.667, p3: 1),
                                                                     .init(p0: 0.334, p1: 0, p2: 0.667, p3: 0))),
         .init(time: 4, valueOne: 0, valueTwo: 0, curve: .bezier2(.init(p0: 0.333, p1: 0, p2: 0.667, p3: 1),
                                                                  .init(p0: 0.333, p1: 0, p2: 0.667, p3: 0)))]
        
        // when
        let result = try adjustedCurves(keyframes)
        
        //then
        XCTAssertEqual(result, expected)
    }
}

fileprivate struct SingleValueKeyframe: CurvedKeyframeModel, Equatable {

    let time: TimeInterval
    let value: Float
    var curve: CurveModel
    
    var values: [Float] { [value] }
}

fileprivate struct DoubleValueKeyframe: CurvedKeyframeModel, Equatable {

    let time: TimeInterval
    let valueOne: Float
    let valueTwo: Float
    var curve: CurveModel
    
    var values: [Float] { [valueOne, valueTwo] }
}

