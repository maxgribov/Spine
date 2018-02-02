//
//  AnimationModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

//MARK: - Animations

struct AnimationModel {
    
    let name: String
    let groups: [AnimationGroupModelType]
}

extension AnimationModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case bones
        case slots
        case ik
        case transform
        case deform
        case events
        case draworder
    }
    
    enum AnimationModelDecodingError: Error {
        
        case animationNameMissed
        case animationGroupTypeUnknown
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {

        var groups = [AnimationGroupModelType]()
        
        for group in container.allKeys {
            
            guard let groupType = Keys(stringValue: group.stringValue) else {
                
                throw AnimationModelDecodingError.animationGroupTypeUnknown
            }
            
            switch groupType {
            case .bones:
                let bonesAnimationGroupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: group)
                
                var bonesAnimations = [BoneAnimationModel]()
                
                for boneAnimationKey in bonesAnimationGroupContainer.allKeys {
                    
                    let boneAnimationTimelineContainer = try bonesAnimationGroupContainer.nestedContainer(keyedBy: BoneAnimationModel.Keys.self, forKey: boneAnimationKey)
                    let boneAnimation = try BoneAnimationModel(boneAnimationKey.stringValue, boneAnimationTimelineContainer)
                    bonesAnimations.append(boneAnimation)
                }
                groups.append(AnimationGroupModelType.bones(bonesAnimations))
                
            default:
                continue
            }
        }
        
        self.name = name
        self.groups = groups
        
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: SpineNameKey.self)
        
        guard let animationName = container.allKeys.first?.stringValue,
            let animationNameKey = SpineNameKey(stringValue: animationName) else {
                
                throw AnimationModelDecodingError.animationNameMissed
        }
        
        let animationGroupsContainer = try container.nestedContainer(keyedBy: Keys.self, forKey: animationNameKey)
        
        var groups = [AnimationGroupModelType]()

        for group in animationGroupsContainer.allKeys {
            
            guard let groupType = Keys(stringValue: group.stringValue) else {
                
                throw AnimationModelDecodingError.animationGroupTypeUnknown
            }
            
            switch groupType {
            case .bones:
                let bonesAnimationGroupContainer = try animationGroupsContainer.nestedContainer(keyedBy: SpineNameKey.self, forKey: group)
                
                var bonesAnimations = [BoneAnimationModel]()
                
                for boneAnimationKey in bonesAnimationGroupContainer.allKeys {
                    
                    let boneAnimationTimelineContainer = try bonesAnimationGroupContainer.nestedContainer(keyedBy: BoneAnimationModel.Keys.self, forKey: boneAnimationKey)
                    let boneAnimation = try BoneAnimationModel(boneAnimationKey.stringValue, boneAnimationTimelineContainer)
                    bonesAnimations.append(boneAnimation)
                }
                groups.append(AnimationGroupModelType.bones(bonesAnimations))

            default:
                continue
            }
        }
        
        self.name = animationName
        self.groups = groups
    }
}

enum AnimationGroupModelType {
    
    case bones([BoneAnimationModel])
    case slots([SlotAnimationModel])
    case ik([IKConstraintAnimationModel])
    case transform([TransformConstraintAnimationModel])
    case deform([DeformSkinAnimationModel])
    case events([EventKeyfarameModel])
    case draworder([DrawOrderKeyframeModel])
    
    var identifier: String {
        
        switch self {
        case .bones(_): return "bones"
        case .slots(_): return "slots"
        case .ik(_): return "ik"
        case .transform(_): return "transform"
        case .deform(_): return "deform"
        case .events(_): return "events"
        case .draworder(_): return "draworder"
        }
    }
    
    var models: [AnimationGroupModel] {
        
        switch self {
        case .bones(let model): return model
        case .slots(let model): return model
        case .ik(let model): return model
        case .transform(let model): return model
        case .deform(let model): return model
        case .events(let model): return model
        case .draworder(let model): return model
        }
    }
}

protocol AnimationGroupModel {
    
}

