//
//  BoneKeyframeTranslateModel.swift
//  
//
//  Created by Max Gribov on 11.11.2022.
//

import SpriteKit

struct BoneKeyframeTranslateModel: CurvedKeyframeModel {
    
    let time: TimeInterval
    let position: CGPoint
    var curve: CurveModelType
}

extension BoneKeyframeTranslateModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, x, y, curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        let x = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        let y = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        position = .init(x: x, y: y)
        curve = try container.decodeIfPresent(CurveModelType.self, forKey: .curve) ?? .linear
    }
}
