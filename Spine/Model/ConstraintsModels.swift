//
//  ConstraintsModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

struct IKConstraintModel {
    
    let name: String
    let order: UInt
    let bones: [String]
    let target: String
    let mix: CGFloat
    let blendPositive: Bool
    
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

struct TransformConstraintModel {
    
    let name: String
    let order: UInt
    let bone: String
    let target: String
    let rotation: CGFloat
    let offset: CGVector
    let scale: CGVector
    let shear: CGVector
    let rotateMix: CGFloat
    let translateMix: CGFloat
    let scaleMix: CGFloat
    let shearMix: CGFloat
    let local: Bool
    let relative: Bool
    
    init(_ name: String, _ order: UInt, _ bone: String, _ target: String, _ rotation: CGFloat?, _ x: CGFloat?, _ y: CGFloat?, _ scaleX: CGFloat?, _ scaleY: CGFloat?, _ shearY: CGFloat?, _ rotateMix: CGFloat?, _ translateMix: CGFloat?, _ scaleMix: CGFloat?, _ shearMix: CGFloat?, _ local: Bool?, _ relative: Bool?) {
        
        self.name = name
        self.order = order
        self.bone = bone
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
        case bone
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
        let bone: String = try container.decode(String.self, forKey: .bone)
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
        
        self.init(name, order, bone, target, rotation, x, y, scaleX, scaleY, shearY, rotateMix, translateMix, scaleMix, shearMix, local, relative)
    }
}

struct PathConstraintModel {
    
    let name: String
    let order: UInt
    let bones: [String]
    let target: String
    let positionMode: PathPositionModelMode
    let spacingMode: PathSpacingModelMode
    let rotateMode: PathRotateModelMode
    let rotation: CGFloat
    let position: CGFloat
    let spacing: CGFloat
    let rotateMix: CGFloat
    let translateMix: CGFloat
    
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
        case chainScale = "chain scale"
        
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
