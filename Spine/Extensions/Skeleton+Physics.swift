//
//  Skeleton+Physics.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension Skeleton {

    public func setBitMasks(category: UInt32, collision: UInt32) {
        
        if let slots = slots {
            
            for slot in slots {
                
                slot.physicsBody?.categoryBitMask = category
                slot.physicsBody?.collisionBitMask = collision
            }
        }
    }
    
    public func setCategoryBitMask(_ mask: UInt32) {
        
        if let slots = slots {
            
            for slot in slots {
                
                slot.physicsBody?.categoryBitMask = mask
            }
        }
    }
    
    public func setCollisionBitMask(_ mask: UInt32) {
        
        if let slots = slots {
            
            for slot in slots {
                
                slot.physicsBody?.collisionBitMask = mask
            }
        }
    }
}
