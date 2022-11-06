//
//  AttachmentModelType.swift
//  
//
//  Created by Max Gribov on 06.11.2022.
//

import Foundation

enum AttachmentModelTypeKeys: String, Decodable {
    
    case region
    case boundingBox = "boundingbox"
    case mesh
    case linkedMesh = "linkedmesh"
    case path
    case point
    case clipping
}

enum AttachmentModelKeys: String, CodingKey {
    
    case type
}

enum AttachmentModelType {
    
    case region(RegionAttachmentModel)
    case boundingBox(BoundingBoxAttachmentModel)
    case mesh (MeshAttachmentModel)
    case linkedMesh(LinkedMeshAttachmentModel)
    case path(PathAttachmentModel)
    case point(PointAttachmentModel)
    case clipping(ClippingAttachmentModel)

    var model: AttachmentModel {
        
        switch self {
        case .region(let model): return model
        case .boundingBox(let model): return model
        case .mesh(let model): return model
        case .linkedMesh(let model): return model
        case .path(let model): return model
        case .point(let model): return model
        case .clipping(let model): return model
        }
    }
    
    var modelName: String {
        switch self {
        case .region(let model): return model.path ?? model.name
        case .boundingBox(let model): return model.name
        case .mesh(let model): return model.path ?? model.name
        case .linkedMesh(let model): return model.path ?? model.name
        case .path(let model): return model.name
        case .point(let model): return model.name
        case .clipping(let model): return model.name
        }
    }
}