//MARK: - Bone Animation Model

struct BoneAnimationModel: AnimationGroupModel {
    
    let bone: String
    let timelines: [BoneAnimationTimelineModelType]
}

enum BoneAnimationTimelineModelType {
    
    case rotate([BoneKeyframeRotateModel])
    case translate([BoneKeyframeTranslateModel])
    case scale([BoneKeyframeScaleModel])
    case shear([BoneKeyframeShearModel])
    
    var identifier: String {
        
        switch self {
        case .rotate(_): return "rotate"
        case .translate(_): return "translate"
        case .scale(_): return "scale"
        case .shear(_): return "shear"
        }
    }
    
    var models: [BoneKeyframeModel] {
        
        switch self {
        case .rotate(let model): return model
        case .translate(let model): return model
        case .scale(let model): return model
        case .shear(let model): return model
        }
    }
}

extension BoneAnimationModel: SpineDecodableDictionary {

    enum Keys: String, CodingKey {
        
        case rotate
        case translate
        case scale
        case shear
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var timelines = [BoneAnimationTimelineModelType]()
        
        for timelineKey in container.allKeys {
            
            switch timelineKey {
                
            case .rotate:
                let rotateKeyframes = try container.decode([BoneKeyframeRotateModel].self, forKey: .rotate)
                timelines.append(BoneAnimationTimelineModelType.rotate(rotateKeyframes))
            case .translate:
                let translateKeyframes = try container.decode([BoneKeyframeTranslateModel].self, forKey: .translate)
                timelines.append(BoneAnimationTimelineModelType.translate(translateKeyframes))
            case .scale:
                let scaleKeyframes = try container.decode([BoneKeyframeScaleModel].self, forKey: .scale)
                timelines.append(BoneAnimationTimelineModelType.scale(scaleKeyframes))
            case .shear:
                let shearKeyframes = try container.decode([BoneKeyframeShearModel].self, forKey: .shear)
                timelines.append(BoneAnimationTimelineModelType.shear(shearKeyframes))
            }
        }
        
        self.bone = name
        self.timelines = timelines
    }
    
}

//MARK: - Slot Animation Model

struct SlotAnimationModel: AnimationGroupModel {
    
    let slot: String
    let timelines: [SlotAnimationTimelineModelType]
}

enum SlotAnimationTimelineModelType {
    
    case attachment([SlotKeyframeAttachmentModel])
    case color([SlotKeyframeColorModel])
    
    var identifier: String {
        
        switch self {
        case .attachment(_): return "attachment"
        case .color(_): return "color"
        }
    }
    
    var models: [SlotKeyframeModel] {
        
        switch self {
        case .attachment(let model): return model
        case .color(let model): return model
        }
    }
}

//TODO: write tests
extension SlotAnimationModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case attachment
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var timelines = [SlotAnimationTimelineModelType]()
        
        for timelineKey in container.allKeys {
            
            switch timelineKey {
                
            case .attachment:
                let attachmentKeyframes = try container.decode([SlotKeyframeAttachmentModel].self, forKey: .attachment)
                timelines.append(SlotAnimationTimelineModelType.attachment(attachmentKeyframes))
            case .color:
                let colorKeyframes = try container.decode([SlotKeyframeColorModel].self, forKey: .color)
                timelines.append(SlotAnimationTimelineModelType.color(colorKeyframes))
            }
        }
        
        self.slot = name
        self.timelines = timelines
    }
}

struct IKConstraintAnimationModel: AnimationGroupModel {
    
    let constraint: String
    let keyframes: [IKConstraintKeyframeModel]
}

struct TransformConstraintAnimationModel: AnimationGroupModel {
    
    let constraint: String
    let keyframes: [TransformConstraintKeyframeModel]
}

struct DeformSkinAnimationModel: AnimationGroupModel {
    
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

//MARK: Bone Rotate Keyframe

struct BoneKeyframeRotateModel: BoneKeyframeModel {
    
    let time: CGFloat
    let curve: CurveModelType
    let angle: CGFloat
    
