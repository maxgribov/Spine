//
//  BoneKeyframeRotateModel.swift
//  
//
//  Created by Max Gribov on 11.11.2022.
//

import SpriteKit

struct BoneKeyframeRotateModel: BoneKeyframeModel {
    
    let time: TimeInterval
    let angle: CGFloat
    var curve: CurveModelType
}

extension BoneKeyframeRotateModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, curve
        case angle = "value"
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        angle = try container.decodeIfPresent(CGFloat.self, forKey: .angle) ?? 0
        curve = try container.decodeIfPresent(CurveModelType.self, forKey: .curve) ?? .linear
    }
}
