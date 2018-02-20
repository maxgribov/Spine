//
//  Skeleton+Animations.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public extension Skeleton {

    public var animationsNames: [String]? {
        get {
            guard let animations = animations else {
                return nil
            }
            
            return animations.map({ $0.name })
        }
    }
    
    public func animation(named: String) -> SKAction? {
        
        guard let animation = animations?.first(where: { $0.name == named }) else {
            
            return nil
        }
        
        return animation.action
    }
    
    public func runAnimation(named: String) {
        
        if let animation = animation(named: named) {
            
            self.run(animation)
        }
    }
}
