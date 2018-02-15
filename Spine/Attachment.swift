//
//  Attachment.swift
//  Spine
//
//  Created by Max Gribov on 07/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

typealias SKNodeNamePrefix = SKNode & NamePrefix

protocol Attachment: SKNodeNamePrefix {

}

extension Attachment {
    
    static var namePrefix: String {
        get{
            return "attachment:"
        }
    }
}

class AttachmentBuilder {
    
    class func attachment(of type: AttachmentModelType, texture: SKTexture) -> Attachment? {
        
        switch type {
        case .region(let regionModel): return RegionAttachment(regionModel, texture)
        default: return nil
        }
    }
    
    class func attachment(of type: AttachmentModelType) -> Attachment? {
        
        return nil
    }
    
    class func textureRequired(for type: AttachmentModelType) -> Bool {
        
        switch type {
        case .region(_), .mesh(_), .linkedMesh(_): return true
        default:
            return false
        }
    }
}

class RegionAttachment: SKSpriteNode, Attachment {

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