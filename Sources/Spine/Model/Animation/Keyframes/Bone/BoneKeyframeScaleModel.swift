//
//  BoneKeyframeScaleModel.swift
//  
//
//  Created by Max Gribov on 11.11.2022.
//

import SpriteKit

struct BoneKeyframeScaleModel: CurvedKeyframeModel {
    
    let time: TimeInterval
    let scale: CGVector
    var curve: CurveModel
    
    var values: [Float] { [Float(scale.dx), Float(scale.dy)]}
}

extension BoneKeyframeScaleModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, x, y, curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        let dx = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 1
        let dy = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 1
        scale = .init(dx: dx, dy: dy)
        curve = try container.decodeIfPresent(CurveModel.self, forKey: .curve) ?? .linear
    }
}
