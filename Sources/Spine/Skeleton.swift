//
//  Skeleton.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

/**
 The skeleton of your character with all the bones, slots, attachments. Also, all character animations are stored together with the skeleton.
 
 The easiest way to create your character and run the animation:
 ```swift
 do {
     
     let character = try Skeleton(json: "goblins-ess", folder: "goblins", skin: "goblin")
     
     character.name = "goblin"
     character.position = CGPoint(x: self.size.width / 2, y: (self.size.height / 2) - 200)
     
     // add to the scene or to any other SKNode
     addChild(character)
     
     let walkAnimation = try character.action(animation: "walk")
     character.run(.repeatForever(walkAnimation))

 } catch {
     
     // handle error
     print(error)
 }
 ```
 The `Skeleton` is inherited from `SKNode` so you can do with it everything you can do with other nodes in `Spritekit`. Add to the scene, to various other nodes, apply `SKAction`, etc.
 */
public class Skeleton: SKNode {
    
    /**
     Closure that is called each time an event animation is triggered.
     The events represented by the `EventModel` model
     
     See more information about events:
     http://esotericsoftware.com/spine-events
     */
    public var eventTriggered: ((EventModel) ->())?

    /**
     Creates a skeleton node with an `SpineModel` and *optional* atlas folder name.
     
     See more information about Spine:
     http://esotericsoftware.com/spine-basic-concepts
     
     - parameter model: the skeleton model.
     - parameter folder: name of the folder with image atlases. *optional*
     */
    public convenience init(_ model: SpineModel, atlas folder: String? = nil) {

        let skins = Self.createSkins(model, atlas: folder)
        let animations = Self.createAnimations(model)
        self.init(skins: skins, animations: animations)
        
        self.createBones(model)
        self.createSlots(model)
    }
    
    /**
     Creates a skeleton node with an `SpineModel` and atlases dictionary.

     - parameter model: the skeleton model.
     - parameter atlases: atlases dictionary
     */
    public convenience init(_ model: SpineModel, _ atlases: [String : SKTextureAtlas]) {
        
        let skins = Self.createSkins(model, atlases)
        let animations = Self.createAnimations(model)
        self.init(skins: skins, animations: animations)
        
        self.createBones(model)
        self.createSlots(model)
    }
    /**
     Сreates a skeleton node based on the `json` file stored in the bundle application.
     
     The initializer may fail, so returning value *optional*
     
     See more information about Spine:
     http://esotericsoftware.com/spine-basic-concepts
     
     - parameter name: Spine JSON file name.
     - parameter folder: name of the folder with image atlases. *optional*
     - parameter skin: the name of the skin that you want to apply to 'Skeleton'. *optional*
     
     - throws: Throws a debuggable error.
     */
    public convenience init(json name: String, folder: String? = nil, skin: String? = nil) throws {
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw SpineError.jsonFileLoadingFromBundleFailed("\(name).json")
        }
        
        let json = try Data(contentsOf: url)
        let model = try JSONDecoder().decode(SpineModel.self, from: json)
        
        self.init(model, atlas: folder)
        
        try applyDefaultSkin()
        
        if let skin = skin {
            
            try apply(skin: skin)
        }
    }
    
    /**
     Сreates a skeleton node based on the `json` file stored in the bundle application.
     
     The initializer may fail, so returning value *optional*
     
     See more information about Spine:
     http://esotericsoftware.com/spine-basic-concepts
     
     - parameter name: Spine JSON file name.
     - parameter folder: name of the folder with image atlases. *optional*
     - parameter skin: the name of the skin that you want to apply to 'Skeleton'. *optional*
     */
    @available(*, deprecated, message: "Use 'init(json:folder:skin:) throws' instead")
    public convenience init?(fromJSON name: String, atlas folder: String? = nil, skin: String? = nil) {
        
        do {
            
            try self.init(json: name, folder: folder, skin: skin)
            
        } catch {
            
            return nil
        }
    }
    
    /**
     Not implemented. If you try to call this initializer, a fatal error will occur and the application will crash.
     */
    @available(*, deprecated, message: "Not implemented. If you try to call this initializer, a fatal error will occur and the application will crash.")
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Private
    
    var slots: [Slot] { self["//\(Slot.prefix)*"].compactMap({ $0 as? Slot }) }
    var skins: [Skin]
    var animations: [Animation]
    
    init(skins: [Skin], animations: [Animation]) {
    
        self.skins = skins
        self.animations = animations
        super.init()
    }
}

//MARK: - Init Helpers

extension Skeleton {
    
    func createBones(_ model: SpineModel)  {
        
        let bones = model.bones.map { Bone($0) }
        for bone in bones {
            
            if let parentName = bone.model.parent,
                let parentNode = bones.first(where: { $0.name == Bone.generateName(parentName) }) {
                
                parentNode.addChild(bone)
                
            } else {
                
                self.addChild(bone)
            }
        }
    }
    
    func createSlots(_ model: SpineModel) {

        for (index, slotModel) in model.slots.enumerated() {
            
            let boneName = Bone.generateName(slotModel.bone)
            guard let bone = childNode(withName: "//\(boneName)") else {
                continue
            }
            
            let slot = Slot(slotModel, index)
            bone.addChild(slot)
        }
    }
    
    static func createSkins(_ model: SpineModel, atlas folder: String?) -> [Skin] {
        
        model.skins.map{ Skin($0, atlas: folder) }
    }
    
    static func createSkins(_ model: SpineModel, _ atlases: [String : SKTextureAtlas]) -> [Skin] {
        
        model.skins.map{ Skin($0, atlases) }
    }
    
    static func createAnimations(_ model: SpineModel) -> [Animation] {
        
        model.animations.map{ Animation($0, model) }
    }
}

//MARK: - Skins

extension Skeleton {
    
    func skin(named: String) throws -> Skin {
        
        guard let skin = skins.first(where: { $0.name == named }) else {
            throw SpineError.missingSkinNamed(named)
        }
        
        return skin
    }

    func apply(skin: Skin) {
        
        for slotModel in skin.model.slots {
            
            guard let slot = slots.first(where: { $0.model.name == slotModel.name }) else {
                continue
            }
            
            // reset slot
            slot.removeAllChildren()
            slot.physicsBody = nil

            var boundingBoxes = [BoundingBoxAttachment]()
            let attachments = slotModel.attachments.compactMap({ skin.attachment($0) })
            for attachment in attachments {

                switch attachment {
                case let region as RegionAttachment:
                    slot.addChild(region)
                    
                case let boundingBox as BoundingBoxAttachment:
                    boundingBoxes.append(boundingBox)
                    
                case let point as PointAttachment:
                    slot.addChild(point)
                    
                default:
                    continue
                }
            }
            
            if boundingBoxes.count > 1 {
                
                let physicBodies = boundingBoxes.compactMap({ $0.physicsBody })
                let compositePhysicBody = SKPhysicsBody(bodies: physicBodies)
                compositePhysicBody.isDynamic = false
                slot.physicsBody = compositePhysicBody
                
            } else {
                
                slot.physicsBody = boundingBoxes.first?.physicsBody
            }
            
            slot.dropToDefaults()
        }
    }
}

//MARK: - Defaultable

extension Skeleton: Defaultable {
    
    func dropToDefaults() {
        
        if self.hasActions() {
            
            self.removeAllActions()
        }
        
        for child in self[".//*"] {
            
            if child.hasActions() {
                
                child.removeAllActions()
            }
            
            if let defaultableChild = child as? Defaultable {
                
                defaultableChild.dropToDefaults()
            }
        }
    }
}

