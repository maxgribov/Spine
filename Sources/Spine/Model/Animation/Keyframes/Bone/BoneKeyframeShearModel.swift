//
//  BoneKeyframeShearModel.swift
//  
//
//  Created by Max Gribov on 11.11.2022.
//

import Foundation

struct BoneKeyframeShearModel: CurvedKeyframeModel {
    
    let time: TimeInterval
    let shear: CGVector
    var curve: CurveModel
    
    var values: [Float] { [Float(shear.dx), Float(shear.dy)] }
}

extension BoneKeyframeShearModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, x, y, curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        let dx = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        let dy = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        shear = .init(dx: dx, dy: dy)
        curve = try container.decodeIfPresent(CurveModel.self, forKey: .curve) ?? .linear
    }
}
