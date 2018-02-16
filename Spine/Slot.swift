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
        
        if let sprites = children.filter({ $0 is SKSpriteNode }) as? [SKSpriteNode] {
            
            for sprite in sprites {
                
                sprite.color = Slot.color(with: model.color)
                sprite.colorBlendFactor = Slot.colorBlendFactor(with: model.color)
                sprite.alpha = Slot.alpha(with: model.color)
            }
        }
    }
    
    //TODO:  find a better place for this methods in the future
    
    class func color(with model: ColorModel) -> UIColor {
        
        return UIColor(red: model.red, green: model.green, blue: model.blue, alpha: 1.0)
    }
    
    class func colorBlendFactor(with model: ColorModel) -> CGFloat {
        
        //color default value is FFFFFFFF... if color part if FFFFFF (means white) so we don't need apply color to sprite
        return model.value.hasPrefix("FFFFFF") ? 0 : 1.0
    }

    class func alpha(with model: ColorModel) -> CGFloat {
        
        return model.alpha
    }
}
