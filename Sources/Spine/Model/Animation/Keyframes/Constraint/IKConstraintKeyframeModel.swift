//
//  IKConstraintKeyframeModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import SpriteKit

//MARK: - [Spine Pro]
struct IKConstraintKeyframeModel: KeyframeModel {
    
    let time: TimeInterval
    let mix: CGFloat
    let isBlendPositive: Bool
}

//TODO: - tests
extension IKConstraintKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, mix
        case blendPositive = "blendPositive"
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        mix = try container.decodeIfPresent(CGFloat.self, forKey: .mix) ?? 1.0
        isBlendPositive = try container.decodeIfPresent(Bool.self, forKey: .blendPositive) ?? false
    }
}
