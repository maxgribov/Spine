//
//  Skeleton+Atlases.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension Skeleton {
    
    /**
     A list of all texture atlases for all of the `Slots` of the `Skeleton`.
     Each atlas is represented only once.
     */
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
    
    /**
     Preloads all the atlases for the 'Skeleton' and invokes the callback
     
     - parameter completionHandler: the closure that is called when the preload is complete.
     - parameter succeed: preload operation completion flag
     */
    public func preloadTextureAtlases(withCompletionHandler completionHandler: @escaping (_ succeed: Bool) -> Swift.Void){
        
        guard let atlases = atlases else {
            
            completionHandler(false)
            return
        }
        
        SKTextureAtlas.preloadTextureAtlases(atlases) {
            
            completionHandler(true)
        }
    }
    
    /**
     Preloads all the atlases for the `Skeletons` in list and invokes the callback
     
     - parameter skeletons: list of skeletons whose atlases will be preloaded.
     - parameter completionHandler: the closure that is called when the preload is complete.
     */
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
