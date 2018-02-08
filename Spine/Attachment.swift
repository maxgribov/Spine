//
//  Attachment.swift
//  Spine
//
//  Created by Max Gribov on 07/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

protocol Attachment: NamePrefix {
    
}

class RegionAttachment: SKSpriteNode, Attachment {
    
    public static let namePrefix = "attachment:"
    let model: RegionAttachmentModel
    
    init(_ model: RegionAttachmentModel, _ texture: SKTexture) {
        
        self.model = model
        super.init(texture: texture, color: UIColor(model.color), size: model.size)
        self.name = RegionAttachment.generateName(model.name)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
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
