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
    
    init(_ model: SkinModel, atlas folder: String?) {
        
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
    
    func attachment(_ model: AttachmentModelType) -> Attachment? {
        
        if AttachmentBuilder.textureRequired(for: model) {
            
            guard let attachmentAtlasName = atlasName(for: model),
                let textureName = textureName(for: model),
                let texture = texture(with: textureName, from: attachmentAtlasName) else {
                    
                    return nil
            }
            
            return AttachmentBuilder.attachment(for: model, texture)
            
        } else {
            
            return AttachmentBuilder.attachment(for: model)
        }
    }
    
    func texture(with name: String, from atlasName: String) -> SKTexture? {
        
        guard let atlas = atlases?[atlasName],
              let textureName = atlas.textureNames.first(where: { $0.contains(name) }) else {
            
            return nil
        }

        return atlas.textureNamed(textureName)
    }
}

//MARK: - Atlases Names Helpers

func textureName(from name: String, actualName: String? , path: String?) -> String {
    
    let resultName = path ?? actualName ?? name
    let splittedResultName = resultName.components(separatedBy: "/")
    
    return splittedResultName.last ?? name
}

func textureName(for attachmentType: AttachmentModelType ) -> String? {
    
    switch attachmentType {
    case .region(let region): return textureName(from: region.name, actualName: region.actualName, path: region.path)
    case .mesh(let mesh): return textureName(from: mesh.name, actualName: mesh.actualName, path: mesh.path)
    case .linkedMesh(let linkedMesh): return textureName(from: linkedMesh.name, actualName: linkedMesh.actualName, path: linkedMesh.path)
    default: return nil
    }
}

func atlasName(from name: String, actualName: String?, path: String?) -> String {
    
    let nameWithPath = path ?? actualName ?? name
    var nameWithPathSplitted = nameWithPath.components(separatedBy: "/")
    
    if nameWithPathSplitted.count > 1 {
        
        nameWithPathSplitted.removeLast()
        return nameWithPathSplitted.joined(separator: "/")
        
    } else {
        
        return "default"
    }
}

func atlasName(for attachmentType: AttachmentModelType ) -> String? {
    
    switch attachmentType {
    case .region(let region): return atlasName(from: region.name, actualName: region.actualName, path: region.path)
    case .mesh(let mesh): return atlasName(from: mesh.name, actualName: mesh.actualName, path: mesh.path)
    case .linkedMesh(let linkedMesh): return atlasName(from: linkedMesh.name, actualName: linkedMesh.actualName, path: linkedMesh.path)
    default: return nil
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
            
            guard let attachmentAtlasName = atlasName(for: attachment) else {
                
                continue
            }
            
            names.insert(attachmentAtlasName)
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
