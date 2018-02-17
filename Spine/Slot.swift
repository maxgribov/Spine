//
//  Slot.swift
//  Spine
//
//  Created by Max Gribov on 07/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

class Slot: SKNode, Prefixable, Defaultable {
    
    public static let prefix = "slot:"
    let model: SlotModel
    
    init(_ model: SlotModel) {
        
        self.model = model
        super.init()
        self.name = Slot.generateName(model.name)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Defaultable
    
    func dropToDefaults() {
        
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
