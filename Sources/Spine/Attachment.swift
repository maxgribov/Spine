//
//  Attachment.swift
//  Spine
//
//  Created by Max Gribov on 07/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

typealias SKNodeNamePrefix = SKNode & Prefixable & Defaultable

protocol Attachment: SKNodeNamePrefix {}

extension Attachment {
    
    static var prefix: String { get { return "attachment:" } }
}

//MARK: - Attachments

class RegionAttachment: SKSpriteNode, Attachment {

    let model: RegionAttachmentModel
    
    init(_ model: RegionAttachmentModel, _ texture: SKTexture) {
        
        self.model = model
        super.init(texture: texture, color: model.color.skColor, size: model.size)
        self.name = RegionAttachment.generateName(model.name)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.dropToDefaults()
    }
    
    func setColor(with colorModel: ColorModel) {
        
        self.color = model.color.add(color: colorModel).skColor
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

class BoundingBoxAttachment: SKShapeNode, Attachment {
    
    var model: AttachmentModel { get { return concreteModel } }
    let concreteModel: BoundingBoxAttachmentModel

    init(_ model: BoundingBoxAttachmentModel) {
        
        self.concreteModel = model
        super.init()
        
        if let path = CGPath.path(with: model.vertices) {
            
            self.path = path
            self.fillColor = model.color.skColor
            self.zPosition = 100.0
            self.alpha = 0.5
            
            let physicsBody = SKPhysicsBody(polygonFrom: path)
            physicsBody.isDynamic = false
            self.physicsBody = physicsBody
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Defaultable
    
    func dropToDefaults() {

    }
}

class PointAttachment: SKShapeNode, Attachment {
    
    var model: AttachmentModel { get { return concreteModel } }
    let concreteModel: PointAttachmentModel
    
    init(_ model: PointAttachmentModel) {
        
        self.concreteModel = model
        super.init()
        let circleRadius: CGFloat = 5.0
        let curcleRect = CGRect(x: -circleRadius, y: -circleRadius, width: circleRadius * 2, height: circleRadius * 2)
        self.path = CGPath(ellipseIn: curcleRect, transform: nil)
        self.fillColor = concreteModel.color.skColor
        self.dropToDefaults()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Defaultable
    
    func dropToDefaults() {
        
        self.position = concreteModel.position
        self.zRotation = concreteModel.rotation * degreeToRadiansFactor
    }
}
