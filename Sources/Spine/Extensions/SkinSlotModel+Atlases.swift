//
//  SkinSlotModel+Atlases.swift
//  Spine
//
//  Created by Max Gribov on 06/07/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension SkinSlotModel {
    
    func atlasesNames() -> [String] {
        
        var names = Set<String>()
        for attachment in attachments {
            
            guard let attachmentAtlasName = atlasName(for: attachment) else {
                
                continue
            }
            
            names.insert(attachmentAtlasName)
        }

        return Array(names)
    }
}
