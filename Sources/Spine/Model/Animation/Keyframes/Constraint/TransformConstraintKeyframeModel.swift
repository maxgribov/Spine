//
//  TransformConstraintKeyframeModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import SpriteKit

struct TransformConstraintKeyframeModel: KeyframeModel {
    
    let time: TimeInterval
    let rotateMix: CGFloat
    let translateMix: CGFloat
    let scaleMix: CGFloat
    let shearMix: CGFloat
}

//TODO: - tests
extension TransformConstraintKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, rotateMix, translateMix, scaleMix, shearMix
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        rotateMix = try container.decodeIfPresent(CGFloat.self, forKey: .rotateMix) ?? 1
        translateMix = try container.decodeIfPresent(CGFloat.self, forKey: .translateMix) ?? 1
        scaleMix = try container.decodeIfPresent(CGFloat.self, forKey: .scaleMix) ?? 1
        shearMix = try container.decodeIfPresent(CGFloat.self, forKey: .shearMix) ?? 1
    }
}
