//
//  AnimationModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

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

//MARK: - Animations

struct AnimationModel {
    
    let name: String
    let groups: [AnimationGroupModelType]
}

struct BoneAnimationModel {
    
    let bone: String
    let timelines: [BoneAnimationTimelineModelType]
}

struct SlotAnimationModel {
    
    let slot: String
    let timelines: [SlotAnimationTimelineModelType]
}

struct IKConstraintAnimationModel {
    
    let constraint: String
    let keyframes: [IKConstraintKeyframeModel]
}

struct TransformConstraintAnimationModel {
    
    let constraint: String
    let keyframes: [TransformConstraintKeyframeModel]
}

struct DeformSkinAnimationModel {
    
    let skin: String
    let slots: [DeformSlotAnimationModel]
}

struct DeformSlotAnimationModel {
    
    let slot: String
    let meshes: [DeformMeshAnimationModel]
}

struct DeformMeshAnimationModel {
    
    let mesh: String
    let keyframes: [DeformKeyframeModel]
}

//MARK: - Keyframes

protocol KeyframeModel {
    
    var time: CGFloat { get }
}

protocol BoneKeyframeModel: KeyframeModel {
    
    var curve: CurveModelType { get }
}

struct BoneKeyframeRotateModel: BoneKeyframeModel {
    
    let time: CGFloat
    let curve: CurveModelType
    let angle: CGFloat
    
    init(_ time: CGFloat, _ curve: String?, _ angle: CGFloat = 0) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.angle = angle
    }
    
    //bezier curve init
    init(_ time: CGFloat, _ curve: [CGFloat], _ angle: CGFloat = 0) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.angle = angle
    }
}

struct BoneKeyframeTranslateModel: BoneKeyframeModel {
    
    let time: CGFloat
    let curve: CurveModelType
    let position: CGPoint
    
    init(_ time: CGFloat, _ curve: String?, _ x: CGFloat = 0, _ y: CGFloat = 0) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.position = CGPoint(x: x, y: y)
    }
    
    //bezier curve init
    init(_ time: CGFloat, _ curve: [CGFloat], _ x: CGFloat = 0, _ y: CGFloat = 0) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.position = CGPoint(x: x, y: y)
    }
}

struct BoneKeyframeScaleModel: BoneKeyframeModel {
    
    let time: CGFloat
    let curve: CurveModelType
    let scale: CGVector
    
    init(_ time: CGFloat, _ curve: String?, _ x: CGFloat = 0, _ y: CGFloat = 0) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.scale = CGVector(dx: x, dy: y)
    }
    
    //bezier curve init
    init(_ time: CGFloat, _ curve: [CGFloat], _ x: CGFloat = 0, _ y: CGFloat = 0) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.scale = CGVector(dx: x, dy: y)
    }
}

struct BoneKeyframeShearModel: BoneKeyframeModel {
    
    let time: CGFloat
    let curve: CurveModelType
    let shear: CGVector
    
    init(_ time: CGFloat, _ curve: String?, _ x: CGFloat = 0, _ y: CGFloat = 0) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.shear = CGVector(dx: x, dy: y)
    }
    
    //bezier curve init
    init(_ time: CGFloat, _ curve: [CGFloat], _ x: CGFloat = 0, _ y: CGFloat = 0) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.shear = CGVector(dx: x, dy: y)
    }
}

struct SlotKeyframeAttachmentModel: KeyframeModel {
    
    let time: CGFloat
    let name: String
    
    init(_ time: CGFloat, _ name: String) {
        
        self.time = time
        self.name = name
    }
}

struct SlotKeyframeColorModel: KeyframeModel {
    
    let time: CGFloat
    let color: ColorModel
    let curve: CurveModelType
    
    init(_ time: CGFloat, _ color: String, _ curve: String?) {
        
        self.time = time
        self.color = ColorModel(color)
        self.curve = CurveModelType(curve)
    }
    
    //bezier curve type init
    init(_ time: CGFloat, _ color: String, _ curve: [CGFloat]) {
        
        self.time = time
        self.color = ColorModel(color)
        self.curve = CurveModelType(curve)
    }
}

struct IKConstraintKeyframeModel: KeyframeModel {
    
    let time: CGFloat
    let mix: CGFloat
    let blendPositive: Bool
    
    init(_ time: CGFloat, _ mix: CGFloat = 1, _ blendPositive: Bool = false) {
        
        self.time = time
        self.mix = mix
        self.blendPositive = blendPositive
    }
}

struct TransformConstraintKeyframeModel: KeyframeModel {
    
    let time: CGFloat
    let rotateMix: CGFloat
    let translateMix: CGFloat
    let scaleMix: CGFloat
    let shearMix: CGFloat
    
    init(_ time: CGFloat, _ rotateMix: CGFloat = 1, _ translateMix: CGFloat = 1, _ scaleMix: CGFloat, _ shearMix: CGFloat) {
        
        self.time = time
        self.rotateMix = rotateMix
        self.translateMix = translateMix
        self.scaleMix = scaleMix
        self.shearMix = shearMix
    }
}

struct DeformKeyframeModel: KeyframeModel {
    
    let time: CGFloat
    let offset: Int
    let vertices: [CGFloat]
    let curve: CurveModelType
    
    init(_ time: CGFloat, _ offset: Int, _ vertices: [CGFloat], _ curve: String?) {
        
        self.time = time
        self.offset = offset
        self.vertices = vertices
        self.curve = CurveModelType(curve)
    }
    
    //bezier curve type init
    init(_ time: CGFloat, _ offset: Int, _ vertices: [CGFloat], _ curve: [CGFloat]) {
        
        self.time = time
        self.offset = offset
        self.vertices = vertices
        self.curve = CurveModelType(curve)
    }
}

struct EventKeyfarameModel: KeyframeModel {
    
    let time: CGFloat
    let event: String
    let int: Int?
    let float: CGFloat?
    let string: String?
    
    init(_ time: CGFloat, _ event: String, _ int: Int?, _ float: CGFloat?, _ string: String?) {
        
        self.time = time
        self.event = event
        self.int = int
        self.float = float
        self.string = string
    }
}

struct DrawOrderKeyframeModel: KeyframeModel {
    
    let time: CGFloat
    let offsets: [DrawOrderOffsetModel]
    
    init(_ time: CGFloat, _ offsets: [[String : Any]]) {
        
        var offsetsMutable = [DrawOrderOffsetModel]()
        for dict in offsets {
            
            if let offset = DrawOrderOffsetModel(dict) {
                
                offsetsMutable.append(offset)
            }
        }
        
        self.time = time
        self.offsets = offsetsMutable
    }
}

struct DrawOrderOffsetModel {
    
    let slot: String
    let offset: Int
    
    init?(_ dict: [String: Any]) {
        
        guard let slot = dict["slot"] as? String, let offset = dict["offset"] as? Int else {
            
            return nil
        }
        
        self.slot = slot
        self.offset = offset
    }
}

//MARK: - Event

struct EventModel {
    
    let name: String
    let int: Int
    let float: CGFloat
    let string: String?
    
    init(_ name: String, _ int: Int = 0, _ float: CGFloat = 0, _ string: String?) {
        
        self.name = name
        self.int = int
        self.float = float
        self.string = string
    }
}
