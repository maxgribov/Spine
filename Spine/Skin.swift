//
//  Skin.swift
//  Spine
//
//  Created by Max Gribov on 08/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

class Skin {
    
    let model: SkinModel
    let atlases: [String : SKTextureAtlas]?
    
    init(_ model: SkinModel, _ folder: String?) {
        
        self.model = model
        
        guard let atlasesNames = atlasesNames(from: model) else {
            
            self.atlases = nil
            return
        }
        
        var atlases = [String : SKTextureAtlas]()
        
        for atlasName in atlasesNames {

            var atlasPath = atlasName
            
            if let folder = folder {
                
                atlasPath = "\(folder)/\(atlasName)"
            }
            
            atlases[atlasName] = SKTextureAtlas(named: atlasPath)
        }
        
        self.atlases = atlases
    }
}

//MARK: - Atlases Names Helpers

func atlasName(from name: String, path: String?) -> String {
    
    let actualName = path ?? name
    var actualNameSplitted = actualName.components(separatedBy: "/")
    
    if actualNameSplitted.count > 1 {
        
        actualNameSplitted.removeLast()
        return actualNameSplitted.joined(separator: "/")
        
    } else {
        
        return "default"
    }
}

func atlasesNames(from skin: SkinModel) -> [String]? {

    guard let slots = skin.slots else {
        
        return nil
    }
    
    var names = Set<String>()
    
    for slot in slots {
        
        guard let attachments = slot.attachments else {
            
            continue
        }
        
        for attachment in attachments {
            
            switch attachment {
            case .region(let region):
                names.insert(atlasName(from: region.name, path: region.path))
            case .mesh(let mesh):
                names.insert(atlasName(from: mesh.name, path: mesh.path))
            case .linkedMesh(let linkedMesh):
                names.insert(atlasName(from: linkedMesh.name, path: linkedMesh.path))
            default:
                continue
                
            }
        }
    }
    
    return Array(names)
}

func atlasesNames(from skins: [SkinModel]? ) -> [String]? {
    
    guard let skins = skins else {
        
        return nil
    }
    
    var names = Set<String>()
    
    for skin in skins {
        
        guard let skinNames = atlasesNames(from: skin) else {
            continue
        }
        
        names = names.union(Set(skinNames))
    }
    
    return Array(names)
}
