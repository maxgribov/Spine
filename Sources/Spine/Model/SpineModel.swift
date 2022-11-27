//
//  SpineModel.swift
//  Spine
//
//  Created by Max Gribov on 27/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

/**
 The `JSON` exported from Spine App is deserialized into this data model. Then this data model is used to create a `Skeleton`.
 
 Usually you don't need to get the model from JSON yourself, this is done during the `Skeleton` initialization process:
 
 ```swift
 do {
     
     let character = try Skeleton(json: "goblins-ess", folder: "goblins", skin: "goblin")
     
     // do something with the character
     
 } catch {
     
     // handle error
     print(error)
 }
 ```
 But in some cases, for example, when you manually prepare texture atlases, you need to decode JSON yourself:
 
 ```swift
 do {
     // prepare your atlases
     let atlases: [String: SKTextureAtlas] = ...

     guard let url = Bundle.main.url(forResource: "goblins-ess", withExtension: "json") else {
         return
     }
     
     let json = try Data(contentsOf: url)
     let model = try JSONDecoder().decode(SpineModel.self, from: json)
     
     let character = Skeleton(model, atlases)
     // do something with the character
     
 } catch {
     
     // handle error
     print(error)
 }
 ```
 */
public struct SpineModel {
    
    let skeleton: SkeletonModel
    let bones: [BoneModel]
    let slots: [SlotModel]
    let skins: [SkinModel]
    let ik: [IKConstraintModel]
    let transform: [TransformConstraintModel]
    let path: [PathConstraintModel]
    let events: [EventModel]
    let animations: [AnimationModel]
}

//MARK: - Decoding

extension SpineModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case skeleton
        case bones
        case slots
        case skins
        case ik
        case transform
        case path
        case events
        case animations
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        self.skeleton = try container.decode(SkeletonModel.self, forKey: .skeleton)
        self.bones = try container.decodeIfPresent([BoneModel].self, forKey: .bones) ?? []
        self.slots = try container.decodeIfPresent([SlotModel].self, forKey: .slots) ?? []
        self.skins = try container.decodeIfPresent([SkinModel].self, forKey: .skins) ?? []
        self.ik = try container.decodeIfPresent([IKConstraintModel].self, forKey: .ik) ?? []
        self.transform = try container.decodeIfPresent([TransformConstraintModel].self, forKey: .transform) ?? []
        self.path = try container.decodeIfPresent([PathConstraintModel].self, forKey: .path) ?? []
        
        //events
        if container.contains(.events) {

            let eventsContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: .events)
            var events = [EventModel]()

            for eventKey in eventsContainer.allKeys {

                let eventContainer = try eventsContainer.nestedContainer(keyedBy: EventModel.Keys.self, forKey: eventKey)
                let event = try EventModel(eventKey.stringValue, eventContainer)
                events.append(event)
            }

            self.events = events

        } else {

            self.events = []
        }

        //animations
        if container.contains(.animations) {
            
            let animationsContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: .animations)
            
            var animations = [AnimationModel]()
            
            for animationKey in animationsContainer.allKeys {
                
                let animationContainer = try animationsContainer.nestedContainer(keyedBy: AnimationModel.Keys.self, forKey: animationKey)
                let animation = try AnimationModel(animationKey.stringValue, animationContainer)
                animations.append(animation)
            }
            
            self.animations = animations
            
        } else {
            
            self.animations = []
        }
    }
}