    init(_ time: CGFloat, _ curve: String?, _ angle: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.angle = angle ?? 0
    }
    
    //bezier curve init
    init(_ time: CGFloat, _ curve: [CGFloat], _ angle: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.angle = angle ?? 0
    }
}

extension BoneKeyframeRotateModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case curve
        case angle
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let angle: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .angle)
        
        do {
            
            let bezierCurve: [CGFloat] = try container.decode([CGFloat].self, forKey: .curve)
            self.init(time, bezierCurve, angle)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, curve, angle)
        }
    }
}

//MARK: Bone Translate Keyframe

struct BoneKeyframeTranslateModel: BoneKeyframeModel {
    
    let time: CGFloat
    let curve: CurveModelType
    let position: CGPoint
    
    init(_ time: CGFloat, _ curve: String?, _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.position = CGPoint(x: x ?? 0, y: y ?? 0)
    }
    
    //bezier curve init
    init(_ time: CGFloat, _ curve: [CGFloat], _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.position = CGPoint(x: x ?? 0, y: y ?? 0)
    }
}

extension BoneKeyframeTranslateModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case curve
        case x
        case y
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        
        do {
            
            let bezierCurve: [CGFloat] = try container.decode([CGFloat].self, forKey: .curve)
            self.init(time, bezierCurve, x, y)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, curve, x, y)
        }
    }
}

//MARK: Bone Scale Keyframe

struct BoneKeyframeScaleModel: BoneKeyframeModel {
    
    let time: CGFloat
    let curve: CurveModelType
    let scale: CGVector
    
    init(_ time: CGFloat, _ curve: String?, _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.scale = CGVector(dx: x ?? 0, dy: y ?? 0)
    }
    
    //bezier curve init
    init(_ time: CGFloat, _ curve: [CGFloat], _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.scale = CGVector(dx: x ?? 0, dy: y ?? 0)
    }
}

extension BoneKeyframeScaleModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case curve
        case x
        case y
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        
        do {
            
            let bezierCurve: [CGFloat] = try container.decode([CGFloat].self, forKey: .curve)
            self.init(time, bezierCurve, x, y)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, curve, x, y)
        }
    }
}

//MARK: Bone Shear Keyframe

struct BoneKeyframeShearModel: BoneKeyframeModel {
    
    let time: CGFloat
    let curve: CurveModelType
    let shear: CGVector
    
    init(_ time: CGFloat, _ curve: String?, _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.shear = CGVector(dx: x ?? 0, dy: y ?? 0)
    }
    
    //bezier curve init
    init(_ time: CGFloat, _ curve: [CGFloat], _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.shear = CGVector(dx: x ?? 0, dy: y ?? 0)
    }
}

extension BoneKeyframeShearModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case curve
        case x
        case y
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        
        do {
            
            let bezierCurve: [CGFloat] = try container.decode([CGFloat].self, forKey: .curve)
            self.init(time, bezierCurve, x, y)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, curve, x, y)
        }
    }
}

//MARK: Slot Attachment Keyframe

protocol SlotKeyframeModel: KeyframeModel {
    
}

struct SlotKeyframeAttachmentModel: SlotKeyframeModel {
    
    let time: CGFloat
    let name: String?
    
    init(_ time: CGFloat, _ name: String?) {
        
        self.time = time
        self.name = name
    }
}

extension SlotKeyframeAttachmentModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case name
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let name: String? = try container.decodeIfPresent(String.self, forKey: .name)
        
        self.init(time, name)
    }
}

//MARK: Slot Color Keyframe

struct SlotKeyframeColorModel: SlotKeyframeModel {
    
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

extension SlotKeyframeColorModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case color
        case curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let color: String = try container.decode(String.self, forKey: .color)
        
        do {
            
            let bezierCurve: [CGFloat] = try container.decode([CGFloat].self, forKey: .curve)
            self.init(time, color, bezierCurve)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, color, curve)
        }
    }
}

//MARK: IK Constraint Keyframe

