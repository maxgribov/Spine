//
//  AnimationModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct AnimationModel {
    
    let name: String
    let groups: [Group]
}

//MARK: - Types

extension AnimationModel {
    
    enum Group {
        
        case bones([BoneAnimationModel])
        case slots([SlotAnimationModel])
        case ik([IKConstraintAnimationModel])
        case transform([TransformConstraintAnimationModel])
        case deform([DeformSkinAnimationModel])
        case events([EventKeyfarameModel])
        case drawOrder([DrawOrderKeyframeModel])
    }
    
    enum Error: LocalizedError {
        
        case animationGroupTypeUnknown
    }
}

//MARK: - Decoding

extension AnimationModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case bones, slots, ik, transform, deform, events, drawOrder
    }

    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {

        var groups = [Group]()
        
        for groupKey in container.allKeys {
            
            guard let groupType = Keys(stringValue: groupKey.stringValue) else {
                throw Error.animationGroupTypeUnknown
            }
            
            switch groupType {
            case .bones:
                let groupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                var animations = [BoneAnimationModel]()
                for key in groupContainer.allKeys {
                    
                    let timelineContainer = try groupContainer.nestedContainer(keyedBy: BoneAnimationModel.Keys.self, forKey: key)
                    let animation = try BoneAnimationModel(key.stringValue, timelineContainer)
                    animations.append(animation)
                }
                groups.append(.bones(animations))
                
            case .slots:
                let groupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                var animations = [SlotAnimationModel]()
                for key in groupContainer.allKeys {
                    
                    let timelineContainer = try groupContainer.nestedContainer(keyedBy: SlotAnimationModel.Keys.self, forKey: key)
                    let animation = try SlotAnimationModel(key.stringValue, timelineContainer)
                    animations.append(animation)
                }
                groups.append(.slots(animations))
                
            case .ik:
                let groupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                var animations = [IKConstraintAnimationModel]()
                for key in groupContainer.allKeys {
                    
                    var animationContainer = try groupContainer.nestedUnkeyedContainer(forKey: key)
                    let animation = try IKConstraintAnimationModel(key.stringValue, &animationContainer)
                    animations.append(animation)
                }
                groups.append(.ik(animations))
                
            case .transform:
                let groupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                var animations = [TransformConstraintAnimationModel]()
                for key in groupContainer.allKeys {
                    
                    var animationContainer = try groupContainer.nestedUnkeyedContainer(forKey: key)
                    let animation = try TransformConstraintAnimationModel(key.stringValue, &animationContainer)
                    animations.append(animation)
                }
                groups.append(.transform(animations))
                
            case .deform:
                let groupContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: groupKey)
                var animations = [DeformSkinAnimationModel]()
                for key in groupContainer.allKeys {
                    
                    let animationContainer = try groupContainer.nestedContainer(keyedBy: DeformSkinAnimationModel.KeysType.self, forKey: key)
                    let animation = try DeformSkinAnimationModel(key.stringValue, animationContainer)
                    animations.append(animation)
                }
                groups.append(.deform(animations))
                
            case .events:
                var groupContainer = try container.nestedUnkeyedContainer(forKey: groupKey)
                var keyframes = [EventKeyfarameModel]()
                while groupContainer.isAtEnd == false {
                    
                    keyframes.append(try groupContainer.decode(EventKeyfarameModel.self))
                }
                groups.append(.events(keyframes))

            case .drawOrder:
                var groupContainer = try container.nestedUnkeyedContainer(forKey: groupKey)
                var keyframes = [DrawOrderKeyframeModel]()
                while groupContainer.isAtEnd == false {
                    
                    keyframes.append(try groupContainer.decode(DrawOrderKeyframeModel.self))
                }
                groups.append(.drawOrder(keyframes))
            }
        }
        
        self.name = name
        self.groups = groups
    }
}


