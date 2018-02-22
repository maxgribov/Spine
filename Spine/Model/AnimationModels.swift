//
//  AnimationModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

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
        case draworder = "drawOrder"
    }
    
    enum AnimationModelDecodingError: Error {
        
        case animationGroupTypeUnknown
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {

        var groups = [AnimationGroupModelType]()
        
        for groupKey in container.allKeys {
            
            guard let groupType = Keys(stringValue: groupKey.stringValue) else {
                
                throw AnimationModelDecodingError.animationGroupTypeUnknown
            }
            
            switch groupType {
            case .bones:
                let bonesAnimationGroupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                
                var bonesAnimations = [BoneAnimationModel]()
                
                for boneAnimationKey in bonesAnimationGroupContainer.allKeys {
                    
                    let boneAnimationTimelineContainer = try bonesAnimationGroupContainer.nestedContainer(keyedBy: BoneAnimationModel.Keys.self, forKey: boneAnimationKey)
                    let boneAnimation = try BoneAnimationModel(boneAnimationKey.stringValue, boneAnimationTimelineContainer)
                    bonesAnimations.append(boneAnimation)
                }
                groups.append(AnimationGroupModelType.bones(bonesAnimations))
                
            case .slots:
                let slotsAnimationGroupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                
                var slotsAnimations = [SlotAnimationModel]()
                
                for slotAnimationKey in slotsAnimationGroupContainer.allKeys {
                    
                    let slotAnimationTimelineContainer = try slotsAnimationGroupContainer.nestedContainer(keyedBy: SlotAnimationModel.Keys.self, forKey: slotAnimationKey)
                    let slotAnimation = try SlotAnimationModel(slotAnimationKey.stringValue, slotAnimationTimelineContainer)
                    slotsAnimations.append(slotAnimation)
                }
                groups.append(AnimationGroupModelType.slots(slotsAnimations))
                
            case .ik:
                let ikAnimationGroupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                
                var ikAnimations = [IKConstraintAnimationModel]()
                
                for ikAnimationKey in ikAnimationGroupContainer.allKeys {
                    
                    var ikAnimationContainer = try ikAnimationGroupContainer.nestedUnkeyedContainer(forKey: ikAnimationKey)
                    let ikAnimation = try IKConstraintAnimationModel(ikAnimationKey.stringValue, &ikAnimationContainer)
                    ikAnimations.append(ikAnimation)
                }
                groups.append(AnimationGroupModelType.ik(ikAnimations))
                
            case .transform:
                let transformAnimationGroupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                
                var transformAnimations = [TransformConstraintAnimationModel]()
                
                for transformAnimationKey in transformAnimationGroupContainer.allKeys {
                    
                    var transformAnimationContainer = try transformAnimationGroupContainer.nestedUnkeyedContainer(forKey: transformAnimationKey)
                    let transformAnimation = try TransformConstraintAnimationModel(transformAnimationKey.stringValue, &transformAnimationContainer)
                    transformAnimations.append(transformAnimation)
                }
                groups.append(AnimationGroupModelType.transform(transformAnimations))
                
            case .deform:
                let deformAnimationGroupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                
                var deformAnimations = [DeformSkinAnimationModel]()
                
                for deformAnimationKey in deformAnimationGroupContainer.allKeys {
                    
                    let deformAnimationContainer = try deformAnimationGroupContainer.nestedContainer(keyedBy: DeformSkinAnimationModel.KeysType.self, forKey: deformAnimationKey)
                    let deformAnimation = try DeformSkinAnimationModel(deformAnimationKey.stringValue, deformAnimationContainer)
                    deformAnimations.append(deformAnimation)
                }
                groups.append(AnimationGroupModelType.deform(deformAnimations))
                
            case .events:
                var eventsAnimationGroupContainer = try container.nestedUnkeyedContainer(forKey: groupKey)
                
                var eventAnimationKeyframes = [EventKeyfarameModel]()
                
                while !eventsAnimationGroupContainer.isAtEnd {
                    
                    eventAnimationKeyframes.append(try eventsAnimationGroupContainer.decode(EventKeyfarameModel.self))
                }
                groups.append(AnimationGroupModelType.events(eventAnimationKeyframes))

            case .draworder:
                var draworderAnimationGroupContainer = try container.nestedUnkeyedContainer(forKey: groupKey)
                
                var draworderAnimationKeyframes = [DrawOrderKeyframeModel]()
                
                while !draworderAnimationGroupContainer.isAtEnd {
                    
                    draworderAnimationKeyframes.append(try draworderAnimationGroupContainer.decode(DrawOrderKeyframeModel.self))
                }
                groups.append(AnimationGroupModelType.draworder(draworderAnimationKeyframes))
            }
        }
        
        self.name = name
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

//MARK: - IK Constraint Animation Model

struct IKConstraintAnimationModel: AnimationGroupModel {
    
    let constraint: String
    let keyframes: [IKConstraintKeyframeModel]
}

extension IKConstraintAnimationModel: SpineDecodableArray {
    
    init(_ name: String, _ container: inout UnkeyedDecodingContainer) throws {

        var keyframes = [IKConstraintKeyframeModel]()
        while !container.isAtEnd {

            keyframes.append(try container.decode(IKConstraintKeyframeModel.self))
        }
        
        self.constraint = name
        self.keyframes = keyframes
    }
}

//MARK: - Transform Constraint Animation Model

struct TransformConstraintAnimationModel: AnimationGroupModel {
    
    let constraint: String
    let keyframes: [TransformConstraintKeyframeModel]
}

extension TransformConstraintAnimationModel: SpineDecodableArray {
    
    init(_ name: String, _ container: inout UnkeyedDecodingContainer) throws {
        
        var keyframes = [TransformConstraintKeyframeModel]()
        while !container.isAtEnd {
            
            keyframes.append(try container.decode(TransformConstraintKeyframeModel.self))
        }
        
        self.constraint = name
        self.keyframes = keyframes
    }
}

//MARK: - Deform Skin Animation Model

struct DeformSkinAnimationModel: AnimationGroupModel {
    
    let skin: String
    let slots: [DeformSlotAnimationModel]
}

extension DeformSkinAnimationModel: SpineDecodableDictionary {

    typealias KeysType = SpineNameKey

    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {

        var slots = [DeformSlotAnimationModel]()

        for slotKey in container.allKeys {

            let slotContainer = try container.nestedContainer(keyedBy: DeformSlotAnimationModel.KeysType.self, forKey: slotKey)
            let slotAnimation = try DeformSlotAnimationModel(slotKey.stringValue, slotContainer)
            slots.append(slotAnimation)
        }
        
        self.skin = name
        self.slots = slots
    }
}

struct DeformSlotAnimationModel {
    
    let slot: String
    let meshes: [DeformMeshAnimationModel]
}

extension DeformSlotAnimationModel: SpineDecodableDictionary {

    typealias KeysType = SpineNameKey

    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {

        var meshes = [DeformMeshAnimationModel]()

        for meshKey in container.allKeys {

            var meshContainer = try container.nestedUnkeyedContainer(forKey: meshKey)
            let meshAnimation = try DeformMeshAnimationModel(meshKey.stringValue, &meshContainer)
            meshes.append(meshAnimation)
        }
        
        self.slot = name
        self.meshes = meshes
    }
}

struct DeformMeshAnimationModel {
    
    let mesh: String
    let keyframes: [DeformKeyframeModel]
}

extension DeformMeshAnimationModel: SpineDecodableArray {

    init(_ name: String, _ container: inout UnkeyedDecodingContainer) throws {

        var keyframes = [DeformKeyframeModel]()
        while !container.isAtEnd {

            keyframes.append(try container.decode(DeformKeyframeModel.self))
        }

        self.mesh = name
        self.keyframes = keyframes
    }
}

//MARK: - Keyframes

protocol KeyframeModel {
    
    var time: TimeInterval { get }
}

protocol BoneKeyframeModel: KeyframeModel {
    
    var curve: CurveModelType { get }
}

//MARK: Bone Rotate Keyframe

struct BoneKeyframeRotateModel: BoneKeyframeModel {
    
    let time: TimeInterval
    let curve: CurveModelType
    let angle: CGFloat
    
    init(_ time: TimeInterval, _ curve: String?, _ angle: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.angle = angle ?? 0
    }
    
    //bezier curve init
    init(_ time: TimeInterval, _ curve: [Float], _ angle: CGFloat?) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let angle: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .angle)
        
        do {
            
            let bezierCurve: [Float] = try container.decode([Float].self, forKey: .curve)
            self.init(time, bezierCurve, angle)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, curve, angle)
        }
    }
}

