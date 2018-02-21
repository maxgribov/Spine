//
//  Skeleton+Physics.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension Skeleton {

    /**
     Sets the bit masks for the categories and collisions for all of the physical bodies of the skeleton
     
     - parameter category: defines what logical 'categories' all skeleton's bodies belongs to
     - parameter collision: defines what logical 'categories' of bodies this skeleton responds to collisions with
     */
    public func setBitMasks(category: UInt32, collision: UInt32) {
        
        if let slots = slots {
            
            for slot in slots {
                
                slot.physicsBody?.categoryBitMask = category
                slot.physicsBody?.collisionBitMask = collision
            }
        }
    }
    
    /**
     Sets the bit masks for the categories for all of the physical bodies of the skeleton
     
     - parameter mask: defines what logical 'categories' all skeleton's bodies belongs to
     */
    public func setCategoryBitMask(_ mask: UInt32) {
        
        if let slots = slots {
            
            for slot in slots {
                
                slot.physicsBody?.categoryBitMask = mask
            }
        }
    }
    
    /**
     Sets the bit masks for collisions for all of the physical bodies of the skeleton
     
     - parameter mask: defines what logical 'categories' of bodies this skeleton responds to collisions with
     */
    public func setCollisionBitMask(_ mask: UInt32) {
        
        if let slots = slots {
            
            for slot in slots {
                
                slot.physicsBody?.collisionBitMask = mask
            }
        }
    }
}
