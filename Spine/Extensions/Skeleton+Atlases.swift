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
            
            var atlasesMutable = Set<SKTextureAtlas>()
            
            guard let skins = skins else {
                
                return nil
            }
            
            for skin in skins {
                
                guard let skinAtlaces = skin.atlases else {
                    
                    continue
                }
                
                for atlasName in skinAtlaces.keys {
                    
                    if let atlas = skinAtlaces[atlasName] {
                        
                        atlasesMutable.insert(atlas)
                    }
                }
            }
            
            return Array(atlasesMutable)
        }
    }
    
    public func preloadTextureAtlases(withCompletionHandler completionHandler: @escaping (_ succeed: Bool) -> Swift.Void){
        
        guard let atlases = atlases else {
            
            completionHandler(false)
            return
        }
        
        SKTextureAtlas.preloadTextureAtlases(atlases) {
            
            completionHandler(true)
        }
    }
    
    public class func preloadTextureAtlases(_ skeletons: [Skeleton], withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
        
        var atlasesMutable = Set<SKTextureAtlas>()
        
        for skeleton in skeletons {
            
            if let atlases = skeleton.atlases {
                
                atlasesMutable = atlasesMutable.union(atlases)
            }
        }
        
        SKTextureAtlas.preloadTextureAtlases(Array(atlasesMutable)) {
            
            completionHandler()
        }
    }
}
