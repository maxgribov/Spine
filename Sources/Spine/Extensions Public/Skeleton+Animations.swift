//
//  Skeleton+Animations.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public extension Skeleton {
    
    /**
     A list of all available animation names for this skeleton `Skeleton`.
     */
    var animationsNames: [String] { meshRuntime?.asset.animationNames ?? animations.map({ $0.name }) }
    
    /**
     Returns a `SKAction` for animation with a specific name.

     In mesh-aware mode, this action and its copies or action containers must run
     on the Skeleton that created it. Running them on another node is unsupported;
     receiver validation and mutation safety are not guaranteed for that misuse.
     
     - parameter named: the name of the animation.
     
     - throws: error if animation with this name can't be found.
     */
    func action(animation name: String) throws -> SKAction {
        if let runtime = meshRuntime { return try runtime.action(named: name, owner: self) }
        
        guard let animation = animations.first(where: { $0.name == name }) else {
            throw SpineError.missingAnimatonNamed(name)
        }
        
        return animation.action
    }
    
    /**
     Runs action for animation with a specific name.
     
     - parameter named: the name of the animation.
     
     - throws: error if animation with this name can't be found.
     */
    func run(animation name: String) throws {
        
        run(try action(animation: name))
    }
    
    /**
     Returns a `SKAction` for animation with a specific name if possible.
     
     - parameter named: the name of the animation.
     */
    @available(*, deprecated, message: "Use 'action(animation:)' instead")
    func animation(named: String) -> SKAction? {
        
        return try? action(animation: named)
    }
    
    /**
     Returns a `SKAction` that stops all animations and resets all skeleton parameters to the default state.
     */
    func dropToDefaultsAction() -> SKAction {
        
        SKAction.run { [weak self] in  self?.dropToDefaults() }
    }
}
