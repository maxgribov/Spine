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
    
    init(_ name: String, _ order: UInt, _ bones: [String], _ target: String, _ mix: CGFloat = 1.0, _ blendPositive: Bool = false) {
        self.name = name
        self.order = order
        self.bones = bones
        self.target = target
        self.mix = mix
        self.blendPositive = blendPositive
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
    
    init(_ name: String, _ order: UInt, _ bone: String, _ target: String, _ rotation: CGFloat = 0, _ x: CGFloat = 0, _ y: CGFloat = 0, _ scaleX: CGFloat = 0, _ scaleY: CGFloat = 0, _ shearY: CGFloat = 0, _ rotateMix: CGFloat = 1.0, _ translateMix: CGFloat = 1.0, _ scaleMix: CGFloat = 1.0, _ shearMix: CGFloat = 0, _ local: Bool = false, _ relative: Bool = false) {
        
        self.name = name
        self.order = order
        self.bone = bone
        self.target = target
        self.rotation = rotation
        self.offset = CGVector(dx: x, dy: y)
        self.scale = CGVector(dx: scaleX, dy: scaleY)
        self.shear = CGVector(dx: 0, dy: shearY)
        self.rotateMix = rotateMix
        self.translateMix = translateMix
        self.scaleMix = scaleMix
        self.shearMix = shearMix
        self.local = local
        self.relative = relative
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
    
    init(_ name: String, _ order: UInt, _ bones: [String], _ target: String, _ positionMode: Int = 1, _ spacingMode: Int = 0, _ rotateMode: Int = 0, _ rotation: CGFloat = 0, _ position: CGFloat = 0, _ spacing: CGFloat = 0, _ rotateMix: CGFloat = 1.0, _ translateMix: CGFloat = 1.0 ) {
        
        self.name = name
        self.order = order
        self.bones = bones
        self.target = target
        self.positionMode = PathPositionModelMode(positionMode)
        self.spacingMode = PathSpacingModelMode(spacingMode)
        self.rotateMode = PathRotateModelMode(rotateMode)
        self.rotation = rotation
        self.position = position
        self.spacing = spacing
        self.rotateMix = rotateMix
        self.translateMix = translateMix
    }
}
