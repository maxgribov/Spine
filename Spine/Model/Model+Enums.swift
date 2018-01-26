//
//  Model+Enums.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

//MARK: - Skeleton

enum BoneTransformModelType: Int {
    
    case normal = 0
    case onlyTranslation
    case noRotationOrReflection
    case noScale
    case noScaleOrReflection
    
    init(_ transform: Int ) {
        
        if let transform = BoneTransformModelType(rawValue: transform) {
            
            self = transform
            
        } else {
            
            self = .normal
        }
    }
}

enum BlendModeModelType: Int {
    
    case normal = 0
    case additive
    case multiply
    case screen
    
    init(_ blend: Int) {
        
        if let blend = BlendModeModelType(rawValue: blend) {
            
            self = blend
            
        } else {
            
            self = .normal
        }
    }
}

//MARK: - Constraints

enum PathPositionModelMode: Int {
    
    case fixed = 0
    case percent
    
    init(_ positionMode: Int) {
        
        if let positionMode = PathPositionModelMode(rawValue: positionMode) {
            
            self = positionMode
            
        } else {
            
            self = .percent
        }
    }
}

enum PathSpacingModelMode: Int {
    
    case length = 0
    case fixed
    case percent
    
    init(_ spacingMode: Int) {
        
        if let spacingMode = PathSpacingModelMode(rawValue: spacingMode) {
            
            self = spacingMode
            
        } else {
            
            self = .length
        }
    }
}

enum PathRotateModelMode: Int {
    
    case tangent = 0
    case chain
    case chainScale
    
    init(_ rotateMode: Int) {
        
        if let rotateMode = PathRotateModelMode(rawValue: rotateMode) {
            
            self = rotateMode
            
        } else {
            
            self = .tangent
        }
    }
}

//MARK: - Attachments

enum AttachmentModelType {
    
    case region(RegionAttachmentModel)
    case boundingBox(BoundingBoxAttachmentModel)
    case mesh (MeshAttachmentModel)
    case linkedMesh(LinkedMeshAttachmentModel)
    case path(PathAttachmentModel)
    case point(PointAttachmentModel)
    case clipping(ClippingAttachmentModel)
}

//MARK: - Animation

enum AnimationGroupModelType {
    
    case bones([BoneAnimationModel])
    case slots([SlotAnimationModel])
    case ik([IKConstraintAnimationModel])
    case transform([TransformConstraintAnimationModel])
    case deform([DeformSkinAnimationModel])
    case events([EventKeyfarameModel])
    case draworder([DrawOrderKeyframeModel])
}

enum BoneAnimationTimelineModelType {
    
    case rotate([BoneKeyframeRotateModel])
    case translate([BoneKeyframeTranslateModel])
    case scale([BoneKeyframeScaleModel])
    case shear([BoneKeyframeShearModel])
}

enum SlotAnimationTimelineModelType {
    
    case attachment([SlotKeyframeAttachmentModel])
    case color([SlotKeyframeColorModel])
}

//MARK: - Other

enum CurveModelType {
    
    case linear
    case stepped
    case bezier(BezierCurveModel)
    
    init(_ value: Int) {
        
        if value == 1 {
            
            self = .stepped
            
        } else {
            
            self = .linear
        }
    }
    
    init(_ value: [CGFloat]) {
        
        if let curve = BezierCurveModel(value) {
            
            self = .bezier(curve)
            
        } else {
            
            self = .linear
        }
    }
}

enum VerticeModel {
    
    case normal(CGPoint)
    case weighted(CGFloat)
    
    init(_ vertice: [String : CGFloat]) {
        
        guard let x = vertice["x"], let y = vertice["y"] else {
            
            self = .normal(CGPoint.zero)
            return
        }
        
        self = .normal(CGPoint(x: x, y: y))
    }
    
    init(_ vertice: CGFloat) {
        
        self = .weighted(vertice)
    }
}


