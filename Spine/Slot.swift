//
//  Slot.swift
//  Spine
//
//  Created by Max Gribov on 07/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

class Slot: SKNode, NamePrefix {
    
    public static let namePrefix = "slot:"
    let model: SlotModel
    
    init(_ model: SlotModel) {
        
        self.model = model
        super.init()
        self.name = Slot.generateName(model.name)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
