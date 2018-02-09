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
    
    func attachment(named: String, slotName: String) -> Attachment? {
        
        guard let slotModel = model.slots?.first(where: { $0.name == slotName }),
              let attachmentType = slotModel.attachments?.first(where: { $0.modelName == named }) else {
            
            return nil
        }
        
        if AttachmentBuilder.textureRequired(for: attachmentType) {
            
            guard let attachmentAtlasName = atlasName(for: attachmentType),
                let texture = texture(with: textureName(from: attachmentType.modelName), from: attachmentAtlasName) else {
                    
                    return nil
            }
            
            return AttachmentBuilder.attachment(of: attachmentType, texture: texture)
            
        } else {
            
            return AttachmentBuilder.attachment(of: attachmentType)
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

func textureName(from name: String ) -> String {
    
    let splittedName = name.components(separatedBy: "/")
    
    return splittedName.last ?? name
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
