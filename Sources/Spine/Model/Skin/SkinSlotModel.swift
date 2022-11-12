//
//  SkinSlotModel.swift
//  
//
//  Created by Max Gribov on 06.11.2022.
//

import SpriteKit

struct SkinSlotModel {
    
    let name: String
    let attachments: [AttachmentModelType]
}

extension SkinSlotModel: SpineDecodableDictionary {

    typealias KeysType = SpineNameKey
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var attachments = [AttachmentModelType]()
        
        for attachmentKey in container.allKeys {
            
            let attachmentContainer = try container.nestedContainer(keyedBy: AttachmentModelKeys.self, forKey: attachmentKey)
            let attachmentType = try attachmentContainer.decodeIfPresent(AttachmentModelTypeKeys.self, forKey: AttachmentModelKeys.type) ?? .region
            
            let name = attachmentKey.stringValue
            
            switch attachmentType {
            case .region:
                let container = try container.nestedContainer(keyedBy: RegionAttachmentModel.Keys.self, forKey: attachmentKey)
                let attachment = try RegionAttachmentModel(name, container)
                attachments.append(.region(attachment))
                
            case .boundingBox:
                let container = try container.nestedContainer(keyedBy: BoundingBoxAttachmentModel.Keys.self, forKey: attachmentKey)
                let attachment = try BoundingBoxAttachmentModel(name, container)
                attachments.append(.boundingBox(attachment))
                
            case .mesh:
                let container = try container.nestedContainer(keyedBy: MeshAttachmentModel.Keys.self, forKey: attachmentKey)
                let attachment = try MeshAttachmentModel(name, container)
                attachments.append(.mesh(attachment))
                
            case .linkedMesh:
                let container = try container.nestedContainer(keyedBy: LinkedMeshAttachmentModel.Keys.self, forKey: attachmentKey)
                let attachment = try LinkedMeshAttachmentModel(name, container)
                attachments.append(.linkedMesh(attachment))
                
            case .path:
                let container = try container.nestedContainer(keyedBy: PathAttachmentModel.Keys.self, forKey: attachmentKey)
                let attachment = try PathAttachmentModel(name, container)
                attachments.append(.path(attachment))
                
            case .point:
                let container = try container.nestedContainer(keyedBy: PointAttachmentModel.Keys.self, forKey: attachmentKey)
                let attachment = try PointAttachmentModel(name, container)
                attachments.append(.point(attachment))
                
            case .clipping:
                let container = try container.nestedContainer(keyedBy: ClippingAttachmentModel.Keys.self, forKey: attachmentKey)
                let attachment = try ClippingAttachmentModel(name, container)
                attachments.append(.clipping(attachment))
            }
        }
        
        self.name = name
        self.attachments = attachments
    }
}
