//
//  SKAction+Spine.swift
//  Spine
//
//  Created by Max Gribov on 21/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension SKAction {
    
    class func run(_ action: SKAction, onChildWithName name: String, inheritDuration: Bool) -> SKAction {
        
        if inheritDuration {
            
            let newAction = SKAction.run(action, onChildWithName: name)
            newAction.duration = action.duration
            
            return newAction
            
        } else {
            
            return SKAction.run(action, onChildWithName: name)
        }
    }
}
