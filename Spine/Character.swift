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
        get {
            return children.filter({ (node) -> Bool in
                
                guard let name = node.name else {
                    return false
                }
               
                return name.contains(Bone.namePrefix)
                
            }) as? [Bone]
        }
    }
    
    var slots: [Slot]? {
        get {
            return children.filter({ (node) -> Bool in
                
                guard let name = node.name else {
                    return false
                }
                
                return name.contains(Slot.namePrefix)
                
            }) as? [Slot]
        }
    }
    
    var skins: [Skin]?
    
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
    
    func createSlots(_ model: SpineModel) {
        
        if let slotsModels = model.slots {
            
            for slotModel in slotsModels {
                
                let boneName = Bone.generateName(slotModel.bone)
                if let bone = childNode(withName: "//\(boneName)") {
                    
                    bone.addChild(Slot(slotModel))
                }
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
    
    public func runAnimation(_ name: String) {
        
        guard let animation = animations?.first(where: { $0.name == name }) else {
            
            return
        }
        
        self.run(animation.action)
    }
}

