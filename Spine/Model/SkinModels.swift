//
//  SkinModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

//MARK: - Skin Model

struct SkinModel {
    
    let name: String
    let slots: [SkinSlotModel]?
}

extension SkinModel: SpineDecodableDictionary {
    
    typealias KeysType = SpineNameKey
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var slots = [SkinSlotModel]()
        
        for slotKey in container.allKeys {
            
            let slotContainer = try container.nestedContainer(keyedBy: SkinSlotModel.KeysType.self, forKey: slotKey)
            let slot = try SkinSlotModel(slotKey.stringValue, slotContainer)
            slots.append(slot)
        }
        
        self.name = name
        self.slots = slots
    }
}

//MARK: - Skin Slot Model

struct SkinSlotModel {
    
    let name: String
    let attachments: [AttachmentModelType]?
}

extension SkinSlotModel: SpineDecodableDictionary {
    
    enum SkinSlotModelDecodingError: Error {
        
        case attachmentTypeUnknown
    }
    
    typealias KeysType = SpineNameKey
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var attachments = [AttachmentModelType]()
        
        for attachmentKey in container.allKeys {
            
            let attachmentContainer = try container.nestedContainer(keyedBy: AttachmentModelKeys.self, forKey: attachmentKey)
            let attachmentTypeString: String? = try attachmentContainer.decodeIfPresent(String.self, forKey: AttachmentModelKeys.type)
            
            guard let attachmentType = AttachmentModelTypeKeys(attachmentTypeString) else {
                
                throw SkinSlotModelDecodingError.attachmentTypeUnknown
            }
            
            let name = attachmentKey.stringValue
            
            switch attachmentType {
            case .region:
                attachments.append(AttachmentModelType.region(try RegionAttachmentModel(name, try container.nestedContainer(keyedBy: RegionAttachmentModel.Keys.self, forKey: attachmentKey))))
                
            case .boundingBox:
                attachments.append(AttachmentModelType.boundingBox(try BoundingBoxAttachmentModel(name, try container.nestedContainer(keyedBy: BoundingBoxAttachmentModel.Keys.self, forKey: attachmentKey))))
                
            case .mesh:
                attachments.append(AttachmentModelType.mesh(try MeshAttachmentModel(name, try container.nestedContainer(keyedBy: MeshAttachmentModel.Keys.self, forKey: attachmentKey))))
                
            case .linkedMesh:
                attachments.append(AttachmentModelType.linkedMesh(try LinkedMeshAttachmentModel(name, try container.nestedContainer(keyedBy: LinkedMeshAttachmentModel.Keys.self, forKey: attachmentKey))))
                
            case .path:
                attachments.append(AttachmentModelType.path(try PathAttachmentModel(name, try container.nestedContainer(keyedBy: PathAttachmentModel.Keys.self, forKey: attachmentKey))))
                
            case .point:
                attachments.append(AttachmentModelType.point(try PointAttachmentModel(name, try container.nestedContainer(keyedBy: PointAttachmentModel.Keys.self, forKey: attachmentKey))))
                
            case .clipping:
                attachments.append(AttachmentModelType.clipping(try ClippingAttachmentModel(name, try container.nestedContainer(keyedBy: ClippingAttachmentModel.Keys.self, forKey: attachmentKey))))
            }
        }
        
        self.name = name
        self.attachments = attachments
    }
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
    
    var modelName: String {
        get {
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
}

protocol AttachmentModel {

    var name: String { get }
    var actualName: String? { get }
}

enum AttachmentModelKeys: String, CodingKey {
    
    case type
}

enum AttachmentModelTypeKeys: String {
    
    case region
    case boundingBox = "boundingbox"
    case mesh
    case linkedMesh = "linkedmesh"
    case path
    case point
    case clipping
    
    init?(_ value: String?) {
        
        let typeValue = value ?? "region"
        
        guard let type = AttachmentModelTypeKeys(rawValue: typeValue) else {
            
            return nil
        }
        
        self = type
    }
}

//MARK: - Region

struct RegionAttachmentModel: AttachmentModel {
    
    let name: String
    let actualName: String?
    let path: String?
    let position: CGPoint
    let scale: CGVector
    let rotation: CGFloat
    let size: CGSize
    let color: ColorModel

    init(_ name: String, _ actualName: String?, _ path: String?, _ x: CGFloat?, _ y: CGFloat?, _ scaleX: CGFloat?, _ scaleY: CGFloat?, _ rotation: CGFloat?, _ width: CGFloat, _ height: CGFloat, _ color: String?) {
        
        self.name = name
        self.actualName = actualName
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
        
        case name
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
        
        let actualName: String? = try container.decodeIfPresent(String.self, forKey: .name)
        let path: String? = try container.decodeIfPresent(String.self, forKey: .path)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        let scaleX: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleX)
        let scaleY: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleY)
        let rotation: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotation)
        let width: CGFloat = try container.decode(CGFloat.self, forKey: .width)
        let height: CGFloat = try container.decode(CGFloat.self, forKey: .height)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, actualName, path, x, y, scaleX, scaleY, rotation, width, height, color)
    }
}

//MARK: - Bounding Box

struct BoundingBoxAttachmentModel: AttachmentModel {
    
    let name: String
    let actualName: String?
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel

    init(_ name: String, _ actualName: String?, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String?) {
        
        self.name = name
        self.actualName = actualName
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color ?? "60F000FF")
    }
}

