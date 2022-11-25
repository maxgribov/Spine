//
//  Skeleton+Atlases.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public extension Skeleton {
    
    /**
     A list of all texture atlases for all of the `Slots` of the `Skeleton`.
     Each atlas is represented only once.
     */
    var atlases: [SKTextureAtlas] {
            
        skins.map { skin in
            
            skin.atlases.keys.compactMap { atlasName in
                
                skin.atlases[atlasName]
            }
            
        }.reduce(Set<SKTextureAtlas>()) { partialResult, atlas in
            
            partialResult.union(atlas)
            
        }.reduce([SKTextureAtlas]()) { partialResult, atlas in
            
            var result = partialResult
            result.append(atlas)
            
            return result
        }
    }
    
    /**
     Preloads all the atlases for the 'Skeleton' and invokes the callback
     
     - parameter completionHandler: the closure that is called when the preload is complete.
     - parameter succeed: preload operation completion flag
     */
    func preloadTextureAtlases(withCompletionHandler completionHandler: @escaping () -> Void) {
        
        SKTextureAtlas.preloadTextureAtlases(atlases) {
            
            completionHandler()
        }
    }
    
    /**
     Preloads all the atlases for the `Skeletons` in list and invokes the callback
     
     - parameter skeletons: list of skeletons whose atlases will be preloaded.
     - parameter completionHandler: the closure that is called when the preload is complete.
     */
    class func preloadTextureAtlases(_ skeletons: [Skeleton], withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let atlases = skeletons.map { skeleton in
            
            skeleton.atlases
            
        }.reduce(Set<SKTextureAtlas>()) { partialResult, atlases in
            
            partialResult.union(atlases)
        }

        SKTextureAtlas.preloadTextureAtlases(Array(atlases)) {
            
            completionHandler()
        }
    }
}
