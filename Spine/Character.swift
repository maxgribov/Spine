//
//  Character.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public class Character: SKNode {
    
    var animations: [Animation]?
    public var animationsNames: [String]? {
        get{
            
            guard let animations = animations else {
                
                return nil
            }
            
            return animations.map({ $0.name })
        }
    }
    
    public init(_ model: SpineModel) {
        
        super.init()
        self.addChild(Skeleton(model))
        self.createAnimations(model)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createAnimations(_ model: SpineModel) {
        
        if let animations = model.animations {
            
            self.animations = animations.map({ Animation($0, model)})
        }
    }
    
    public func runAnimation(_ name: String) {
        
        guard let animation = animations?.filter({ $0.name == name }).first else {
            
            return
        }
        
        self.run(animation.action)
    }
}
