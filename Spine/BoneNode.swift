//
//  BoneNode.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

class BoneNode: SKSpriteNode {
    
    let model: BoneModel
    
    init(_ model: BoneModel) {

        self.model = model
        super.init(texture: nil, color: UIColor(model.color), size: CGSize.zero)
        self.name = model.name
        self.setDefaultPose()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDefaultPose() {
        
        self.position = model.position
        self.zRotation = model.rotation * degreeToRadiansFactor
        self.xScale = model.scale.dx
        self.yScale = model.scale.dy
    }
}
