//
//  ConstraintsModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit



///This section describes the path constraints.
struct PathConstraintModel {
    
    ///The constraint name. This is unique for the skeleton.
    let name: String
    ///The ordinal for the order constraints are applied.
    let order: UInt
    ///The bones whose rotation and/or translation will be controlled by the constraint.
    let bones: [String]
    ///The name of the target slot.
    let target: String
    ///Determines how the path position is calculated: fixed or percent. Assume percent if omitted.
    let positionMode: PathPositionModelMode
    ///Determines how the spacing between bones is calculated: length, fixed, or percent. Assume length if omitted.
    let spacingMode: PathSpacingModelMode
    ///Determines how the bone rotation is calculated: tangent, chain, or chain scale. Assume tangent if omitted.
    let rotateMode: PathRotateModelMode
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
    
    /**
     Initializes a new PathConstraintModel.
     
     - Parameters:
         - name: Required
         - order: Required
         - bones: Required
         - target: Required
         - positionMode: Optional, default: precent
         - spacingMode: Optional, default: length
         - rotateMode: Optional, default: tangent
         - rotation: Optional, default: 0
         - position: Optional, default: 0
         - spacing: Optional, default: 0
         - rotateMix: Optional, default: 1
         - translateMix: Optional, default: 1

     - Returns: new PathConstraintModel.
     */
    init(_ name: String, _ order: UInt, _ bones: [String], _ target: String, _ positionMode: String?, _ spacingMode: String?, _ rotateMode: String?, _ rotation: CGFloat?, _ position: CGFloat?, _ spacing: CGFloat?, _ rotateMix: CGFloat?, _ translateMix: CGFloat? ) {
        
        self.name = name
        self.order = order
        self.bones = bones
        self.target = target
        self.positionMode = PathPositionModelMode(positionMode ?? "percent")
        self.spacingMode = PathSpacingModelMode(spacingMode ?? "length")
        self.rotateMode = PathRotateModelMode(rotateMode ?? "tangent")
        self.rotation = rotation ?? 0
        self.position = position ?? 0
        self.spacing = spacing ?? 0
        self.rotateMix = rotateMix ?? 1.0
        self.translateMix = translateMix ?? 1.0
    }
    
    enum PathPositionModelMode: String {
        
        case fixed
        case percent
        
        init(_ positionMode: String) {
            
            if let positionMode = PathPositionModelMode(rawValue: positionMode) {
                
                self = positionMode
                
            } else {
                
                self = .percent
            }
        }
    }
    
    enum PathSpacingModelMode: String {
        
        case length
        case fixed
        case percent
        
        init(_ spacingMode: String) {
            
            if let spacingMode = PathSpacingModelMode(rawValue: spacingMode) {
                
                self = spacingMode
                
            } else {
                
                self = .length
            }
        }
    }
    
    enum PathRotateModelMode: String {
        
        case tangent
        case chain
        case chainScale
        
        init(_ rotateMode: String) {
            
            if let rotateMode = PathRotateModelMode(rawValue: rotateMode) {
                
                self = rotateMode
                
            } else {
                
                self = .tangent
            }
        }
    }
}

extension PathConstraintModel: Decodable {
    
    enum PathConstraintModelKeys: String, CodingKey {
        case name
        case order
        case bones
        case target
        case positionMode
        case spacingMode
        case rotateMode
        case rotation
        case position
        case spacing
        case rotateMix
        case translateMix
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: PathConstraintModelKeys.self)
        let name: String = try container.decode(String.self, forKey: .name)
        let order: UInt = try container.decode(UInt.self, forKey: .order)
        let bones: [String] = try container.decode([String].self, forKey: .bones)
        let target: String = try container.decode(String.self, forKey: .target)
        let positionMode: String? = try container.decodeIfPresent(String.self, forKey: .positionMode)
        let spacingMode: String? = try container.decodeIfPresent(String.self, forKey: .spacingMode)
        let rotateMode: String? = try container.decodeIfPresent(String.self, forKey: .rotateMode)
        let rotation: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotation)
        let position: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .position)
        let spacing: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
        let rotateMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotateMix)
        let translateMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .translateMix)
        
        self.init(name, order, bones, target, positionMode, spacingMode, rotateMode, rotation, position, spacing, rotateMix, translateMix)
    }
}
