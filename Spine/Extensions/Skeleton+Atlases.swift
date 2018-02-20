//
//  Skeleton+Atlases.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension Skeleton {
    
    public var atlases: [SKTextureAtlas]? {
        get {
            
            var atlasesMutable = [SKTextureAtlas]()
            
            guard let skins = skins else {
                
                return nil
            }
            
            for skin in skins {
                
                guard let skinAtlaces = skin.atlases else {
                    
                    continue
                }
                
                for atlasName in skinAtlaces.keys {
                    
                    if let atlas = skinAtlaces[atlasName] {
                        
                        atlasesMutable.append(atlas)
                    }
                }
            }
            
            return atlasesMutable
        }
    }
}
