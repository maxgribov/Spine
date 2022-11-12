//
//  SlotKeyframeColorModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct SlotKeyframeColorModel: CurvedKeyframeModel {
    
    let time: TimeInterval
    let color: ColorModel
    var curve: CurveModelType
}

extension SlotKeyframeColorModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, color, curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        color = try container.decode(ColorModel.self, forKey: .color)
        curve = try container.decodeIfPresent(CurveModelType.self, forKey: .curve) ?? .linear
    }
}
