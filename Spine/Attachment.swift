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
    
    class func attachment(for type: AttachmentModelType, _ texture: SKTexture? = nil) -> Attachment? {
        
        switch type {
        case .region(let regionModel):
            guard let texture = texture else {
                return nil
            }
            return RegionAttachment(regionModel, texture)
        case .boundingBox(let boundingBoxModel): return BoundingBoxAttachment(boundingBoxModel)
        case .point(let pointModel): return PointAttachment(pointModel)
        default: return nil
        }
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
        super.init(texture: texture, color: createColor(with: model.color), size: model.size)
        self.name = RegionAttachment.generateName(model.name)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.dropToDefaults()
    }
    
    func setColor(with model: ColorModel) {
        
        let resultColorModel = concreteModel.color.mix(with: model)
        self.color = createColor(with: resultColorModel)
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

class BoundingBoxAttachment: SKShapeNode, Attachment {
    
    var model: AttachmentModel { get { return concreteModel } }
    let concreteModel: BoundingBoxAttachmentModel

    init(_ model: BoundingBoxAttachmentModel) {
        
        self.concreteModel = model
        super.init()
        
        if let path = CGPath.path(with: model.vertices) {
            
            self.path = path
            self.fillColor = createColor(with: model.color)
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
        self.name = PointAttachment.generateName(model.name)
        let circleRadius: CGFloat = 5.0
        let curcleRect = CGRect(x: -circleRadius, y: -circleRadius, width: circleRadius * 2, height: circleRadius * 2)
        self.path = CGPath(ellipseIn: curcleRect, transform: nil)
        self.fillColor = createColor(with: concreteModel.color)
        self.dropToDefaults()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Defaultable
    
    func dropToDefaults() {
        
        self.position = concreteModel.point
        self.zRotation = concreteModel.rotation * degreeToRadiansFactor
    }
}