extension BoundingBoxAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name
        case vertexCount
        case vertices
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let actualName: String? = try container.decodeIfPresent(String.self, forKey: .name)
        let vertexCount: UInt = try container.decode(UInt.self, forKey: .vertexCount)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, actualName, vertexCount, vertices, color)
    }
}

//MARK: - Mesh

struct MeshAttachmentModel: AttachmentModel {
    
    let name: String
    let actualName: String?
    let path: String?
    let uvs: [CGFloat]
    let triangles: [UInt]
    let vertices: [CGFloat]
    let hull: UInt
    let edges: [UInt]?
    let color: ColorModel
    let size: CGSize?

    init(_ name: String, _ actualName: String?, _ path: String?, _ uvs: [CGFloat], _ triangles: [UInt], _ vertices: [CGFloat], _ hull: UInt, _ edges: [UInt]?, _ color: String?, _ width: CGFloat?, _ height: CGFloat?) {
        
        self.name = name
        self.actualName = actualName
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
        
        case name
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
        
        let actualName: String? = try container.decodeIfPresent(String.self, forKey: .name)
        let path: String? = try container.decodeIfPresent(String.self, forKey: .path)
        let uvs: [CGFloat] = try container.decode([CGFloat].self, forKey: .uvs)
        let triangles: [UInt] = try container.decode([UInt].self, forKey: .triangles)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let hull: UInt = try container.decode(UInt.self, forKey: .hull)
        let edges: [UInt]? = try container.decodeIfPresent([UInt].self, forKey: .edges)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        let width: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .width)
        let height: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .height)
        
        self.init(name, actualName, path, uvs, triangles, vertices, hull, edges, color, width, height)
    }
}

//MARK: - Linked Mesh

struct LinkedMeshAttachmentModel: AttachmentModel {
    
    let name: String
    let actualName: String?
    let path: String?
    let skin: String?
    let parent: String?
    let deform: Bool
    let color: ColorModel
    let size: CGSize?

    init(_ name: String, _ actualName: String?, _ path: String?, _ skin: String?, _ parent: String?, _ deform: Bool?, _ color: String?, _ width: CGFloat?, _ height: CGFloat?) {
        
        self.name = name
        self.actualName = actualName
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
        
        case name
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
        
        let actualName: String? = try container.decodeIfPresent(String.self, forKey: .name)
        let path: String? = try container.decodeIfPresent(String.self, forKey: .path)
        let skin: String? = try container.decodeIfPresent(String.self, forKey: .skin)
        let parent: String? = try container.decodeIfPresent(String.self, forKey: .parent)
        let deform: Bool? = try container.decodeIfPresent(Bool.self, forKey: .deform)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        let width: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .width)
        let height: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .height)
        
        self.init(name, actualName, path, skin, parent, deform, color, width,height)
    }
}

//MARK: - Path

struct PathAttachmentModel: AttachmentModel {
    
    let name: String
    let actualName: String?
    let closed: Bool
    let constantSpeed: Bool
    let lengths: [CGFloat]
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
    
    init(_ name: String, _ actualName: String?, _ closed: Bool?, _ constantSpeed: Bool?, _ lengths: [CGFloat], _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String?) {
        
        self.name = name
        self.actualName = actualName
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
        
        case name
        case closed
        case constantSpeed
        case lengths
        case vertexCount
        case vertices
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let actualName: String? = try container.decodeIfPresent(String.self, forKey: .name)
        let closed: Bool? = try container.decodeIfPresent(Bool.self, forKey: .closed)
        let constantSpeed: Bool? = try container.decodeIfPresent(Bool.self, forKey: .constantSpeed)
        let lengths: [CGFloat] = try container.decode([CGFloat].self, forKey: .lengths)
        let vertexCount: UInt = try container.decode(UInt.self, forKey: .vertexCount)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, actualName, closed, constantSpeed, lengths, vertexCount, vertices, color)
    }
}

//MARK: - Point

struct PointAttachmentModel: AttachmentModel {

    let name: String
    let actualName: String?
    let point: CGPoint
    let rotation: CGFloat
    let color: ColorModel

    init(_ name: String, _ actualName: String?, _ x: CGFloat?, _ y: CGFloat?, _ rotation: CGFloat?, _ color: String?) {
        
        self.name = name
        self.actualName = actualName
        self.point = CGPoint(x: x ?? 0, y: y ?? 0)
        self.rotation = rotation ?? 0
        self.color = ColorModel(color ?? "F1F100FF")
    }
}

extension PointAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name
        case x
        case y
        case rotation
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let actualName: String? = try container.decodeIfPresent(String.self, forKey: .name)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        let rotation: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotation)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, actualName, x, y, rotation, color)
    }
}

//MARK: - Clipping

struct ClippingAttachmentModel: AttachmentModel {
    
    let name: String
    let actualName: String?
    let end: String
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
    
    init(_ name: String, _ actualName: String?, _ end: String, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String?) {
        
        self.name = name
        self.actualName = actualName
        self.end = end
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color ?? "CE3A3AFF")
    }
}

extension ClippingAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name
        case end
        case vertexCount
        case vertices
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let actualName: String? = try container.decodeIfPresent(String.self, forKey: .name)
        let end: String = try container.decode(String.self, forKey: .end)
        let vertexCount: UInt = try container.decode(UInt.self, forKey: .vertexCount)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, actualName, end, vertexCount, vertices, color)
    }
}
