//
//  TransformConstraintModel.swift
//  
//
//  Created by Max Gribov on 05.11.2022.
//

import SpriteKit

///This section describes the transform constraints.
struct TransformConstraintModel {
    
    ///The constraint name. This is unique for the skeleton.
    let name: String
    ///The ordinal for the order constraints are applied.
    let order: UInt
    ///The bone whose transform will be controlled by the constraint.
    let bones: [BoneModel.ID]
    ///The name of the target bone.
    let target: BoneModel.ID
    ///The rotation to offset from the target bone. Assume 0 if omitted.
    let rotation: CGFloat
    /**
     The distance to offset from the target bone.
     
     - dx: The X distance to offset from the target bone. Assume 0 if omitted.
     - dy: The Y distance to offset from the target bone. Assume 0 if omitted.
     */
    let offset: CGVector
    /**
     The scale to offset from the target bone.
     
     - dx: The X scale to offset from the target bone. Assume 0 if omitted.
     - dy: The Y scale to offset from the target bone. Assume 0 if omitted.
     */
    let scale: CGVector
    ///The Y shear to offset from the target bone. Assume 0 if omitted.
    let shear: CGVector
    ///A value from 0 to 1 indicating the influence the constraint has on the bones, where 0 means no affect, 1 means only the constraint, and between is a mix of the normal pose and the constraint. Assume 1 if omitted.
    let rotateMix: CGFloat
    ///See rotateMix.
    let translateMix: CGFloat
    ///See rotateMix.
    let scaleMix: CGFloat
    ///See rotateMix.
    let shearMix: CGFloat
    ///True if the target's local transform is affected, else the world transform is affected. Assume false if omitted.
    let local: Bool
    ///True if the target's transform is adjusted relatively, else the transform is set absolutely. Assume false if omitted.
    let relative: Bool
}

//MARK: - Decodable

extension TransformConstraintModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case name, order, bones, target, rotation, x, y
        case scaleX, scaleY, shearY
        case rotateMix, translateMix, scaleMix, shearMix
        case local, relative
    }
    
    //TODO: - Tests
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        name = try container.decode(String.self, forKey: .name)
        order = try container.decode(UInt.self, forKey: .order)
        bones = try container.decode([BoneModel.ID].self, forKey: .bones)
        target = try container.decode(BoneModel.ID.self, forKey: .target)
        rotation = try container.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        let dx = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        let dy = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        offset = .init(dx: dx, dy: dy)
        let scaleX = try container.decodeIfPresent(CGFloat.self, forKey: .scaleX) ?? 0
        let scaleY = try container.decodeIfPresent(CGFloat.self, forKey: .scaleY) ?? 0
        scale = .init(dx: scaleX, dy: scaleY)
        let shearY = try container.decodeIfPresent(CGFloat.self, forKey: .shearY) ?? 0
        shear = .init(dx: 0, dy: shearY)
        rotateMix = try container.decodeIfPresent(CGFloat.self, forKey: .rotateMix) ?? 0
        translateMix = try container.decodeIfPresent(CGFloat.self, forKey: .translateMix) ?? 0
        scaleMix = try container.decodeIfPresent(CGFloat.self, forKey: .scaleMix) ?? 0
        shearMix = try container.decodeIfPresent(CGFloat.self, forKey: .shearMix) ?? 0
        local = try container.decodeIfPresent(Bool.self, forKey: .local) ?? false
        relative = try container.decodeIfPresent(Bool.self, forKey: .relative) ?? false
    }
}