struct IKConstraintKeyframeModel: KeyframeModel {
    
    let time: CGFloat
    let mix: CGFloat
    let blendPositive: Bool
    
    init(_ time: CGFloat, _ mix: CGFloat?, _ blendPositive: Bool?) {
        
        self.time = time
        self.mix = mix ?? 1.0
        self.blendPositive = blendPositive ?? false
    }
}

extension IKConstraintKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case mix
        case blendPositive
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let mix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .mix)
        let blendPositive: Bool? = try container.decodeIfPresent(Bool.self, forKey: .blendPositive)
        
        self.init(time, mix, blendPositive)
    }
}

//MARK: Transform Constraint Keyframe

struct TransformConstraintKeyframeModel: KeyframeModel {
    
    let time: CGFloat
    let rotateMix: CGFloat
    let translateMix: CGFloat
    let scaleMix: CGFloat
    let shearMix: CGFloat
    
    init(_ time: CGFloat, _ rotateMix: CGFloat?, _ translateMix: CGFloat?, _ scaleMix: CGFloat?, _ shearMix: CGFloat?) {
        
        self.time = time
        self.rotateMix = rotateMix ?? 1.0
        self.translateMix = translateMix ?? 1.0
        self.scaleMix = scaleMix ?? 1.0
        self.shearMix = shearMix ?? 1.0
    }
}

extension TransformConstraintKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case rotateMix
        case translateMix
        case scaleMix
        case shearMix
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let rotateMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotateMix)
        let translateMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .translateMix)
        let scaleMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleMix)
        let shearMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .shearMix)
        
        self.init(time, rotateMix, translateMix, scaleMix, shearMix)
    }
}

//MARK: Deform Keyframe

struct DeformKeyframeModel: KeyframeModel {
    
    let time: CGFloat
    let offset: Int
    let vertices: [CGFloat]
    let curve: CurveModelType
    
    init(_ time: CGFloat, _ offset: Int?, _ vertices: [CGFloat], _ curve: String?) {
        
        self.time = time
        self.offset = offset ?? 0
        self.vertices = vertices
        self.curve = CurveModelType(curve)
    }
    
    //bezier curve type init
    init(_ time: CGFloat, _ offset: Int?, _ vertices: [CGFloat], _ curve: [CGFloat]) {
        
        self.time = time
        self.offset = offset ?? 0
        self.vertices = vertices
        self.curve = CurveModelType(curve)
    }
}

extension DeformKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case offset
        case vertices
        case curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let offset: Int? = try container.decodeIfPresent(Int.self, forKey: .offset)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        
        do {
            
            let bezierCurve: [CGFloat] = try container.decode([CGFloat].self, forKey: .curve)
            self.init(time, offset, vertices, bezierCurve)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, offset, vertices, curve)
        }
    }
}

//MARK: Event Keyframe

struct EventKeyfarameModel: KeyframeModel, AnimationGroupModel {
    
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

extension EventKeyfarameModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case event = "name"
        case int
        case float
        case string
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let event: String = try container.decode(String.self, forKey: .event)
        let int: Int? = try container.decodeIfPresent(Int.self, forKey: .int)
        let float: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .float)
        let string: String? = try container.decodeIfPresent(String.self, forKey: .string)
        
        self.init(time, event, int, float, string)
    }
}

//MARK: Draw Order Keyframe

struct DrawOrderKeyframeModel: KeyframeModel, AnimationGroupModel {
    
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

extension DrawOrderKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case offsets
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: CGFloat = try container.decode(CGFloat.self, forKey: .time)
        let offsets: [DrawOrderOffsetModel] = try container.decode([DrawOrderOffsetModel].self, forKey: .offsets)
        
        self.time = time
        self.offsets = offsets
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

extension DrawOrderOffsetModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case slot
        case offset
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let slot: String = try container.decode(String.self, forKey: .slot)
        let offset: Int = try container.decode(Int.self, forKey: .offset)
        
        self.slot = slot
        self.offset = offset
    }
}
