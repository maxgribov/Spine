//
//  Skeleton.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public class Skeleton: SKNode {
    
    let model: SkeletonModel
    
    public init(_ model: SpineModel) {

        self.model = model.skeleton
        super.init()
        self.createBones(model.bones)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createBones(_ models: [BoneModel]?)  {
        
        if let models = models {
        
            let bones: [Bone] = models.map { Bone($0) }
            
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
}
