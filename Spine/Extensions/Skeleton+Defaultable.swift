//
//  Skeleton+Defaultable.swift
//  Spine
//
//  Created by Max Gribov on 21/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension Skeleton: Defaultable {
    
    func dropToDefaults() {
        
        for child in self[".//*"] {
            
            if child.hasActions() {
                
                child.removeAllActions()
            }
            
            if let defaultableChild = child as? Defaultable {
                
                defaultableChild.dropToDefaults()
            }
        }
    }
}
