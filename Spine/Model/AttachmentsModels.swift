//
//  AttachmentsModels.swift
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

struct SkinSlotModel {
    
    let name: String
    let attachments: [AttachmentModelType]
}

protocol AttachmentModel {

    var name: String { get }
}

struct RegionAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String
    let position: CGPoint
    let scale: CGVector
    let rotation: CGFloat
    let size: CGSize
    let color: ColorModel
    
    init(_ name: String, _ path: String, _ x: CGFloat = 0, _ y: CGFloat = 0, _ scaleX: CGFloat = 1.0, _ scaleY: CGFloat = 1.0, _ rotation: CGFloat = 0, _ width: CGFloat = 0, _ height: CGFloat = 0, _ color: String = "FFFFFFFF") {
        
        self.name = name
        self.path = path
        self.position = CGPoint(x: x, y: y)
        self.scale = CGVector(dx: scaleX, dy: scaleY)
        self.rotation = rotation
        self.size = CGSize(width: width, height: height)
        self.color = ColorModel(color)
    }
}

struct MeshAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String
    let uvs: [CGPoint]
    let triangles: [Int]
    let vertices: [VerticeModel]
    let hull: UInt
    let edges: UInt?
    let color: ColorModel
    let size: CGSize?
    
    init(_ name: String, _ path: String, _ uvs: [[String : CGFloat]], _ triangles: [Int], _ vertices: [[String : CGFloat]], _ hull: UInt, _ edges: UInt?, _ color: String = "FFFFFFFF", _ width: CGFloat?, _ height: CGFloat?) {
        
        self.name = name
        self.path = path
        self.uvs = uvs.map{ CGPoint($0) }
        self.triangles = triangles
        self.vertices = vertices.map{ VerticeModel($0) }
        self.hull = hull
        self.edges = edges
        self.color = ColorModel(color)
        self.size = CGSize(width, height)
    }
    
    //weighted vertices init
    init(_ name: String, _ path: String, _ uvs: [[String : CGFloat]], _ triangles: [Int], _ vertices: [CGFloat], _ hull: UInt, _ edges: UInt?, _ color: String = "FFFFFFFF", _ width: CGFloat?, _ height: CGFloat?) {
        
        self.name = name
        self.path = path
        self.uvs = uvs.map{ CGPoint($0) }
        self.triangles = triangles
        self.vertices = vertices.map{ VerticeModel($0) }
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
    let vertices: [VerticeModel]
    let color: ColorModel
    
    init(_ name: String, _ vertexCount: UInt, _ vertices: [[String : CGFloat]], _ color: String = "60F000FF") {
        
        self.name = name
        self.vertexCount = vertexCount
        self.vertices = vertices.map{ VerticeModel($0) }
        self.color = ColorModel(color)
    }
    
    //weighted vertices init
    init(_ name: String, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String = "60F000FF") {
        
        self.name = name
        self.vertexCount = vertexCount
        self.vertices = vertices.map{ VerticeModel($0) }
        self.color = ColorModel(color)
    }
}

struct PathAttachmentModel: AttachmentModel {
    
    let name: String
    let closed: Bool
    let constantSpeed: Bool
    let lengths: [CGFloat] //TODO: should refine values type
    let vertexCount: UInt
    let vertices: [VerticeModel]
    let color: ColorModel
    
    init(_ name: String, _ closed: Bool = false, _ constantSpeed: Bool = true, _ lengths: [CGFloat], _ vertexCount: UInt, _ vertices: [[String : CGFloat]], _ color: String = "FF7F00FF") {
        
        self.name = name
        self.closed = closed
        self.constantSpeed = constantSpeed
        self.lengths = lengths
        self.vertexCount = vertexCount
        self.vertices = vertices.map{ VerticeModel($0) }
        self.color = ColorModel(color)
    }
    
    //weighted vertices init
    init(_ name: String, _ closed: Bool = false, _ constantSpeed: Bool = true, _ lengths: [CGFloat], _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String = "FF7F00FF") {
        
        self.name = name
        self.closed = closed
        self.constantSpeed = constantSpeed
        self.lengths = lengths
        self.vertexCount = vertexCount
        self.vertices = vertices.map{ VerticeModel($0) }
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
    let vertices: [VerticeModel]
    let color: ColorModel
    
    init(_ name: String, _ end: Int, _ vertexCount: UInt, _ vertices: [[String : CGFloat]], _ color: String = "CE3A3AFF") {
        
        self.name = name
        self.end = end
        self.vertexCount = vertexCount
        self.vertices = vertices.map{ VerticeModel($0) }
        self.color = ColorModel(color)
    }
    
    //weighted verteces init
    init(_ name: String, _ end: Int, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String = "CE3A3AFF") {
        
        self.name = name
        self.end = end
        self.vertexCount = vertexCount
        self.vertices = vertices.map{ VerticeModel($0) }
        self.color = ColorModel(color)
    }
}