//MARK: Bone Translate Keyframe

struct BoneKeyframeTranslateModel: BoneKeyframeModel {
    
    let time: TimeInterval
    let curve: CurveModelType
    let position: CGPoint
    
    init(_ time: TimeInterval, _ curve: String?, _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.position = CGPoint(x: x ?? 0, y: y ?? 0)
    }
    
    //bezier curve init
    init(_ time: TimeInterval, _ curve: [Float], _ x: CGFloat?, _ y: CGFloat?) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        
        do {
            
            let bezierCurve: [Float] = try container.decode([Float].self, forKey: .curve)
            self.init(time, bezierCurve, x, y)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, curve, x, y)
        }
    }
}

//MARK: Bone Scale Keyframe

struct BoneKeyframeScaleModel: BoneKeyframeModel {
    
    let time: TimeInterval
    let curve: CurveModelType
    let scale: CGVector
    
    init(_ time: TimeInterval, _ curve: String?, _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.scale = CGVector(dx: x ?? 0, dy: y ?? 0)
    }
    
    //bezier curve init
    init(_ time: TimeInterval, _ curve: [Float], _ x: CGFloat?, _ y: CGFloat?) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        
        do {
            
            let bezierCurve: [Float] = try container.decode([Float].self, forKey: .curve)
            self.init(time, bezierCurve, x, y)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, curve, x, y)
        }
    }
}

