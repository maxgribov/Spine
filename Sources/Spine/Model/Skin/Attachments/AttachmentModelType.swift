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
}
