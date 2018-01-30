//
//  SkinModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

struct SkinModel {
    
    let name: String
    let slots: [SkinSlotModel]
}

extension SkinModel: Decodable {
    
    enum SkinModelDecodingError: Error {
        
        case skinNameMissed
        case slotNameMissed
        case attachmentNameMissed
        case attachmentTypeUnknown
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: SpineNameKey.self)
        
        guard let skinName = container.allKeys.first?.stringValue,
            let skinKey = SpineNameKey(stringValue: skinName) else {
                
                throw SkinModelDecodingError.skinNameMissed
        }

        // Slots
        let slotsContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: skinKey)
        
        var slots = [SkinSlotModel]()
        
        for slot in slotsContainer.allKeys {
            
            guard let slotKey = SpineNameKey(stringValue: slot.stringValue) else {
                
                throw SkinModelDecodingError.slotNameMissed
            }
            
            //attachments
            let attachmentsContainer = try slotsContainer.nestedContainer(keyedBy: SpineNameKey.self, forKey: slotKey)
            
            var attachments = [AttachmentModelType]()
            
            for attachment in attachmentsContainer.allKeys {
                
                guard let attachmentKey = SpineNameKey(stringValue: attachment.stringValue),
                      let attachmentTypeKey =  SpineNameKey(stringValue: "type") else {
                    
                    throw SkinModelDecodingError.attachmentNameMissed
                }
                
                let attachmentContainer = try attachmentsContainer.nestedContainer(keyedBy: SpineNameKey.self, forKey: attachmentKey)
                let attachmentTypeString: String? = try attachmentContainer.decodeIfPresent(String.self, forKey: attachmentTypeKey)
                
                guard let attachmentType = AttachmentModelType.Keys(attachmentTypeString) else {
                    
                    throw SkinModelDecodingError.attachmentTypeUnknown
                }
                
                switch attachmentType {
                    
                default:
                    let regionAttachmentContainer = try attachmentsContainer.nestedContainer(keyedBy: RegionAttachmentModel.Keys.self, forKey: attachmentKey)
                    let name = attachment.stringValue
                    let path: String? = try regionAttachmentContainer.decodeIfPresent(String.self, forKey: .path)
                    let x: CGFloat? = try regionAttachmentContainer.decodeIfPresent(CGFloat.self, forKey: .x)
                    let y: CGFloat? = try regionAttachmentContainer.decodeIfPresent(CGFloat.self, forKey: .y)
                    let scaleX: CGFloat? = try regionAttachmentContainer.decodeIfPresent(CGFloat.self, forKey: .scaleX)
                    let scaleY: CGFloat? = try regionAttachmentContainer.decodeIfPresent(CGFloat.self, forKey: .scaleY)
                    let rotation: CGFloat? = try regionAttachmentContainer.decodeIfPresent(CGFloat.self, forKey: .rotation)
                    let width: CGFloat? = try regionAttachmentContainer.decodeIfPresent(CGFloat.self, forKey: .width)
                    let height: CGFloat? = try regionAttachmentContainer.decodeIfPresent(CGFloat.self, forKey: .height)
                    let color: String? = try regionAttachmentContainer.decodeIfPresent(String.self, forKey: .color)
                    
                    attachments.append(AttachmentModelType.region(RegionAttachmentModel(name, path, x, y, scaleX, scaleY, rotation, width, height, color)))
                }
            }
            
            slots.append(SkinSlotModel(name: slot.stringValue, attachments: attachments))
        }
        
        self.name = skinName
        self.slots = slots
    }
}

struct SkinSlotModel {
    
    let name: String
    let attachments: [AttachmentModelType]
}

//MARK: - Attachments

enum AttachmentModelType {
    
    case region(RegionAttachmentModel)
    case boundingBox(BoundingBoxAttachmentModel)
    case mesh (MeshAttachmentModel)
    case linkedMesh(LinkedMeshAttachmentModel)
    case path(PathAttachmentModel)
    case point(PointAttachmentModel)
    case clipping(ClippingAttachmentModel)
    
    enum Keys: String {
        
