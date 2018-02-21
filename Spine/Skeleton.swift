//
//  Skeleton.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public class Skeleton: SKNode {
    
    /**
     Cloasure that is called each time an event animation is triggered.
     The events represented by the 'EventModel' model
     
     See more information about events:
     http://esotericsoftware.com/spine-events
     */
    public var eventTriggered: ((EventModel) ->())?

    /**
     Creates a skeleton node with an 'SpineModel' and *optional* atlas folder name.
     
     See more information about Spine:
     http://esotericsoftware.com/spine-basic-concepts
     
     - parameter model: the skeleton model.
     - parameter folder: name of the folder with image atlases. *optional*
     */
    public init(_ model: SpineModel, atlas folder: String? = nil) {

        super.init()
        self.createBones(model)
        self.createSlots(model)
        self.createSkins(model, atlas: folder)
        self.createAnimations(model)
    }
    
    /**
     Сreates a skeleton node based on the json file stored in the bundle application.
     
     The initializer may fail, so returning value *optional*
     
     See more information about Spine:
     http://esotericsoftware.com/spine-basic-concepts
     
     - parameter name: Spine JSON file name.
     - parameter folder: name of the folder with image atlases. *optional*
     - parameter skin: the name of the skin that you want to apply to 'Skeleton'. *optional*
     */
    public convenience init?(fromJSON name: String, atlas folder: String? = nil, skin: String? = nil) {
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let json = try? Data(contentsOf: url),
              let model = try? JSONDecoder().decode(SpineModel.self, from: json) else {
                
                return nil
        }
        
        self.init(model, atlas: folder)
        applySkin(named: skin)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Private
    
    var slots: [Slot]? { get { return self["//\(Slot.prefix)*"] as? [Slot] } }
    var skins: [Skin]?
    var animations: [Animation]?
    
    func createBones(_ model: SpineModel)  {
        
        if let bonesModels = model.bones {
            
            let bones: [Bone] = bonesModels.map { Bone($0) }
            
            for bone in bones {
                
                if let parentName = bone.model.parent,
                    let parentNode = bones.first(where: { $0.name == Bone.generateName(parentName) }) {
                    
                    parentNode.addChild(bone)
                    
                } else {
                    
                    self.addChild(bone)
                }
            }
        }
    }
    
    func createSlots(_ model: SpineModel) {

        if let slotsModels = model.slots {
            
            var slotOrder: Int = 0
            
            for slotModel in slotsModels {
                
                let boneName = Bone.generateName(slotModel.bone)
                if let bone = childNode(withName: "//\(boneName)") {
                    
                    let slot = Slot(slotModel, slotOrder)
                    bone.addChild(slot)
                }
                
                slotOrder += 1
            }
        }
    }
    
    func createSkins(_ model: SpineModel, atlas folder: String? ) {
        
        self.skins = model.skins?.map({ (skinModel) -> Skin in
            
            return Skin(skinModel, atlas: folder)
        })
    }
    
    func createAnimations(_ model: SpineModel) {
        
        self.animations = model.animations?.map({ (animationModel) -> Animation in
            
            return Animation(animationModel, model)
        })
    }
}

