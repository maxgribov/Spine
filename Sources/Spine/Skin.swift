//
//  Skin.swift
//  Spine
//
//  Created by Max Gribov on 08/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

class Skin {
    
    var name: String { model.name }
    let model: SkinModel
    let atlases: [String : SKTextureAtlas]
    
    init(_ model: SkinModel, atlas folder: String?) {
        
        self.model = model

        var atlases = [String : SKTextureAtlas]()
        
        for atlasName in model.atlasesNames {

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
    
    func attachment(_ model: AttachmentModel) -> Attachment? {

        if let texturedModel = model as? AttachmentTexturedModel {
            
            guard let texture = texture(with: texturedModel.textureName, from: texturedModel.atlasName) else {
                    return nil
            }
            
            switch texturedModel {
            case let regionModel as RegionAttachmentModel:
                return RegionAttachment(regionModel, texture)
                
                //TODO: mesh and linked mesh
            default:
                return nil
            }
            
        } else {
            
            switch model {
            case let boundingBoxModel as BoundingBoxAttachmentModel:
                return BoundingBoxAttachment(boundingBoxModel)
            
            case let pointModel as PointAttachmentModel:
                return PointAttachment(pointModel)
                
                //TODO: rest models
            default:
                return nil
            }
        }
    }
    
    func texture(with name: String, from atlasName: String) -> SKTexture? {
        
        guard let atlas = atlases[atlasName],
              let textureName = atlas.textureNames.first(where: { $0 == name }) else {
            
            return nil
        }

        return atlas.textureNamed(textureName)
    }
}