//MARK: Bone Shear Keyframe

struct BoneKeyframeShearModel: BoneKeyframeModel {
    
    let time: TimeInterval
    let curve: CurveModelType
    let shear: CGVector
    
    init(_ time: TimeInterval, _ curve: String?, _ x: CGFloat?, _ y: CGFloat?) {
        
        self.time = time
        self.curve = CurveModelType(curve)
        self.shear = CGVector(dx: x ?? 0, dy: y ?? 0)
    }
    
    //bezier curve init
    init(_ time: TimeInterval, _ curve: [Float], _ x: CGFloat?, _ y: CGFloat?) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        
        do {
            
            let bezierCurve: [Float] = try container.decode([Float].self, forKey: .curve)
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
    
    let time: TimeInterval
    let name: String?
    
    init(_ time: TimeInterval, _ name: String?) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let name: String? = try container.decodeIfPresent(String.self, forKey: .name)
        
        self.init(time, name)
    }
}

//MARK: Slot Color Keyframe

struct SlotKeyframeColorModel: SlotKeyframeModel {
    
    let time: TimeInterval
    let color: ColorModel
    let curve: CurveModelType
    
    init(_ time: TimeInterval, _ color: String, _ curve: String?) {
        
        self.time = time
        self.color = ColorModel(color)
        self.curve = CurveModelType(curve)
    }
    
    //bezier curve type init
    init(_ time: TimeInterval, _ color: String, _ curve: [Float]) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let color: String = try container.decode(String.self, forKey: .color)
        
        do {
            
            let bezierCurve: [Float] = try container.decode([Float].self, forKey: .curve)
            self.init(time, color, bezierCurve)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, color, curve)
        }
    }
}

