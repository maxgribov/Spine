//
//  Attachment.swift
//  Spine
//
//  Created by Max Gribov on 07/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

typealias SKNodeNamePrefix = SKNode & Prefixable & Defaultable

protocol Attachment: SKNodeNamePrefix {

    var model: AttachmentModel { get }
}

extension Attachment {
    
    static var prefix: String { get { return "attachment:" } }
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

    var model: AttachmentModel { get { return concreteModel } }
    let concreteModel: RegionAttachmentModel
    
    init(_ model: RegionAttachmentModel, _ texture: SKTexture) {
        
        self.concreteModel = model
        super.init(texture: texture, color: UIColor(model.color), size: model.size)
        self.name = RegionAttachment.generateName(model.name)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.dropToDefaults()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Defaultable
    
    func dropToDefaults() {
        
        self.position = concreteModel.position
        self.zRotation = concreteModel.rotation * degreeToRadiansFactor
        self.xScale = concreteModel.scale.dx
        self.yScale = concreteModel.scale.dy
    }
}
