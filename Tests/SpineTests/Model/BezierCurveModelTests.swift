//
//  BezierCurveModelTests.swift
//  
//
//  Created by Max Gribov on 19.11.2022.
//

import XCTest
@testable import Spine

final class BezierCurveModelTests: XCTestCase {}

//MARK: - Normalized

extension BezierCurveModelTests {
    
    //MARK: Smaple adjusted keyframes
    /*
     [{
             "time": 0,
             "x": 0
         },
         {
             "time": 1,
             "x": 100,
             "curve": [0.333, 0, 0.667, 100, 0.333, 0, 0.667, 0]
         },
         {
             "time": 3,
             "x": -100,
             "curve": [1.667, 100, 2.333, -100, 1.667, 0, 2.333, 0]
         },
         {
             "time": 4,
             "x": 0,
             "curve": [3.333, -100, 3.667, 0, 3.333, 0, 3.667, 0]
         }
     ]
     */
        
    func testNormalized_Keyframe_Two() throws {
       
        // given
        let prevTime: Float = 0
        let currTime: Float = 1
        let prevValue: Float = 0
        let currValue: Float = 100
        let curve = BezierCurveModel(p0: 0.333, p1: 0, p2: 0.667, p3: 100)
        
        // when
        let result = curve.normalazed(timeStart: prevTime, timeEnd: currTime, valueStart: prevValue, valueEnd: currValue)
        
        // then
        XCTAssertEqual(result.p0, 0.333, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p1, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p2, 0.667, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p3, 1, accuracy: .ulpOfOne)
    }
    
    func testNormalized_Keyframe_Three() throws {
       
        // given
        let prevTime: Float = 1
        let currTime: Float = 3
        let prevValue: Float = 100
        let currValue: Float = -100
        let curve = BezierCurveModel(p0: 1.667, p1: 100, p2: 2.333, p3: -100)
        
        // when
        let result = curve.normalazed(timeStart: prevTime, timeEnd: currTime, valueStart: prevValue, valueEnd: currValue)
        
        // then
        XCTAssertEqual(result.p0, 0.334, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p1, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p2, 0.667, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p3, 1, accuracy: .ulpOfOne)
    }
    
    func testNormalized_Keyframe_Four() throws {
       
        // given
        let prevTime: Float = 3
        let currTime: Float = 4
        let prevValue: Float = -100
        let currValue: Float = 0
        let curve = BezierCurveModel(p0: 3.333, p1: -100, p2: 3.667, p3: 0)
        
        // when
        let result = curve.normalazed(timeStart: prevTime, timeEnd: currTime, valueStart: prevValue, valueEnd: currValue)
        
        // then
        XCTAssertEqual(result.p0, 0.333, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p1, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p2, 0.667, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p3, 1, accuracy: .ulpOfOne)
    }
}

//MARK: - Extreme Bezier

extension BezierCurveModelTests {
    
    func testNormalized_Extreme() throws {
       
        // given
        let prevTime: Float = 0
        let currTime: Float = 1
        let prevValue: Float = 0
        let currValue: Float = 100
        let curve = BezierCurveModel(p0: 0.333, p1: 0, p2: 1, p3: -200)
        
        // when
        let result = curve.normalazed(timeStart: prevTime, timeEnd: currTime, valueStart: prevValue, valueEnd: currValue)
        
        // then
        XCTAssertEqual(result.p0, 0.333, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p1, 0, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p2, 1, accuracy: .ulpOfOne)
        XCTAssertEqual(result.p3, -2, accuracy: .ulpOfOne)
    }
}
