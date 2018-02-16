//
//  Character.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public class Character: SKNode {

    var bones: [Bone]? {
        get { return self["//\(Bone.prefix)*"] as? [Bone]  }
    }
    
    var slots: [Slot]? {
        get { return self["//\(Slot.prefix)*"] as? [Slot] }
    }
    
    var skins: [Skin]?
    public var atlases: [SKTextureAtlas]? {
        get {
            
            var atlasesMutable = [SKTextureAtlas]()
            
            guard let skins = skins else {
                
                return nil
            }
            
            for skin in skins {
                
                guard let skinAtlaces = skin.atlases else {
                    
                    continue
                }
                
                for atlasName in skinAtlaces.keys {
                    
                    if let atlas = skinAtlaces[atlasName] {
                        
                        atlasesMutable.append(atlas)
                    }
                }
            }
            
            return atlasesMutable
        }
    }
    
    var animations: [Animation]?
    public var animationsNames: [String]? {
        get {
            
            guard let animations = animations else {
                return nil
            }
            
            return animations.map({ $0.name })
        }
    }
    
    public init(_ model: SpineModel, atlasFolder: String?) {

        super.init()
        self.addChild(Skeleton(model))
        self.createSlots(model)
        self.createSkins(model, folder: atlasFolder)
        self.createAnimations(model)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func applySkin(named: String? = nil) {
        
        var skinsNames: Set = ["default"]
        
        if let named = named {
            
            skinsNames.insert(named)
        }
        
        guard let skins = skins?.filter({ skinsNames.contains($0.model.name) }) else {
            
            return
        }
        
        for skin in skins {
            
            guard let slotsModels = skin.model.slots else {
                
                continue
            }
            
            for slotModel in slotsModels {

                guard let slot = slots?.first(where: { $0.model.name == slotModel.name }),
                      let attachmentsModels = slotModel.attachments else {
                    
                    continue
                }
                
                for attachmentModel in attachmentsModels {
                    
                    if let attachment = skin.attachment(attachmentModel),
                       let attachmentNode = attachment as? SKNode {

                        slot.addChild(attachmentNode)
                    }
                }
                
                slot.dropToDefaults()
            }
        }
    }
    
    public func runAnimation(named: String) {
        
        guard let animation = animations?.first(where: { $0.name == named }) else {
            
            return
        }
        
        self.run(animation.action)
    }
    
    //MARK: - Private Setup Helpers
    
    func createSlots(_ model: SpineModel) {

        if let slotsModels = model.slots {
            
            var slotOrder: CGFloat = 0
            
            for slotModel in slotsModels {
                
                let boneName = Bone.generateName(slotModel.bone)
                if let bone = childNode(withName: "//\(boneName)") {
                    
                    let slot = Slot(slotModel)
                    slot.zPosition = slotOrder
                    
                    bone.addChild(slot)
                }
                
                slotOrder = slotOrder + 0.01
            }
        }
    }
    
    func createSkins(_ model: SpineModel, folder: String? ) {
        
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

