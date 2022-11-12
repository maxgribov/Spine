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
                let adjustedRotateKeyframes = adjustedCurves(rotateKeyframes)
                timelines.append(BoneAnimationTimelineModelType.rotate(adjustedRotateKeyframes))

            case .translate:
                let translateKeyframes = try container.decode([BoneKeyframeTranslateModel].self, forKey: .translate)
                let adjustedTranslateKeyframes = adjustedCurves(translateKeyframes)
                timelines.append(BoneAnimationTimelineModelType.translate(adjustedTranslateKeyframes))

            case .scale:
                let scaleKeyframes = try container.decode([BoneKeyframeScaleModel].self, forKey: .scale)
                let adjustedScaleKeyframes = adjustedCurves(scaleKeyframes)
                timelines.append(BoneAnimationTimelineModelType.scale(adjustedScaleKeyframes))

            case .shear:
                let shearKeyframes = try container.decode([BoneKeyframeShearModel].self, forKey: .shear)
                let adjustedShearKeyframes = adjustedCurves(shearKeyframes)
                timelines.append(BoneAnimationTimelineModelType.shear(adjustedShearKeyframes))
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
                let adjustedColorKeyframes = adjustedCurves(colorKeyframes)
                timelines.append(SlotAnimationTimelineModelType.color(adjustedColorKeyframes))
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

protocol CurvedKeyframeModel {

    var curve: CurveModelType { get set }
}



/**
 Most keyframe properties affect how animation behaves *prior* to the keyframe,
 but curve property affects now animation behaves *after* the keyframe.
 This function moves curve property of keyframes to consequent keyframes
 in order to make curve logic consistent with other properties, like position and angle.
 */
func adjustedCurves<T:CurvedKeyframeModel>(_ input: [T]) -> [T]
{
    var output = [T]()
    var previousCurve = CurveModelType.linear
    for frame in input {
        var adjustedFrame = frame
        adjustedFrame.curve = previousCurve
        output.append(adjustedFrame)
        previousCurve = frame.curve
    }

    return output
}





//MARK: Slot Color Keyframe



//MARK: IK Constraint Keyframe



//MARK: Transform Constraint Keyframe



//MARK: Deform Keyframe

struct DeformKeyframeModel: KeyframeModel {
    
    let time: TimeInterval
    let offset: Int
    let vertices: [CGFloat]?
    let curve: CurveModelType
    
    init(_ time: TimeInterval?, _ offset: Int?, _ vertices: [CGFloat]?, _ curve: String?) {
        
        self.time = time ?? 0
        self.offset = offset ?? 0
        self.vertices = vertices
        self.curve = CurveModelType(curve)
    }
    
    //bezier curve type init
    init(_ time: TimeInterval?, _ offset: Int?, _ vertices: [CGFloat]?, _ curve: CurveModelType.BezierCurveModel) {
        
        self.time = time ?? 0
        self.offset = offset ?? 0
        self.vertices = vertices
        self.curve = .bezier(curve)
    }
}

extension DeformKeyframeModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time
        case offset
        case vertices
        case curve
        case c2
        case c3
        case c4
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time: TimeInterval? = try container.decodeIfPresent(TimeInterval.self, forKey: .time)
        let offset: Int? = try container.decodeIfPresent(Int.self, forKey: .offset)
        let vertices: [CGFloat]? = try container.decodeIfPresent([CGFloat].self, forKey: .vertices)
        
        do {
            
            let c1 = try container.decode(Float.self, forKey: .curve)
            let c2 = try container.decodeIfPresent(Float.self, forKey: .c2)
            let c3 = try container.decodeIfPresent(Float.self, forKey: .c3)
            let c4 = try container.decodeIfPresent(Float.self, forKey: .c4)
            
            self.init(time, offset, vertices, CurveModelType.BezierCurveModel(c1, c2, c3, c4))
            
        } catch {
            
            let curve: String? = try container.decodeIfPresent(String.self, forKey: .curve)
            self.init(time, offset, vertices, curve)
        }
    }
}

//MARK: Event Keyframe



//MARK: Draw Order Keyframe


