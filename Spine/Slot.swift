//
//  Slot.swift
//  Spine
//
//  Created by Max Gribov on 07/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

class Slot: SKNode, Prefixable, Defaultable {
    
    static let prefix = "slot:"
    let model: SlotModel
    let initialOrder: Int
    
    init(_ model: SlotModel, _ order: Int) {
        
        self.model = model
        self.initialOrder = order
        super.init()
        self.name = Slot.generateName(model.name)
    }
    
    func setOrder(to order: Int) {
        
        self.zPosition = CGFloat(order) * 0.01
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Defaultable
    
    func dropToDefaults() {
        
        setOrder(to: initialOrder)
        
        if let sprites = children.filter({ $0 is RegionAttachment }) as? [RegionAttachment] {

            for sprite in sprites {

                sprite.setColor(with: model.color)
                sprite.colorBlendFactor = 1.0
                sprite.isHidden = sprite.model.name == model.attachment ? false : true
            }
        }
        
        if let points = children.filter({ $0 is PointAttachment }) as? [PointAttachment] {
            
            for point in points {

                point.isHidden = true
            }
        }
    }
}
