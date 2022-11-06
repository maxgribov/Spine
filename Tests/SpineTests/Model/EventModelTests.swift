//
//  EventModelTests.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import XCTest
@testable import Spine

final class EventModelTests: XCTestCase {

    func testDecoding() throws {
        
        // given
        guard let url = Bundle.module.url(forResource: "events", withExtension: "json") else {
            XCTFail()
            return
        }
        
        let json = try Data(contentsOf: url)
        
        // when
        let result = try JSONDecoder().decode(Events.self, from: json)
        
        // then
        XCTAssertEqual(result.events.count, 2)
        
        guard let eventFirst = result.events.first(where: { $0.name == "footsteps" }) else {
            XCTFail()
            return
        }
        XCTAssertEqual(eventFirst.int, 1)
        XCTAssertEqual(eventFirst.float, 2)
        XCTAssertEqual(eventFirst.string, "three")
        
        guard let eventSecond = result.events.first(where: { $0.name == "action" }) else {
            XCTFail()
            return
        }
        XCTAssertEqual(eventSecond.audio, "hit.wav")
        XCTAssertEqual(eventSecond.volume, 0.9, accuracy: .ulpOfOne)
        XCTAssertEqual(eventSecond.balance, -0.25, accuracy: .ulpOfOne)
    }
}

private struct Events {
    
    let events: [EventModel]
}

extension Events: Decodable {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: SpineNameKey.self)

        var events = [EventModel]()
        
        for eventName in container.allKeys {
            
            let eventContainer = try container.nestedContainer(keyedBy: EventModel.KeysType.self, forKey: eventName)
            let event = try EventModel(eventName.stringValue, eventContainer)
            events.append(event)
        }

        self.events = events
    }
}
