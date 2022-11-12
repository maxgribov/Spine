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

        var atlases = [String : SKTextureAtlas]()
        
        for atlasName in model.atlasesNames() {

            var atlasPath = atlasName
            
            if let folder = folder {
                
                atlasPath = "\(folder)/\(atlasName)"
            }
            
            atlases[atlasName] = SKTextureAtlas(named: atlasPath)
        }
        
        self.atlases = atlases
    }
    
    init(_ model: SkinModel, _ atlases: [String : SKTextureAtlas]) {
        
        self.model = model
        self.atlases = atlases
    }
    
    func attachment(_ model: AttachmentModelType) -> Attachment? {
        
        if model.isTextureRequired == true {
            
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
              let textureName = atlas.textureNames.first(where: { $0 == name }) else {
            
            return nil
        }

        return atlas.textureNamed(textureName)
    }
}

//MARK: - Atlases Names Helpers

//TODO: refactor
func textureName(from name: String, fileName: String? , path: String?) -> String {
    
    let resultName = path ?? fileName ?? name
    let splittedResultName = resultName.components(separatedBy: "/")
    
    return splittedResultName.last ?? name
}

func textureName(for attachmentType: AttachmentModelType ) -> String? {
    
    switch attachmentType {
    case .region(let region): return textureName(from: region.name, fileName: region.fileName, path: region.path)
    case .mesh(let mesh): return textureName(from: mesh.name, fileName: mesh.fileName, path: mesh.path)
    case .linkedMesh(let linkedMesh): return textureName(from: linkedMesh.name, fileName: linkedMesh.fileName, path: linkedMesh.path)
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
    case .region(let region): return atlasName(from: region.name, actualName: region.fileName, path: region.path)
    case .mesh(let mesh): return atlasName(from: mesh.name, actualName: mesh.fileName, path: mesh.path)
    case .linkedMesh(let linkedMesh): return atlasName(from: linkedMesh.name, actualName: linkedMesh.fileName, path: linkedMesh.path)
    default: return nil
    }
}
