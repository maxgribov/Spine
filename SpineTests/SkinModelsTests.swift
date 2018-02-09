//
//  SkinModelsTests.swift
//  SpineTests
//
//  Created by Max Gribov on 30/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class SkinModelsTests: XCTestCase {
    
    func testSkinModel() {

        //given
        let json = """
            {
                "skeleton": {
                    "hash": "FrNJhva2RVZ1bbIjdNspNttett4",
                    "spine": "3.6.32",
                    "width": 419.84,
                    "height": 686.08,
                    "images": "./images/"
                },
                "skins": {
                    "skin-name": {
                        "region-slot": {
                            "region-attachment": {
                                "name": "region-attachment-name",
                                "path": "dust",
                                "x": -31.79,
                                "y": 25.97,
                                "scaleX": 0.463,
                                "scaleY": 0.813,
                                "rotation": -83.07,
                                "width": 96,
                                "height": 73,
                                "color": "ce3a3aff"
                            },
                            "region-attachment-omitted": {
                                "width": 96,
                                "height": 73
                            }
                        },
                        "boundingBox-slot": {
                            "boundingBox-attachment": {
                                "name": "boundingBox-attachment-name",
                                "type": "boundingbox",
                                "vertexCount": 6,
                                "vertices": [-19.14, -70.3, 40.8, -118.08, 257.78, -115.62, 285.17, 57.18, 120.77, 164.95, -5.07, 76.95],
                                "color": "ffffff3e"
                            },
                            "boundingBox-attachment-omitted": {
                                "type": "boundingbox",
                                "vertexCount": 6,
                                "vertices": [-19.14, -70.3, 40.8, -118.08, 257.78, -115.62, 285.17, 57.18, 120.77, 164.95, -5.07, 76.95]
                            }
                        },
                        "mesh-slot": {
                            "mesh-attachment": {
                                "name": "mesh-attachment-name",
                                "type": "mesh",
                                "path": "dust",
                                "uvs": [0.59417, 0.23422, 0.62257, 0.30336, 0.6501, 0.37036, 0.67637, 0.38404, 0.72068, 0.4071, 0.76264, 0.42894, 1, 0.70375],
                                "triangles": [8, 9, 3, 4, 8, 3, 5, 8, 4, 6, 8, 5, 8, 6, 7, 11, 12, 13, 11, 1, 10, 0, 13, 14, 0, 11, 13, 0, 1, 11, 9, 2, 3, 1, 2, 10, 9, 10, 2],
                                "vertices": [2, 38, 18.17, 41.57, 0.72255, 39, 12.46, 46.05, 0.27745, 2, 38, 24.08, 40.76, 0.57407, 39, 16.12, 41.34, 0.42593, 2, 38, 29.81],
                                "hull": 15,
                                "edges": [14, 16, 16, 18, 18, 20, 4, 18, 20, 22, 22, 24, 24, 26, 26, 28, 22, 26, 12, 14, 10, 12, 2, 4, 2, 20, 4, 6, 6, 16, 2, 0, 0, 28, 6, 8, 8, 10],
                                "color": "ffffff00",
                                "width": 126,
                                "height": 69
                            },
                            "mesh-attachment-omitted": {
                                "type": "mesh",
                                "uvs": [0.59417, 0.23422, 0.62257, 0.30336, 0.6501, 0.37036, 0.67637, 0.38404, 0.72068, 0.4071, 0.76264, 0.42894, 1, 0.70375],
                                "triangles": [8, 9, 3, 4, 8, 3, 5, 8, 4, 6, 8, 5, 8, 6, 7, 11, 12, 13, 11, 1, 10, 0, 13, 14, 0, 11, 13, 0, 1, 11, 9, 2, 3, 1, 2, 10, 9, 10, 2],
                                "vertices": [2, 38, 18.17, 41.57, 0.72255, 39, 12.46, 46.05, 0.27745, 2, 38, 24.08, 40.76, 0.57407, 39, 16.12, 41.34, 0.42593, 2, 38, 29.81],
                                "hull": 15
                            }
                        },
                        "linkedMesh-slot": {
                            "linkedMesh-attachment": {
                                "name": "linkedMesh-attachment-name",
                                "type": "linkedmesh",
                                "path": "dust",
                                "skin": "front-foot",
                                "parent": "dust",
                                "deform": false,
                                "color": "fffffffe",
                                "width": 96,
                                "height": 73
                            },
                            "linkedMesh-attachment-omitted": {
                                "type": "linkedmesh"
                            }
                        },
                        "path-slot": {
                            "path-attachment": {
                                "name": "path-attachment-name",
                                "type": "path",
                                "closed": true,
                                "constantSpeed": true,
                                "lengths": [185.21, 354.53, 478.3, 608.52, 786, 1058.49, 1138.97, 1223.96, 1303.87, 1388.23, 1471.11, 1551.64, 1633.55, 1713.27, 1799.89],
                                "vertexCount": 66,
                                "vertices": [1, 111, 11.23, 41.87, 1, 1, 111, 0.79, 41.95, 1, 1, 111, -34.72, 42.24, 1, 1, 91, -104.22, 0.41, 1, 1, 91, 0.07, 0.55, 1, 1, 91, 68.8],
                                "color": "ff8819ff"
                            },
                            "path-attachment-omitted": {
                                "type": "path",
                                "lengths": [185.21, 354.53, 478.3, 608.52, 786, 1058.49, 1138.97, 1223.96, 1303.87, 1388.23, 1471.11, 1551.64, 1633.55, 1713.27, 1799.89],
                                "vertexCount": 66,
                                "vertices": [1, 111, 11.23, 41.87, 1, 1, 111, 0.79, 41.95, 1, 1, 111, -34.72, 42.24, 1, 1, 91, -104.22, 0.41, 1, 1, 91, 0.07, 0.55, 1, 1, 91, 68.8]
                            }
                        },
                        "point-slot": {
                            "point-attachment": {
                                "name": "point-attachment-name",
                                "type": "point",
                                "x": -20.11,
                                "y": 21.6,
                                "rotation": 360.5,
                                "color": "fffffffe"
                            },
                            "point-attachment-omitted": {
                                "type": "point"
                            }
                        },
                        "clipping-slot": {
                            "clipping-attachment": {
                                "name": "clipping-attachment-name",
                                "type": "clipping",
                                "end": "dust",
                                "vertexCount": 9,
                                "vertices": [66.76, 509.48, 19.98, 434.54, 5.34, 336.28, 22.19, 247.93, 77.98, 159.54, 182.21, -97.56, 1452.26, -99.8, 1454.33, 843.61, 166.57, 841.02],
                                "color": "ce3a3aff"
                            },
                            "clipping-attachment-omitted": {
                                "type": "clipping",
                                "end": "dust",
                                "vertexCount": 9,
                                "vertices": [66.76, 509.48, 19.98, 434.54, 5.34, 336.28, 22.19, 247.93, 77.98, 159.54, 182.21, -97.56, 1452.26, -99.8, 1454.33, 843.61, 166.57, 841.02]
                            }
                        }
                    }
                }
            }
        """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let skins = spineModel?.skins {
            
            if let skin = skins.first(where: { $0.name == "skin-name" }) {
                
                XCTAssertEqual(skin.name, "skin-name")
                
                if let slots = skin.slots {
                    
                    XCTAssertEqual(slots.count, 7)
                    
                    for slot in slots {
                        
                        XCTAssertTrue(["region-slot", "boundingBox-slot", "mesh-slot", "linkedMesh-slot", "path-slot", "point-slot", "clipping-slot"].contains(slot.name))
                        
                        if let attachments = slot.attachments {
                            
                            XCTAssertEqual(attachments.count, 2)
                            
                            if slot.name == "region-slot" {
                                
                                for attachment in attachments {
                                    
                                    XCTAssertTrue(["region-attachment-name", "region-attachment-omitted"].contains(attachment.model.name))
                                    XCTAssertTrue(attachment.model is RegionAttachmentModel)
                                }
                                
                            } else if slot.name == "boundingBox-slot" {
                                
                                for attachment in attachments {
                                    
                                    XCTAssertTrue(["boundingBox-attachment-name", "boundingBox-attachment-omitted"].contains(attachment.model.name))
                                    XCTAssertTrue(attachment.model is BoundingBoxAttachmentModel)
                                }
                                
                            }   else if slot.name == "mesh-slot" {
                                
                                for attachment in attachments {
                                    
                                    XCTAssertTrue(["mesh-attachment-name", "mesh-attachment-omitted"].contains(attachment.model.name))
                                    XCTAssertTrue(attachment.model is MeshAttachmentModel)
                                }
                                
                            } else if slot.name == "linkedMesh-slot" {
                                
                                for attachment in attachments {
                                    
                                    XCTAssertTrue(["linkedMesh-attachment-name", "linkedMesh-attachment-omitted"].contains(attachment.model.name))
                                    XCTAssertTrue(attachment.model is LinkedMeshAttachmentModel)
                                }
                                
                            } else if slot.name == "path-slot" {
                                
                                for attachment in attachments {
                                    
                                    XCTAssertTrue(["path-attachment-name", "path-attachment-omitted"].contains(attachment.model.name))
                                    XCTAssertTrue(attachment.model is PathAttachmentModel)
                                }
                                
                            } else if slot.name == "point-slot" {
                                
                                for attachment in attachments {
                                    
                                    XCTAssertTrue(["point-attachment-name", "point-attachment-omitted"].contains(attachment.model.name))
                                    XCTAssertTrue(attachment.model is PointAttachmentModel)
                                }
                                
                            } else if slot.name == "clipping-slot" {
                                
                                for attachment in attachments {
                                    
                                    XCTAssertTrue(["clipping-attachment-name", "clipping-attachment-omitted"].contains(attachment.model.name))
                                    XCTAssertTrue(attachment.model is ClippingAttachmentModel)
                                }
                                
                            } else {
                                
                                XCTFail("unexpected slot name")
                            }
                            
                        } else {
                            
                            XCTFail("attachments should not be nil")
                        }
                    }
                    
                } else {
                    
                    XCTFail("slots should not be nil")
                }
                
            } else {
                
                XCTFail("skin should not be nil")
            }
            
        } else {
            
            XCTFail("skins should not be nil")
        }
        
    }
    
    func testRegionAttachmentModel() {

        //given
        let json = """
            {
                "skeleton": {
                    "hash": "FrNJhva2RVZ1bbIjdNspNttett4",
                    "spine": "3.6.32",
                    "width": 419.84,
                    "height": 686.08,
                    "images": "./images/"
                },
                "skins": {
                    "skin-name": {
                        "region-slot": {
                            "region-attachment": {
                                "name": "region-attachment-name",
                                "path": "dust",
                                "x": -31.79,
                                "y": 25.97,
                                "scaleX": 0.463,
                                "scaleY": 0.813,
                                "rotation": -83.07,
                                "width": 96,
                                "height": 73,
                                "color": "ce3a3aff"
                            },
                            "region-attachment-omitted": {
                                "width": 96,
                                "height": 73
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let skins = spineModel?.skins {
            
            if let skin = skins.first(where: { $0.name == "skin-name" }) {
                
                if let slot = skin.slots?.first(where: { $0.name == "region-slot" }) {
                    
                    if let attachment = slot.attachments?.first(where: { $0.model.name == "region-attachment-name" }) {
                        
                        if let attachmentModel = attachment.model as? RegionAttachmentModel {
                            
                            XCTAssertEqual(attachmentModel.path, "dust")
                            XCTAssertEqual(attachmentModel.position.x, -31.79, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.position.y, 25.97, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.scale.dx, 0.463, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.scale.dy, 0.813, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.rotation, -83.07, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.size.width, 96, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.size.height, 73, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.color.value, "ce3a3aff")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachment should not be nil")
                    }
                    
                    if let attachmentOmitted = slot.attachments?.first(where: { $0.model.name == "region-attachment-omitted" }) {
                        
                        if let attachmentOmittedModel = attachmentOmitted.model as? RegionAttachmentModel {
                            
                            XCTAssertNil(attachmentOmittedModel.path)
                            XCTAssertEqual(attachmentOmittedModel.position.x, 0, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.position.y, 0, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.scale.dx, 1.0, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.scale.dy, 1.0, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.rotation, 0, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.size.width, 96, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.size.height, 73, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.color.value, "FFFFFFFF")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachmentOmitted should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("slot should not be nil")
                }
                
            } else {
                
                XCTFail("skin should not be nil")
            }
            
        } else {
            
            XCTFail("skins should not be nil")
        }
    }
    
    func testBoundingBoxAttachmentModel() {
        
        //given
        let json = """
            {
                "skeleton": {
                    "hash": "FrNJhva2RVZ1bbIjdNspNttett4",
                    "spine": "3.6.32",
                    "width": 419.84,
                    "height": 686.08,
                    "images": "./images/"
                },
                "skins": {
                    "skin-name": {
                        "boundingBox-slot": {
                            "boundingBox-attachment": {
                                "name": "boundingBox-attachment-name",
                                "type": "boundingbox",
                                "vertexCount": 6,
                                "vertices": [-19.14, -70.3, 40.8 ],
                                "color": "ffffff3e"
                            },
                            "boundingBox-attachment-omitted": {
                                "type": "boundingbox",
                                "vertexCount": 6,
                                "vertices": [-19.14, -70.3, 40.8 ]
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let skins = spineModel?.skins {
            
            if let skin = skins.first(where: { $0.name == "skin-name" }) {
                
                if let slot = skin.slots?.first(where: { $0.name == "boundingBox-slot" }) {
                    
                    if let attachment = slot.attachments?.first(where: { $0.model.name == "boundingBox-attachment-name" }) {
                        
                        if let attachmentModel = attachment.model as? BoundingBoxAttachmentModel {
                            
                            XCTAssertEqual(attachmentModel.vertexCount, 6)
                            XCTAssertTrue(attachmentModel.vertices.count == 3)
                            XCTAssertEqual(attachmentModel.vertices[0], -19.14, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertices[1], -70.3, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertices[2], 40.8, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.color.value, "ffffff3e")

                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachment should not be nil")
                    }
                    
                    if let attachmentOmitted = slot.attachments?.first(where: { $0.model.name == "boundingBox-attachment-omitted" }) {
                        
                        if let attachmentOmittedModel = attachmentOmitted.model as? BoundingBoxAttachmentModel {
                            
                            XCTAssertEqual(attachmentOmittedModel.vertexCount, 6)
                            XCTAssertTrue(attachmentOmittedModel.vertices.count == 3)
                            XCTAssertEqual(attachmentOmittedModel.vertices[0], -19.14, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertices[1], -70.3, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertices[2], 40.8, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.color.value, "60F000FF")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachmentOmitted should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("slot should not be nil")
                }
                
            } else {
                
                XCTFail("skin should not be nil")
            }
            
        } else {
            
            XCTFail("skins should not be nil")
        }
    }
    
    func testMeshAttachmentModel() {
        
        //given
        let json = """
            {
                "skeleton": {
                    "hash": "FrNJhva2RVZ1bbIjdNspNttett4",
                    "spine": "3.6.32",
                    "width": 419.84,
                    "height": 686.08,
                    "images": "./images/"
                },
                "skins": {
                    "skin-name": {
                        "mesh-slot": {
                            "mesh-attachment": {
                                "name": "mesh-attachment-name",
                                "type": "mesh",
                                "path": "dust",
                                "uvs": [0.59417, 0.23422, 0.62257],
                                "triangles": [8, 9, 3],
                                "vertices": [2, 38, 18.17],
                                "hull": 15,
                                "edges": [14, 16, 16],
                                "color": "ffffff00",
                                "width": 126,
                                "height": 69
                            },
                            "mesh-attachment-omitted": {
                                "type": "mesh",
                                "uvs": [0.59417, 0.23422, 0.62257],
                                "triangles": [8, 9, 3],
                                "vertices": [2, 38, 18.17],
                                "hull": 15
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let skins = spineModel?.skins {
            
            if let skin = skins.first(where: { $0.name == "skin-name" }) {
                
                if let slot = skin.slots?.first(where: { $0.name == "mesh-slot" }) {
                    
                    if let attachment = slot.attachments?.first(where: { $0.model.name == "mesh-attachment-name" }) {
                        
                        if let attachmentModel = attachment.model as? MeshAttachmentModel {
                            
                            XCTAssertEqual(attachmentModel.path, "dust")
                            XCTAssertTrue(attachmentModel.uvs.count == 3)
                            XCTAssertEqual(attachmentModel.uvs[0], 0.59417, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.uvs[1], 0.23422, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.uvs[2], 0.62257, accuracy: CGFloat.ulpOfOne)
                            XCTAssertTrue(attachmentModel.triangles.count == 3)
                            XCTAssertEqual(attachmentModel.triangles[0], 8)
                            XCTAssertEqual(attachmentModel.triangles[1], 9)
                            XCTAssertEqual(attachmentModel.triangles[2], 3)
                            XCTAssertTrue(attachmentModel.vertices.count == 3)
                            XCTAssertEqual(attachmentModel.vertices[0], 2, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertices[1], 38, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertices[2], 18.17, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.hull, 15)
                            if let edges = attachmentModel.edges {
                                
                                XCTAssertTrue(edges.count == 3)
                                XCTAssertEqual(edges[0], 14)
                                XCTAssertEqual(edges[1], 16)
                                XCTAssertEqual(edges[2], 16)
                                
                            } else {
                                
                                XCTFail("edges should not be nil")
                            }
                            
                            XCTAssertEqual(attachmentModel.color.value, "ffffff00")
                            
                            if let size = attachmentModel.size {
                                
                                XCTAssertEqual(size.width, 126)
                                XCTAssertEqual(size.height, 69)
                                
                            } else {
                                
                                XCTFail("size should not be nil")
                            }
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachment should not be nil")
                    }
                    
                    if let attachmentOmitted = slot.attachments?.first(where: { $0.model.name == "mesh-attachment-omitted" }) {
                        
                        if let attachmentOmittedModel = attachmentOmitted.model as? MeshAttachmentModel {
                            
                            XCTAssertNil(attachmentOmittedModel.path)
                            XCTAssertTrue(attachmentOmittedModel.uvs.count == 3)
                            XCTAssertEqual(attachmentOmittedModel.uvs[0], 0.59417, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.uvs[1], 0.23422, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.uvs[2], 0.62257, accuracy: CGFloat.ulpOfOne)
                            XCTAssertTrue(attachmentOmittedModel.triangles.count == 3)
                            XCTAssertEqual(attachmentOmittedModel.triangles[0], 8)
                            XCTAssertEqual(attachmentOmittedModel.triangles[1], 9)
                            XCTAssertEqual(attachmentOmittedModel.triangles[2], 3)
                            XCTAssertTrue(attachmentOmittedModel.vertices.count == 3)
                            XCTAssertEqual(attachmentOmittedModel.vertices[0], 2, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertices[1], 38, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertices[2], 18.17, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.hull, 15)
                            XCTAssertNil(attachmentOmittedModel.edges)
                            XCTAssertEqual(attachmentOmittedModel.color.value, "FFFFFFFF")
                            XCTAssertNil(attachmentOmittedModel.size)
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachmentOmitted should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("slot should not be nil")
                }
                
            } else {
                
                XCTFail("skin should not be nil")
            }
            
        } else {
            
            XCTFail("skins should not be nil")
        }
    }
    
    func testLinkedMeshAttachmentModel() {
        
        //given
        let json = """
            {
                "skeleton": {
                    "hash": "FrNJhva2RVZ1bbIjdNspNttett4",
                    "spine": "3.6.32",
                    "width": 419.84,
                    "height": 686.08,
                    "images": "./images/"
                },
                "skins": {
                    "skin-name": {
                        "linkedMesh-slot": {
                            "linkedMesh-attachment": {
                                "name": "linkedMesh-attachment-name",
                                "type": "linkedmesh",
                                "path": "dust",
                                "skin": "front-foot",
                                "parent": "dust",
                                "deform": false,
                                "color": "fffffffe",
                                "width": 96,
                                "height": 73
                            },
                            "linkedMesh-attachment-omitted": {
                                "type": "linkedmesh"
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let skins = spineModel?.skins {
            
            if let skin = skins.first(where: { $0.name == "skin-name" }) {
                
                if let slot = skin.slots?.first(where: { $0.name == "linkedMesh-slot" }) {
                    
                    if let attachment = slot.attachments?.first(where: { $0.model.name == "linkedMesh-attachment-name" }) {
                        
                        if let attachmentModel = attachment.model as? LinkedMeshAttachmentModel {
                            
                            XCTAssertEqual(attachmentModel.path, "dust")
                            XCTAssertEqual(attachmentModel.skin, "front-foot")
                            XCTAssertEqual(attachmentModel.parent, "dust")
                            XCTAssertEqual(attachmentModel.deform, false)
                            XCTAssertEqual(attachmentModel.color.value, "fffffffe")
                            if let size = attachmentModel.size {
                                
                                XCTAssertEqual(size.width, 96, accuracy: CGFloat.ulpOfOne)
                                XCTAssertEqual(size.height, 73, accuracy: CGFloat.ulpOfOne)
                                
                            } else {
                                
                                XCTFail("size should not be nil")
                            }
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachment should not be nil")
                    }
                    
                    if let attachmentOmitted = slot.attachments?.first(where: { $0.model.name == "linkedMesh-attachment-omitted" }) {
                        
                        if let attachmentOmittedModel = attachmentOmitted.model as? LinkedMeshAttachmentModel {
                            
                            XCTAssertNil(attachmentOmittedModel.path)
                            XCTAssertNil(attachmentOmittedModel.skin)
                            XCTAssertNil(attachmentOmittedModel.parent)
                            XCTAssertEqual(attachmentOmittedModel.deform, true)
                            XCTAssertEqual(attachmentOmittedModel.color.value, "FFFFFFFF")
                            XCTAssertNil(attachmentOmittedModel.size)
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachmentOmitted should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("slot should not be nil")
                }
                
            } else {
                
                XCTFail("skin should not be nil")
            }
            
        } else {
            
            XCTFail("skins should not be nil")
        }
    }
    
    func testPathAttachmentModel() {
        
        //given
        let json = """
            {
                "skeleton": {
                    "hash": "FrNJhva2RVZ1bbIjdNspNttett4",
                    "spine": "3.6.32",
                    "width": 419.84,
                    "height": 686.08,
                    "images": "./images/"
                },
                "skins": {
                    "skin-name": {
                        "path-slot": {
                            "path-attachment": {
                                "name": "path-attachment-name",
                                "type": "path",
                                "closed": true,
                                "constantSpeed": true,
                                "lengths": [185.21, 354.53, 478.3],
                                "vertexCount": 66,
                                "vertices": [1, 111, 11.23],
                                "color": "ff8819ff"
                            },
                            "path-attachment-omitted": {
                                "type": "path",
                                "lengths": [185.21, 354.53, 478.3],
                                "vertexCount": 66,
                                "vertices": [1, 111, 11.23]
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let skins = spineModel?.skins {
            
            if let skin = skins.first(where: { $0.name == "skin-name" }) {
                
                if let slot = skin.slots?.first(where: { $0.name == "path-slot" }) {
                    
                    if let attachment = slot.attachments?.first(where: { $0.model.name == "path-attachment-name" }) {
                        
                        if let attachmentModel = attachment.model as? PathAttachmentModel {
                            
                            XCTAssertEqual(attachmentModel.closed, true)
                            XCTAssertEqual(attachmentModel.constantSpeed, true)
                            XCTAssertTrue(attachmentModel.lengths.count == 3)
                            XCTAssertEqual(attachmentModel.lengths[0], 185.21, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.lengths[1], 354.53, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.lengths[2], 478.3, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertexCount, 66)
                            XCTAssertTrue(attachmentModel.vertices.count == 3)
                            XCTAssertEqual(attachmentModel.vertices[0], 1, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertices[1], 111, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertices[2], 11.23, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.color.value, "ff8819ff")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachment should not be nil")
                    }
                    
                    if let attachmentOmitted = slot.attachments?.first(where: { $0.model.name == "path-attachment-omitted" }) {
                        
                        if let attachmentOmittedModel = attachmentOmitted.model as? PathAttachmentModel {
                            
                            XCTAssertEqual(attachmentOmittedModel.closed, false)
                            XCTAssertEqual(attachmentOmittedModel.constantSpeed, true)
                            XCTAssertTrue(attachmentOmittedModel.lengths.count == 3)
                            XCTAssertEqual(attachmentOmittedModel.lengths[0], 185.21, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.lengths[1], 354.53, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.lengths[2], 478.3, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertexCount, 66)
                            XCTAssertTrue(attachmentOmittedModel.vertices.count == 3)
                            XCTAssertEqual(attachmentOmittedModel.vertices[0], 1, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertices[1], 111, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertices[2], 11.23, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.color.value, "FF7F00FF")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachmentOmitted should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("slot should not be nil")
                }
                
            } else {
                
                XCTFail("skin should not be nil")
            }
            
        } else {
            
            XCTFail("skins should not be nil")
        }
    }
    
    func testPointAttachmentModel() {
        
        //given
        let json = """
            {
                "skeleton": {
                    "hash": "FrNJhva2RVZ1bbIjdNspNttett4",
                    "spine": "3.6.32",
                    "width": 419.84,
                    "height": 686.08,
                    "images": "./images/"
                },
                "skins": {
                    "skin-name": {
                        "point-slot": {
                            "point-attachment": {
                                "name": "point-attachment-name",
                                "type": "point",
                                "x": -20.11,
                                "y": 21.6,
                                "rotation": 360.5,
                                "color": "fffffffe"
                            },
                            "point-attachment-omitted": {
                                "type": "point"
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let skins = spineModel?.skins {
            
            if let skin = skins.first(where: { $0.name == "skin-name" }) {
                
                if let slot = skin.slots?.first(where: { $0.name == "point-slot" }) {
                    
                    if let attachment = slot.attachments?.first(where: { $0.model.name == "point-attachment-name" }) {
                        
                        if let attachmentModel = attachment.model as? PointAttachmentModel {
                            
                            XCTAssertEqual(attachmentModel.point.x, -20.11, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.point.y, 21.6, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.rotation, 360.5, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.color.value, "fffffffe")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachment should not be nil")
                    }
                    
                    if let attachmentOmitted = slot.attachments?.first(where: { $0.model.name == "point-attachment-omitted" }) {
                        
                        if let attachmentOmittedModel = attachmentOmitted.model as? PointAttachmentModel {
                            
                            XCTAssertEqual(attachmentOmittedModel.point.x, 0, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.point.y, 0, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.rotation, 0, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.color.value, "F1F100FF")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachmentOmitted should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("slot should not be nil")
                }
                
            } else {
                
                XCTFail("skin should not be nil")
            }
            
        } else {
            
            XCTFail("skins should not be nil")
        }
    }
    
    func testClippingAttachmentModel() {
        
        //given
        let json = """
            {
                "skeleton": {
                    "hash": "FrNJhva2RVZ1bbIjdNspNttett4",
                    "spine": "3.6.32",
                    "width": 419.84,
                    "height": 686.08,
                    "images": "./images/"
                },
                "skins": {
                    "skin-name": {
                        "clipping-slot": {
                            "clipping-attachment": {
                                "name": "clipping-attachment-name",
                                "type": "clipping",
                                "end": "dust",
                                "vertexCount": 9,
                                "vertices": [66.76, 509.48, 19.98],
                                "color": "ce3a3aff"
                            },
                            "clipping-attachment-omitted": {
                                "type": "clipping",
                                "end": "dust",
                                "vertexCount": 9,
                                "vertices": [66.76, 509.48, 19.98]
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let skins = spineModel?.skins {
            
            if let skin = skins.first(where: { $0.name == "skin-name" }) {
                
                if let slot = skin.slots?.first(where: { $0.name == "clipping-slot" }) {
                    
                    if let attachment = slot.attachments?.first(where: { $0.model.name == "clipping-attachment-name" }) {
                        
                        if let attachmentModel = attachment.model as? ClippingAttachmentModel {
                            
                            XCTAssertEqual(attachmentModel.end, "dust")
                            XCTAssertEqual(attachmentModel.vertexCount, 9)
                            XCTAssertTrue(attachmentModel.vertices.count == 3)
                            XCTAssertEqual(attachmentModel.vertices[0], 66.76, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertices[1], 509.48, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.vertices[2], 19.98, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentModel.color.value, "ce3a3aff")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachment should not be nil")
                    }
                    
                    if let attachmentOmitted = slot.attachments?.first(where: { $0.model.name == "clipping-attachment-omitted" }) {
                        
                        if let attachmentOmittedModel = attachmentOmitted.model as? ClippingAttachmentModel {
                            
                            XCTAssertEqual(attachmentOmittedModel.end, "dust")
                            XCTAssertEqual(attachmentOmittedModel.vertexCount, 9)
                            XCTAssertEqual(attachmentOmittedModel.vertices[0], 66.76, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertices[1], 509.48, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.vertices[2], 19.98, accuracy: CGFloat.ulpOfOne)
                            XCTAssertEqual(attachmentOmittedModel.color.value, "CE3A3AFF")
                            
                        } else {
                            
                            XCTFail("attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("attachmentOmitted should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("slot should not be nil")
                }
                
            } else {
                
                XCTFail("skin should not be nil")
            }
            
        } else {
            
            XCTFail("skins should not be nil")
        }
    }
}
