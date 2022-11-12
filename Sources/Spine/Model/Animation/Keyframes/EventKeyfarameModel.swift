//
//  EventKeyfarameModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import SpriteKit

struct EventKeyfarameModel: KeyframeModel, AnimationGroupModel {
    
    let time: TimeInterval
    let event: String
    let int: Int?
    let float: CGFloat?
    let string: String?
    let volume: Float?
    let balance: Float?
}

extension EventKeyfarameModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, int, float, string, volume, balance
        case event = "name"
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        event = try container.decode(String.self, forKey: .event)
        int = try container.decodeIfPresent(Int.self, forKey: .int)
        float = try container.decodeIfPresent(CGFloat.self, forKey: .float)
        string = try container.decodeIfPresent(String.self, forKey: .string)
        volume = try container.decodeIfPresent(Float.self, forKey: .volume)
        balance = try container.decodeIfPresent(Float.self, forKey: .balance)
    }
}
