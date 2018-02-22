//
//  ConstraintsModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

///This section describes the IK constraints
struct IKConstraintModel {
    
    ///The constraint name. This is unique for the skeleton.
    let name: String
    ///The ordinal for the order constraints are applied.
    let order: UInt
    ///A list of 1 or 2 bone names whose rotation will be controlled by the constraint.
    let bones: [String]
    ///The name of the target bone.
    let target: String
    ///A value from 0 to 1 indicating the influence the constraint has on the bones, where 0 means only FK, 1 means only IK, and between is a mix of FK and IK. Assume 1 if omitted.
    let mix: CGFloat
    ///If true, the bones will bend in the positive rotation direction. Assume false if omitted.
    let blendPositive: Bool
    
    /**
     Initializes a new IKConstraintModel.
     
     - Parameters:
         - name: Required
         - order: Required
         - bones: Required
         - target: Required
         - mix: Optional, default: 1.0
         - blendPositive: Optional, default false
     
     - Returns: new IKConstraintModel.
     */
    init(_ name: String, _ order: UInt, _ bones: [String], _ target: String, _ mix: CGFloat?, _ blendPositive: Bool?) {
        
        self.name = name
        self.order = order
        self.bones = bones
        self.target = target
        self.mix = mix ?? 1.0
        self.blendPositive = blendPositive ?? false
    }
}

extension IKConstraintModel: Decodable {
    
    enum IKConstraintModelKeys: String, CodingKey {
        
        case name
        case order
        case bones
        case target
        case mix
        case bendPositive
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: IKConstraintModelKeys.self)
        let name: String = try container.decode(String.self, forKey: .name)
        let order: UInt = try container.decode(UInt.self, forKey: .order)
        let bones: [String] = try container.decode([String].self, forKey: .bones)
        let target: String = try container.decode(String.self, forKey: .target)
        let mix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .mix)
        let blendPositive: Bool? = try container.decodeIfPresent(Bool.self, forKey: .bendPositive)
        
        self.init(name, order, bones, target, mix, blendPositive)
    }
}

///This section describes the transform constraints.
struct TransformConstraintModel {
    
    ///The constraint name. This is unique for the skeleton.
    let name: String
    ///The ordinal for the order constraints are applied.
    let order: UInt
    ///The bone whose transform will be controlled by the constraint.
    let bones: [String]
    ///The name of the target bone.
    let target: String
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
    
    /**
     Initializes a new TransformConstraintModel.
     
     - Parameters:
        - name: Required
        - order: Required
        - bone: Required
        - target: Required
        - rotation: Optional, default: 0
        - x: Optional, default: 0
        - y: Optional, default: 0
        - scaleX: Optional, default: 0
        - scaleY: Optional, default: 0
        - shearY: Optional, default: 0
        - rotateMix: Optional, default: 1.0
        - translateMix: Optional, default: 1.0
        - scaleMix: Optional, default: 1.0
        - shearMix: Optional, default: 1.0
        - local: Optional, default: false
        - relative: Optional, default: false

     - Returns: new TransformConstraintModel.
     */
    init(_ name: String, _ order: UInt, _ bones: [String], _ target: String, _ rotation: CGFloat?, _ x: CGFloat?, _ y: CGFloat?, _ scaleX: CGFloat?, _ scaleY: CGFloat?, _ shearY: CGFloat?, _ rotateMix: CGFloat?, _ translateMix: CGFloat?, _ scaleMix: CGFloat?, _ shearMix: CGFloat?, _ local: Bool?, _ relative: Bool?) {
        
        self.name = name
        self.order = order
        self.bones = bones
        self.target = target
        self.rotation = rotation ?? 0
        self.offset = CGVector(dx: x ?? 0, dy: y ?? 0)
        self.scale = CGVector(dx: scaleX ?? 0, dy: scaleY ?? 0)
        self.shear = CGVector(dx: 0, dy: shearY ?? 0)
        self.rotateMix = rotateMix ?? 1.0
        self.translateMix = translateMix ?? 1.0
        self.scaleMix = scaleMix ?? 1.0
        self.shearMix = shearMix ?? 1.0
        self.local = local ?? false
        self.relative = relative ?? false
    }
}

extension TransformConstraintModel: Decodable {
    
    enum TransformConstraintModelKeys: String, CodingKey {
        
        case name
        case order
        case bones
        case target
        case rotation
        case x
        case y
        case scaleX
        case scaleY
        case shearY
        case rotateMix
        case translateMix
        case scaleMix
        case shearMix
        case local
        case relative
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: TransformConstraintModelKeys.self)
        let name: String = try container.decode(String.self, forKey: .name)
        let order: UInt = try container.decode(UInt.self, forKey: .order)
        let bones: [String] = try container.decode([String].self, forKey: .bones)
        let target: String = try container.decode(String.self, forKey: .target)
        let rotation: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotation)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        let scaleX: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleX)
        let scaleY: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleY)
        let shearY: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .shearY)
        let rotateMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotateMix)
        let translateMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .translateMix)
        let scaleMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleMix)
        let shearMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .shearMix)
        let local: Bool? = try container.decodeIfPresent(Bool.self, forKey: .local)
        let relative: Bool? = try container.decodeIfPresent(Bool.self, forKey: .relative)
        
        self.init(name, order, bones, target, rotation, x, y, scaleX, scaleY, shearY, rotateMix, translateMix, scaleMix, shearMix, local, relative)
    }
}

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
