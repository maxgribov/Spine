//
//  SkinModel.swift
//  
//
//  Created by Max Gribov on 06.11.2022.
//

import SpriteKit

struct SkinModel {
    
    let name: String
    let slots: [Slot]
}

extension SkinModel {
    
    struct Slot {
        
        let name: String
        let attachments: [AttachmentModel]
    }
}

//MARK: - Helpers

extension SkinModel {
    
    var atlasesNames: Set<String> {
        
        slots.reduce(Set<String>()) { partialResult, slot in
            
            partialResult.union(slot.atlasesNames)
        }
    }
}

extension SkinModel.Slot {
    
    var atlasesNames: Set<String> {
        
        Set(attachments.compactMap({ $0 as? AttachmentTexturedModel }).map({ $0.atlasName }))
    }
}

//MARK: - Decoding

extension SkinModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case name
        case attachments
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        name = try container.decode(String.self, forKey: .name)
        
        let slotsContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: .attachments)
        
        var slots = [Slot]()
        
        for slotKey in slotsContainer.allKeys {
            
            let slotContainer = try slotsContainer.nestedContainer(keyedBy: Slot.KeysType.self, forKey: slotKey)
            let slot = try Slot(slotKey.stringValue, slotContainer)
            slots.append(slot)
        }

        self.slots = slots
    }
}


extension SkinModel.Slot: SpineDecodableDictionary {
    
    enum AttachmentKey: String, Decodable {
        
        case region
        case boundingBox = "boundingbox"
        case mesh
        case linkedMesh = "linkedmesh"
        case path
        case point
        case clipping
    }

    enum AttachmentType: String, CodingKey {
        
        case type
    }

    typealias KeysType = SpineNameKey
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var attachments = [AttachmentModel]()
        
        for attachmentKey in container.allKeys {
            
            let attachmentContainer = try container.nestedContainer(keyedBy: AttachmentType.self, forKey: attachmentKey)
            let attachmentType = try attachmentContainer.decodeIfPresent(AttachmentKey.self, forKey: AttachmentType.type) ?? .region
            
            let name = attachmentKey.stringValue
            
            switch attachmentType {
            case .region:
                let container = try container.nestedContainer(keyedBy: RegionAttachmentModel.Keys.self, forKey: attachmentKey)
                attachments.append(try RegionAttachmentModel(name, container))
                
            case .boundingBox:
                let container = try container.nestedContainer(keyedBy: BoundingBoxAttachmentModel.Keys.self, forKey: attachmentKey)
                attachments.append(try BoundingBoxAttachmentModel(name, container))
                
            case .mesh:
                let container = try container.nestedContainer(keyedBy: MeshAttachmentModel.Keys.self, forKey: attachmentKey)
                attachments.append(try MeshAttachmentModel(name, container))
                
            case .linkedMesh:
                let container = try container.nestedContainer(keyedBy: LinkedMeshAttachmentModel.Keys.self, forKey: attachmentKey)
                attachments.append(try LinkedMeshAttachmentModel(name, container))
                
            case .path:
                let container = try container.nestedContainer(keyedBy: PathAttachmentModel.Keys.self, forKey: attachmentKey)
                attachments.append(try PathAttachmentModel(name, container))
                
            case .point:
                let container = try container.nestedContainer(keyedBy: PointAttachmentModel.Keys.self, forKey: attachmentKey)
                attachments.append(try PointAttachmentModel(name, container))
                
            case .clipping:
                let container = try container.nestedContainer(keyedBy: ClippingAttachmentModel.Keys.self, forKey: attachmentKey)
                attachments.append(try ClippingAttachmentModel(name, container))
            }
        }
        
        self.name = name
        self.attachments = attachments
    }
}
