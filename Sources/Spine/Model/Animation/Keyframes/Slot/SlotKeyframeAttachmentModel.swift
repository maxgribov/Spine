//
//  SlotKeyframeAttachmentModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct SlotKeyframeAttachmentModel: KeyframeModel {
    
    let time: TimeInterval
    let name: String?
}

extension SlotKeyframeAttachmentModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case name
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }
}
