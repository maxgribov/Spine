//
//  DeformKeyframeModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import SpriteKit

//MARK: - [Spine Pro]
struct DeformKeyframeModel: KeyframeModel {
    
    let time: TimeInterval
    let offset: Int
    let vertices: [CGFloat]
    let curve: CurveModel
}

//TODO: - Tests
extension DeformKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, offset, vertices, curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        offset = try container.decodeIfPresent(Int.self, forKey: .offset) ?? 0
        vertices = try container.decode([CGFloat].self, forKey: .vertices)
        curve = try container.decodeIfPresent(CurveModel.self, forKey: .curve) ?? .linear
    }
}
