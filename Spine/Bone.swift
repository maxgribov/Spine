//
//  Bone.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

class Bone: SKSpriteNode, Prefixable, Defaultable {
    
    static let prefix = "bone:"
    let model: BoneModel

    init(_ model: BoneModel) {

        self.model = model
        #if os(OSX)
            
            super.init(texture: nil, color: NSColor.white, size: CGSize.zero)
            
        #else
            
            super.init(texture: nil, color: UIColor.white, size: CGSize.zero)
            
        #endif
        
        self.name = Bone.generateName(model.name)
        self.anchorPoint = CGPoint(x: 0, y: 0.5)
        self.dropToDefaults()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Defaultable
    
    func dropToDefaults() {
        
        self.position = model.position
        self.zRotation = model.rotation * degreeToRadiansFactor
        self.xScale = model.scale.dx
        self.yScale = model.scale.dy
    }
}
