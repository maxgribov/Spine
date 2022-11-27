//
//  SkeletonModelTests.swift
//  
//
//  Created by Max Gribov on 05.11.2022.
//

import XCTest
@testable import Spine

final class SkeletonModelTests: XCTestCase {

    let decoder = JSONDecoder()
    
    func testDecoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "skeleton", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try decoder.decode(SkeletonModel.self, from: json)
        
        // then
        XCTAssertEqual(result.hash, "SmUDxzck41o")
        XCTAssertEqual(result.spine, "4.1.17")
        XCTAssertEqual(result.position, .init(x: -221.27, y: -8.57))
        XCTAssertEqual(result.size, .init(width: 470.72, height: 731.57))
        XCTAssertEqual(result.fps, 30)
        XCTAssertEqual(result.images, "./images/")
        XCTAssertEqual(result.audio, "")
    }

}