        case region
        case boundingBox = "boundingbox"
        case mesh
        case linkedMesh = "linkedmesh"
        case path
        case point
        case clipping
        
        init?(_ value: String?) {
            
            let typeValue = value ?? "region"
            
            guard let type = Keys(rawValue: typeValue) else {
                
                return nil
            }
            
            self = type
        }
    }
}

protocol AttachmentModel {

    var name: String { get }
}

struct RegionAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String?
    let position: CGPoint
    let scale: CGVector
    let rotation: CGFloat
    let size: CGSize
    let color: ColorModel
    
    enum Keys: String, CodingKey {
        
        case path
        case x
        case y
        case scaleX
        case scaleY
        case rotation
        case width
        case height
        case color
    }
    
    init(_ name: String, _ path: String?, _ x: CGFloat?, _ y: CGFloat?, _ scaleX: CGFloat?, _ scaleY: CGFloat?, _ rotation: CGFloat?, _ width: CGFloat?, _ height: CGFloat?, _ color: String?) {
        
        self.name = name
        self.path = path
        self.position = CGPoint(x: x ?? 0, y: y ?? 0)
        self.scale = CGVector(dx: scaleX ?? 1.0, dy: scaleY ?? 1.0)
        self.rotation = rotation ?? 0
        self.size = CGSize(width: width ?? 0, height: height ?? 0)
        self.color = ColorModel(color ?? "FFFFFFFF")
    }
}

struct MeshAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String
    let uvs: [CGFloat]
    let triangles: [UInt]
    let vertices: [CGFloat]
    let hull: UInt
    let edges: [UInt]?
    let color: ColorModel
    let size: CGSize?
    
    init(_ name: String, _ path: String, _ uvs: [CGFloat], _ triangles: [UInt], _ vertices: [CGFloat], _ hull: UInt, _ edges: [UInt]?, _ color: String = "FFFFFFFF", _ width: CGFloat?, _ height: CGFloat?) {
        
        self.name = name
        self.path = path
        self.uvs = uvs
        self.triangles = triangles
        self.vertices = vertices
        self.hull = hull
        self.edges = edges
        self.color = ColorModel(color)
        self.size = CGSize(width, height)
    }
}

struct LinkedMeshAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String?
    let skin: String?
    let parent: String?
    let deform: Bool
    let color: ColorModel
    let size: CGSize?
    
    init(_ name: String, _ path: String?, _ skin: String?, _ parent: String?, _ deform: Bool = true, _ color: String = "FFFFFFFF", _ width: CGFloat?, _ height: CGFloat?) {
        
        self.name = name
        self.path = path
        self.skin = skin
        self.parent = parent
        self.deform = deform
        self.color = ColorModel(color)
        self.size = CGSize(width, height)
    }
}

struct BoundingBoxAttachmentModel: AttachmentModel {
    
    let name: String
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
    
    init(_ name: String, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String = "60F000FF") {
        
        self.name = name
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color)
    }
}

struct PathAttachmentModel: AttachmentModel {
    
    let name: String
    let closed: Bool
    let constantSpeed: Bool
    let lengths: [CGFloat]
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
    
    init(_ name: String, _ closed: Bool = false, _ constantSpeed: Bool = true, _ lengths: [CGFloat], _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String = "FF7F00FF") {
        
        self.name = name
        self.closed = closed
        self.constantSpeed = constantSpeed
        self.lengths = lengths
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color)
    }
}

struct PointAttachmentModel: AttachmentModel {

    let name: String
    let point: CGPoint
    let rotation: CGFloat
    let color: ColorModel
    
    init(_ name: String, _ x: CGFloat, _ y: CGFloat, _ rotation: CGFloat, _ color: String = "F1F100FF") {
        
        self.name = name
        self.point = CGPoint(x: x, y: y)
        self.rotation = rotation
        self.color = ColorModel(color)
    }
}

struct ClippingAttachmentModel: AttachmentModel {
    
    let name: String
    let end: Int
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
    
    init(_ name: String, _ end: Int, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String = "CE3A3AFF") {
        
        self.name = name
        self.end = end
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color)
    }
}
