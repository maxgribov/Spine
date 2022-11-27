//
//  PathConstraintModel.swift
//  
//
//  Created by Max Gribov on 05.11.2022.
//

import SpriteKit

///This section describes the path constraints.
struct PathConstraintModel {
    
    ///The constraint name. This is unique for the skeleton.
    let name: String
    ///The ordinal for the order constraints are applied.
    let order: UInt
    ///The bones whose rotation and/or translation will be controlled by the constraint.
    let bones: [BoneModel.ID]
    ///The name of the target slot.
    let target: BoneModel.ID
    ///Determines how the path position is calculated: fixed or percent. Assume percent if omitted.
    let positionMode: PositionMode
    ///Determines how the spacing between bones is calculated: length, fixed, or percent. Assume length if omitted.
    let spacingMode: SpacingMode
    ///Determines how the bone rotation is calculated: tangent, chain, or chain scale. Assume tangent if omitted.
    let rotateMode: RotateMode
    ///The rotation to offset from the path rotation. Assume 0 if omitted.
    let rotation: CGFloat
    ///The path position. Assume 0 if omitted.
    let position: CGFloat
    ///The spacing between bones. Assume 0 if omitted.
    let spacing: CGFloat
    ///A value from 0 to 1 indicating the influence the constraint has on the bones, where 0 means no affect, 1 means only the constraint, and between is a mix of the normal pose and the constraint. Assume 1 if omitted.
    let rotateMix: CGFloat
    // See rotateMix.
    let translateMix: CGFloat
}

//MARK: - Types

extension PathConstraintModel {
    
    enum PositionMode: String, Decodable {
        
        case fixed
        case percent
    }
    
    enum SpacingMode: String, Decodable {
        
        case length
        case fixed
        case percent
    }
    
    enum RotateMode: String, Decodable {
        
        case tangent
        case chain
        case chainScale
    }
}

//MARK: - Decodable

extension PathConstraintModel: Decodable {
    
    enum PathConstraintModelKeys: String, CodingKey {
        
        case name, order, bones, target, positionMode, spacingMode, rotateMode
        case rotation, position, spacing, rotateMix, translateMix
    }
    
    //TODO: - Tests
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: PathConstraintModelKeys.self)
        name = try container.decode(String.self, forKey: .name)
        order = try container.decode(UInt.self, forKey: .order)
        bones = try container.decode([BoneModel.ID].self, forKey: .bones)
        target = try container.decode(BoneModel.ID.self, forKey: .target)
        positionMode = try container.decodeIfPresent(PositionMode.self, forKey: .positionMode) ?? .percent
        spacingMode = try container.decodeIfPresent(SpacingMode.self, forKey: .spacingMode) ?? .length
        rotateMode = try container.decodeIfPresent(RotateMode.self, forKey: .rotateMode) ?? .tangent
        rotation = try container.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        position = try container.decodeIfPresent(CGFloat.self, forKey: .position) ?? 0
        spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing) ?? 0
        rotateMix = try container.decodeIfPresent(CGFloat.self, forKey: .rotateMix) ?? 1.0
        translateMix = try container.decodeIfPresent(CGFloat.self, forKey: .translateMix) ?? 1.0
    }
}
