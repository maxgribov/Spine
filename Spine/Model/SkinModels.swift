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
    let slots: [SkinSlotModel]?
}

extension SkinModel: Decodable {
    
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
                
                guard let attachmentType = Keys(attachmentTypeString) else {
                    
                    throw SkinModelDecodingError.attachmentTypeUnknown
                }
                
                let name = attachment.stringValue
                
                switch attachmentType {
                case .region:
                    attachments.append(AttachmentModelType.region(try RegionAttachmentModel(name, try attachmentsContainer.nestedContainer(keyedBy: RegionAttachmentModel.Keys.self, forKey: attachmentKey))))
                    
                case .boundingBox:
                    attachments.append(AttachmentModelType.boundingBox(try BoundingBoxAttachmentModel(name, try attachmentsContainer.nestedContainer(keyedBy: BoundingBoxAttachmentModel.Keys.self, forKey: attachmentKey))))
                    
                case .mesh:
                    attachments.append(AttachmentModelType.mesh(try MeshAttachmentModel(name, try attachmentsContainer.nestedContainer(keyedBy: MeshAttachmentModel.Keys.self, forKey: attachmentKey))))
                    
                case .linkedMesh:
                    attachments.append(AttachmentModelType.linkedMesh(try LinkedMeshAttachmentModel(name, try attachmentsContainer.nestedContainer(keyedBy: LinkedMeshAttachmentModel.Keys.self, forKey: attachmentKey))))

                case .path:
                    attachments.append(AttachmentModelType.path(try PathAttachmentModel(name, try attachmentsContainer.nestedContainer(keyedBy: PathAttachmentModel.Keys.self, forKey: attachmentKey))))
                    
                case .point:
                    attachments.append(AttachmentModelType.point(try PointAttachmentModel(name, try attachmentsContainer.nestedContainer(keyedBy: PointAttachmentModel.Keys.self, forKey: attachmentKey))))
                    
                case .clipping:
                    attachments.append(AttachmentModelType.clipping(try ClippingAttachmentModel(name, try attachmentsContainer.nestedContainer(keyedBy: ClippingAttachmentModel.Keys.self, forKey: attachmentKey))))
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
    let attachments: [AttachmentModelType]?
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

    var model: AttachmentModel {
        get {
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
    }
}

protocol AttachmentModel {

    var name: String { get }
}

//MARK: - Region

struct RegionAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String?
    let position: CGPoint
    let scale: CGVector
    let rotation: CGFloat
    let size: CGSize
    let color: ColorModel

    init(_ name: String, _ path: String?, _ x: CGFloat?, _ y: CGFloat?, _ scaleX: CGFloat?, _ scaleY: CGFloat?, _ rotation: CGFloat?, _ width: CGFloat, _ height: CGFloat, _ color: String?) {
        
        self.name = name
        self.path = path
        self.position = CGPoint(x: x ?? 0, y: y ?? 0)
        self.scale = CGVector(dx: scaleX ?? 1.0, dy: scaleY ?? 1.0)
        self.rotation = rotation ?? 0
        self.size = CGSize(width: width, height: height)
        self.color = ColorModel(color ?? "FFFFFFFF")
    }
}

extension RegionAttachmentModel: SpineDecodableDictionary {

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
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let path: String? = try container.decodeIfPresent(String.self, forKey: .path)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        let scaleX: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleX)
        let scaleY: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleY)
        let rotation: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotation)
        let width: CGFloat = try container.decode(CGFloat.self, forKey: .width)
        let height: CGFloat = try container.decode(CGFloat.self, forKey: .height)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, path, x, y, scaleX, scaleY, rotation, width, height, color)
    }
}

//MARK: - Bounding Box

struct BoundingBoxAttachmentModel: AttachmentModel {
    
    let name: String
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel

    init(_ name: String, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String?) {
        
        self.name = name
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color ?? "60F000FF")
    }
}

extension BoundingBoxAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case vertexCount
        case vertices
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let vertexCount: UInt = try container.decode(UInt.self, forKey: .vertexCount)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, vertexCount, vertices, color)
    }
}

//MARK: - Mesh

struct MeshAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String?
    let uvs: [CGFloat]
    let triangles: [UInt]
    let vertices: [CGFloat]
    let hull: UInt
    let edges: [UInt]?
    let color: ColorModel
    let size: CGSize?

    init(_ name: String, _ path: String?, _ uvs: [CGFloat], _ triangles: [UInt], _ vertices: [CGFloat], _ hull: UInt, _ edges: [UInt]?, _ color: String?, _ width: CGFloat?, _ height: CGFloat?) {
        
        self.name = name
        self.path = path
        self.uvs = uvs
        self.triangles = triangles
        self.vertices = vertices
        self.hull = hull
        self.edges = edges
        self.color = ColorModel(color ?? "FFFFFFFF")
        if let width = width, let height = height  {
            
            self.size = CGSize(width: width, height: height)
            
        } else {
            
            self.size = nil
        }
    }
}

