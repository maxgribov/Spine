//
//  IKConstraintModel.swift
//  
//
//  Created by Max Gribov on 05.11.2022.
//

import SpriteKit

///This section describes the IK constraints
struct IKConstraintModel {
    
    ///The constraint name. This is unique for the skeleton.
    let name: String
    ///The ordinal for the order constraints are applied.
    let order: UInt
    ///If true, the constraint is only applied when the active skin has the constraint. Assume false if omitted.
    let skin: Bool
    ///A list of 1 or 2 bone names whose rotation will be controlled by the constraint.
    let bones: [BoneModel.ID]
    ///The name of the target bone.
    let target: BoneModel.ID
    ///A value from 0 to 1 indicating the influence the constraint has on the bones, where 0 means only FK, 1 means only IK, and between is a mix of FK and IK. Assume 1 if omitted.
    let mix: CGFloat
    ///A value for two bone IK, the distance from the maximum reach of the bones that rotation will slow. Assume 0 if omitted.
    let softness: CGFloat
    ///If true, the bones will bend in the positive rotation direction. Assume false if omitted.
    let blendPositive: Bool
    ///If true, and only a single bone is being constrained, if the target is too close, the bone is scaled to reach it. Assume false if omitted.
    let compress: Bool
    ///If true, and if the target is out of range, the parent bone is scaled to reach it. If more than one bone is being constrained and the parent bone has local nonuniform scale, stretch is not applied. Assume false if omitted.
    let stretch: Bool
    ///If true, and only a single bone is being constrained, and compress or stretch is used, the bone is scaled on both the X and Y axes. Assume false if omitted.
    let uniform: Bool
}

//MARK: - Decodable

extension IKConstraintModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case name, order, skin, bones, target, mix, softness, bendPositive, compress, stretch, uniform
    }
    
    //TODO: - Tests
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        name = try container.decode(String.self, forKey: .name)
        order = try container.decode(UInt.self, forKey: .order)
        skin = try container.decodeIfPresent(Bool.self, forKey: .skin) ?? false
        bones = try container.decode([BoneModel.ID].self, forKey: .bones)
        target = try container.decode(BoneModel.ID.self, forKey: .target)
        mix = try container.decodeIfPresent(CGFloat.self, forKey: .mix) ?? 1.0
        softness = try container.decodeIfPresent(CGFloat.self, forKey: .softness) ?? 0
        blendPositive = try container.decodeIfPresent(Bool.self, forKey: .bendPositive) ?? false
        compress = try container.decodeIfPresent(Bool.self, forKey: .compress) ?? false
        stretch = try container.decodeIfPresent(Bool.self, forKey: .stretch) ?? false
        uniform = try container.decodeIfPresent(Bool.self, forKey: .uniform) ?? false
    }
}