//MARK: IK Constraint Keyframe

struct IKConstraintKeyframeModel: KeyframeModel {
    
    let time: TimeInterval
    let mix: CGFloat
    let blendPositive: Bool
    
    init(_ time: TimeInterval, _ mix: CGFloat?, _ blendPositive: Bool?) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let mix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .mix)
        let blendPositive: Bool? = try container.decodeIfPresent(Bool.self, forKey: .blendPositive)
        
        self.init(time, mix, blendPositive)
    }
}

//MARK: Transform Constraint Keyframe

struct TransformConstraintKeyframeModel: KeyframeModel {
    
    let time: TimeInterval
    let rotateMix: CGFloat
    let translateMix: CGFloat
    let scaleMix: CGFloat
    let shearMix: CGFloat
    
    init(_ time: TimeInterval, _ rotateMix: CGFloat?, _ translateMix: CGFloat?, _ scaleMix: CGFloat?, _ shearMix: CGFloat?) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let rotateMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotateMix)
        let translateMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .translateMix)
        let scaleMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleMix)
        let shearMix: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .shearMix)
        
        self.init(time, rotateMix, translateMix, scaleMix, shearMix)
    }
}

//MARK: Deform Keyframe

struct DeformKeyframeModel: KeyframeModel {
    
    let time: TimeInterval
    let offset: Int
    let vertices: [CGFloat]?
    let curve: CurveModelType
    
    init(_ time: TimeInterval, _ offset: Int?, _ vertices: [CGFloat]?, _ curve: String?) {
        
        self.time = time
        self.offset = offset ?? 0
        self.vertices = vertices
        self.curve = CurveModelType(curve)
    }
    
    //bezier curve type init
    init(_ time: TimeInterval, _ offset: Int?, _ vertices: [CGFloat]?, _ curve: [Float]) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let offset: Int? = try container.decodeIfPresent(Int.self, forKey: .offset)
        let vertices: [CGFloat]? = try container.decodeIfPresent([CGFloat].self, forKey: .vertices)
        
        do {
            
            let bezierCurve: [Float] = try container.decode([Float].self, forKey: .curve)
            self.init(time, offset, vertices, bezierCurve)
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, offset, vertices, curve)
        }
    }
}

//MARK: Event Keyframe

struct EventKeyfarameModel: KeyframeModel, AnimationGroupModel {
    
    let time: TimeInterval
    let event: String
    let int: Int?
    let float: CGFloat?
    let string: String?
    
    init(_ time: TimeInterval, _ event: String, _ int: Int?, _ float: CGFloat?, _ string: String?) {
        
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
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let event: String = try container.decode(String.self, forKey: .event)
        let int: Int? = try container.decodeIfPresent(Int.self, forKey: .int)
        let float: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .float)
        let string: String? = try container.decodeIfPresent(String.self, forKey: .string)
        
        self.init(time, event, int, float, string)
    }
}

//MARK: Draw Order Keyframe

struct DrawOrderKeyframeModel: KeyframeModel, AnimationGroupModel {
    
    let time: TimeInterval
    let offsets: [DrawOrderOffsetModel]?
    
    init(_ time: TimeInterval, _ offsets: [[String : Any]]?) {
        
        if let offsets = offsets {
            
            var offsetsMutable = [DrawOrderOffsetModel]()
            for dict in offsets {
                
                if let offset = DrawOrderOffsetModel(dict) {
                    
                    offsetsMutable.append(offset)
                }
            }

            self.offsets = offsetsMutable
            
        } else {
            
            self.offsets = nil
        }
        
        self.time = time
    }
}

extension DrawOrderKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case offsets
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: TimeInterval = try container.decode(TimeInterval.self, forKey: .time)
        let offsets: [DrawOrderOffsetModel]? = try container.decodeIfPresent([DrawOrderOffsetModel].self, forKey: .offsets)
        
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
