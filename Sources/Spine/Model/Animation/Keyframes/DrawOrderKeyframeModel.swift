//
//  DrawOrderKeyframeModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct DrawOrderKeyframeModel: KeyframeModel {
    
    let time: TimeInterval
    let offsets: [Offset]
}

//MARK: - Types

extension DrawOrderKeyframeModel {
    
    struct Offset: Decodable, Equatable {
        
        let slot: String
        let offset: Int
    }
}

//MARK: - Decodable

extension DrawOrderKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, offsets
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        offsets = try container.decode([Offset].self, forKey: .offsets)
    }
}
