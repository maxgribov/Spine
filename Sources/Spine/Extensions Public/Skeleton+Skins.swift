//
//  Skeleton+Skins.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public extension Skeleton {
    
    var skinsNames: [String] { skins.map { $0.name } }
    
    /**
     Applies *default* skin.
     
     See more information about skins:
     http://esotericsoftware.com/spine-skins
     
     - throws: error if default skin can't be found.
     */
    func applyDefaultSkin() throws {
        
        apply(skin: try skin(named: SpineModel.defaultSkinName))
    }
    
    /**
     Applies a skin with a specific name.
     
     See more information about skins:
     http://esotericsoftware.com/spine-skins
     
     - parameter named: The name of the skin you want to apply.
     - throws: error if a skin can't be found.
     */
    func apply(skin named: String) throws {
        
        apply(skin: try skin(named: named))
    }
    
    /**
     Creates 'SKAction' that applyes skin. This action can be run on skeleton, like any other 'SKAction'.
     
     See more information about skins:
     http://esotericsoftware.com/spine-skins
     
     - parameter applySkin: The name of the skin you want to apply.
     - returns: action than applyes skin if it run on skeleton.
     - throws: error if a skin can't be found.
     */
    func action(applySkin name: String) throws -> SKAction {
        
        let skin = try skin(named: name)
        
        return SKAction.run { [weak self] in self?.apply(skin: skin) }
    }
    
    /**
     Applies a skin with a specific name if possible. Attachments that belong to the 'default' skin will be added to the slots anyway.
     
     See more information about skins:
     http://esotericsoftware.com/spine-skins
     
     - parameter named: The name of the skin you want to apply.
     If a skin with that name is not found or skipped it will be added only attachments for the 'default' skin.
     */
    @available(*, deprecated, message: "Use 'apply(skin:)' or 'applyDefaultSkin()' instead")
    func applySkin(named: String? = nil) {
        
        try? applyDefaultSkin()

        if let named = named {
            
            try? apply(skin: named)
        }
    }
}
