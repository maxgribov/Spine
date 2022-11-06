//
//  EventModel.swift
//  Spine
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

public struct EventModel {
    
    let name: String
    let int: Int
    let float: Float
    let string: String?
    let audio: String?
    let volume: Float
    let balance: Float
}

extension EventModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case event, int, float, string, audio, volume, balance
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        self.name = name
        int = try container.decodeIfPresent(Int.self, forKey: .int) ?? 0
        float = try container.decodeIfPresent(Float.self, forKey: .float) ?? 0
        string = try container.decodeIfPresent(String.self, forKey: .string)
        audio = try container.decodeIfPresent(String.self, forKey: .audio)
        volume = try container.decodeIfPresent(Float.self, forKey: .volume) ?? 1
        balance = try container.decodeIfPresent(Float.self, forKey: .balance) ?? 0
    }
}

extension EventModel {
    
    init(with keyframe: EventKeyfarameModel) {
        
        self.name = keyframe.event
        self.int = keyframe.int ?? 0
        self.float = Float(keyframe.float ?? 0)
        self.string = keyframe.string
        self.audio = nil
        self.volume = 1
        self.balance = 0
    }
}