extension MeshAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case path
        case uvs
        case triangles
        case vertices
        case hull
        case edges
        case color
        case width
        case height
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let path: String? = try container.decodeIfPresent(String.self, forKey: .path)
        let uvs: [CGFloat] = try container.decode([CGFloat].self, forKey: .uvs)
        let triangles: [UInt] = try container.decode([UInt].self, forKey: .triangles)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let hull: UInt = try container.decode(UInt.self, forKey: .hull)
        let edges: [UInt]? = try container.decodeIfPresent([UInt].self, forKey: .edges)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        let width: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .width)
        let height: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .height)
        
        self.init(name, path, uvs, triangles, vertices, hull, edges, color, width, height)
    }
}

//MARK: - Linked Mesh

struct LinkedMeshAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String?
    let skin: String?
    let parent: String?
    let deform: Bool
    let color: ColorModel
    let size: CGSize?

    init(_ name: String, _ path: String?, _ skin: String?, _ parent: String?, _ deform: Bool?, _ color: String?, _ width: CGFloat?, _ height: CGFloat?) {
        
        self.name = name
        self.path = path
        self.skin = skin
        self.parent = parent
        self.deform = deform ?? true
        self.color = ColorModel(color ?? "FFFFFFFF")
        if let width = width, let height = height  {
            
            self.size = CGSize(width: width, height: height)
            
        } else {
            
            self.size = nil
        }
    }
}

extension LinkedMeshAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case path
        case skin
        case parent
        case deform
        case color
        case width
        case height
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let path: String? = try container.decodeIfPresent(String.self, forKey: .path)
        let skin: String? = try container.decodeIfPresent(String.self, forKey: .skin)
        let parent: String? = try container.decodeIfPresent(String.self, forKey: .parent)
        let deform: Bool? = try container.decodeIfPresent(Bool.self, forKey: .deform)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        let width: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .width)
        let height: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .height)
        
        self.init(name, path, skin, parent, deform, color, width,height)
    }
}

//MARK: - Path

struct PathAttachmentModel: AttachmentModel {
    
    let name: String
    let closed: Bool
    let constantSpeed: Bool
    let lengths: [CGFloat]
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
    
    init(_ name: String, _ closed: Bool?, _ constantSpeed: Bool?, _ lengths: [CGFloat], _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String?) {
        
        self.name = name
        self.closed = closed ?? false
        self.constantSpeed = constantSpeed ?? true
        self.lengths = lengths
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color ?? "FF7F00FF")
    }
}

extension PathAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case closed
        case constantSpeed
        case lengths
        case vertexCount
        case vertices
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let closed: Bool? = try container.decodeIfPresent(Bool.self, forKey: .closed)
        let constantSpeed: Bool? = try container.decodeIfPresent(Bool.self, forKey: .constantSpeed)
        let lengths: [CGFloat] = try container.decode([CGFloat].self, forKey: .lengths)
        let vertexCount: UInt = try container.decode(UInt.self, forKey: .vertexCount)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, closed, constantSpeed, lengths, vertexCount, vertices, color)
    }
}

//MARK: - Point

struct PointAttachmentModel: AttachmentModel {

    let name: String
    let point: CGPoint
    let rotation: CGFloat
    let color: ColorModel

    init(_ name: String, _ x: CGFloat?, _ y: CGFloat?, _ rotation: CGFloat?, _ color: String?) {
        
        self.name = name
        self.point = CGPoint(x: x ?? 0, y: y ?? 0)
        self.rotation = rotation ?? 0
        self.color = ColorModel(color ?? "F1F100FF")
    }
}

extension PointAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case x
        case y
        case rotation
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        let rotation: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotation)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, x, y, rotation, color)
    }
}

//MARK: - Clipping

struct ClippingAttachmentModel: AttachmentModel {
    
    let name: String
    let end: String
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
    
    init(_ name: String, _ end: String, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String?) {
        
        self.name = name
        self.end = end
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color ?? "CE3A3AFF")
    }
}

extension ClippingAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case end
        case vertexCount
        case vertices
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let end: String = try container.decode(String.self, forKey: .end)
        let vertexCount: UInt = try container.decode(UInt.self, forKey: .vertexCount)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, end, vertexCount, vertices, color)
    }
}
