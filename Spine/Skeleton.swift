//
//  Skeleton.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public class Skeleton: SKNode {
    
    public var eventTriggered: ((EventModel) ->())?

    public init(_ model: SpineModel, atlas folder: String?) {

        super.init()
        self.createBones(model)
        self.createSlots(model)
        self.createSkins(model, atlas: folder)
        self.createAnimations(model)
    }
    
    public convenience init?(fromJSON name: String, atlas folder: String?, skin: String? = nil) {
        
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
            
            return Skin(skinModel, folder)
        })
    }
    
    func createAnimations(_ model: SpineModel) {
        
        self.animations = model.animations?.map({ (animationModel) -> Animation in
            
            return Animation(animationModel, model)
        })
    }
}

