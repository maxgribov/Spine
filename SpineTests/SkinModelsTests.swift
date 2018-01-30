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
        {"skin-name": {
            "region-slot": {
                "region-attachment": {
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
                    "type": "boundingbox",
                    "vertexCount": 6,
                    "vertices": [ -19.14, -70.3, 40.8, -118.08, 257.78, -115.62, 285.17, 57.18, 120.77, 164.95, -5.07, 76.95 ],
                    "color": "ffffff3e"
                },
                "boundingBox-attachment-omitted": {
                    "type": "boundingbox",
                    "vertexCount": 6,
                    "vertices": [ -19.14, -70.3, 40.8, -118.08, 257.78, -115.62, 285.17, 57.18, 120.77, 164.95, -5.07, 76.95 ]
                }
            },
            "mesh-slot": {
                "mesh-attachment": {
                    "type": "mesh",
                    "path": "dust",
                    "uvs": [ 0.59417, 0.23422, 0.62257, 0.30336, 0.6501, 0.37036, 0.67637, 0.38404, 0.72068, 0.4071, 0.76264, 0.42894, 1, 0.70375 ],
                    "triangles": [ 8, 9, 3, 4, 8, 3, 5, 8, 4, 6, 8, 5, 8, 6, 7, 11, 12, 13, 11, 1, 10, 0, 13, 14, 0, 11, 13, 0, 1, 11, 9, 2, 3, 1, 2, 10, 9, 10, 2 ],
                    "vertices": [ 2, 38, 18.17, 41.57, 0.72255, 39, 12.46, 46.05, 0.27745, 2, 38, 24.08, 40.76, 0.57407, 39, 16.12, 41.34, 0.42593, 2, 38, 29.81 ],
                    "hull": 15,
                    "edges": [ 14, 16, 16, 18, 18, 20, 4, 18, 20, 22, 22, 24, 24, 26, 26, 28, 22, 26, 12, 14, 10, 12, 2, 4, 2, 20, 4, 6, 6, 16, 2, 0, 0, 28, 6, 8, 8, 10 ],
                    "color": "ffffff00",
                    "width": 126,
                    "height": 69
                },
                "mesh-attachment-omitted": {
                    "type": "mesh",
                    "uvs": [ 0.59417, 0.23422, 0.62257, 0.30336, 0.6501, 0.37036, 0.67637, 0.38404, 0.72068, 0.4071, 0.76264, 0.42894, 1, 0.70375 ],
                    "triangles": [ 8, 9, 3, 4, 8, 3, 5, 8, 4, 6, 8, 5, 8, 6, 7, 11, 12, 13, 11, 1, 10, 0, 13, 14, 0, 11, 13, 0, 1, 11, 9, 2, 3, 1, 2, 10, 9, 10, 2 ],
                    "vertices": [ 2, 38, 18.17, 41.57, 0.72255, 39, 12.46, 46.05, 0.27745, 2, 38, 24.08, 40.76, 0.57407, 39, 16.12, 41.34, 0.42593, 2, 38, 29.81 ],
                    "hull": 15
                }
            },
            "linkedMesh-slot": {
                "linkedMesh-attachment": {
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
                    "type": "path",
                    "closed": true,
                    "constantSpeed": true,
                    "lengths": [ 185.21, 354.53, 478.3, 608.52, 786, 1058.49, 1138.97, 1223.96, 1303.87, 1388.23, 1471.11, 1551.64, 1633.55, 1713.27, 1799.89 ],
                    "vertexCount": 66,
                    "vertices": [ 1, 111, 11.23, 41.87, 1, 1, 111, 0.79, 41.95, 1, 1, 111, -34.72, 42.24, 1, 1, 91, -104.22, 0.41, 1, 1, 91, 0.07, 0.55, 1, 1, 91, 68.8 ],
                    "color": "ff8819ff"
                },
                "path-attachment-omitted": {
                    "type": "path",
                    "lengths": [ 185.21, 354.53, 478.3, 608.52, 786, 1058.49, 1138.97, 1223.96, 1303.87, 1388.23, 1471.11, 1551.64, 1633.55, 1713.27, 1799.89 ],
                    "vertexCount": 66,
                    "vertices": [ 1, 111, 11.23, 41.87, 1, 1, 111, 0.79, 41.95, 1, 1, 111, -34.72, 42.24, 1, 1, 91, -104.22, 0.41, 1, 1, 91, 0.07, 0.55, 1, 1, 91, 68.8 ]
                }
            },
            "point-slot": {
                "point-attachment": {
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
                    "type": "clipping",
                    "end": "dust",
                    "vertexCount": 9,
                    "vertices": [ 66.76, 509.48, 19.98, 434.54, 5.34, 336.28, 22.19, 247.93, 77.98, 159.54, 182.21, -97.56, 1452.26, -99.8, 1454.33, 843.61, 166.57, 841.02 ],
                    "color": "ce3a3aff"
                },
                "clipping-attachment-omitted": {
                    "type": "clipping",
                    "end": "dust",
                    "vertexCount": 9,
                    "vertices": [ 66.76, 509.48, 19.98, 434.54, 5.34, 336.28, 22.19, 247.93, 77.98, 159.54, 182.21, -97.56, 1452.26, -99.8, 1454.33, 843.61, 166.57, 841.02 ]
                }
            }
        }}
        """.data(using: .utf8)!
        
        //when
        let skin = try? JSONDecoder().decode(SkinModel.self, from: json)
        
        //then
        if let skin = skin {

            print("\(skin)")
            
        } else {
            
            XCTAssertNotNil(nil, "ikConstraint should not be nil")
        }
    }
    
    func testRegionAttachmentModel() {

            //given
            let json = """
            {"skin-name": {
                "region-slot": {
                    "region-attachment": {
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
            }}
            """.data(using: .utf8)!

            //when
            let skin = try? JSONDecoder().decode(SkinModel.self, from: json)

            //then
            if let skin = skin {

                if let slot = skin.slots?.filter({ $0.name == "region-slot" }).first {
                    
                    if let attachment = slot.attachments?.first {

                        if let attachmentModel = attachment.model as? RegionAttachmentModel {
                            
                            XCTAssertEqual(attachmentModel.name, "region-attachment")
                            XCTAssertEqual(attachmentModel.path, "dust")
                            XCTAssertEqual(attachmentModel.position.x, -31.79)
                            XCTAssertEqual(attachmentModel.position.y, 25.97)
                            XCTAssertEqual(attachmentModel.scale.dx, 0.463)
                            XCTAssertEqual(attachmentModel.scale.dy, 0.813)
                            XCTAssertEqual(attachmentModel.rotation, -83.07)
                            XCTAssertEqual(attachmentModel.size.width, 96)
                            XCTAssertEqual(attachmentModel.size.height, 73)
                            XCTAssertEqual(attachmentModel.color.value, "ce3a3aff")
                            
                        } else {
                            
                            XCTAssertNotNil(nil, "attachmentModel should not be nil")
                        }

                    } else {
                        
                        XCTAssertNotNil(nil, "attachment should not be nil")
                    }
                    
                    if let attachmentOmitted = slot.attachments?.last {
                        
                        if let attachmentOmittedModel = attachmentOmitted.model as? RegionAttachmentModel {
                            
                            XCTAssertEqual(attachmentOmittedModel.name, "region-attachment-omitted")
                            XCTAssertNil(attachmentOmittedModel.path)
                            XCTAssertEqual(attachmentOmittedModel.position.x, 0)
                            XCTAssertEqual(attachmentOmittedModel.position.y, 0)
                            XCTAssertEqual(attachmentOmittedModel.scale.dx, 1.0)
                            XCTAssertEqual(attachmentOmittedModel.scale.dy, 1.0)
                            XCTAssertEqual(attachmentOmittedModel.rotation, 0)
                            XCTAssertEqual(attachmentOmittedModel.size.width, 96)
                            XCTAssertEqual(attachmentOmittedModel.size.height, 73)
                            XCTAssertEqual(attachmentOmittedModel.color.value, "FFFFFFFF")
                            
                        } else {
                            
                            XCTAssertNotNil(nil, "attachmentModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTAssertNotNil(nil, "attachmentOmitted should not be nil")
                    }

                } else {
                    
                    XCTAssertNotNil(nil, "slot should not be nil")
                }

            } else {

                XCTAssertNotNil(nil, "skin should not be nil")
            }

    }
}


