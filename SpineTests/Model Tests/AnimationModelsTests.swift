//
//  AnimationModelsTests.swift
//  SpineTests
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import XCTest
@testable import Spine

class AnimationModelsTests: XCTestCase {
    
    func testAnimationModel() {
        
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
                "animations": {
                    "idle": {
                        "bones": {
                            "bone-name": {
                                "rotate": [{
                                        "time": 0,
                                        "angle": 55.63
                                    },
                                    {
                                        "time": 0.8,
                                        "curve": "stepped",
                                        "angle": -70.59
                                    },
                                    {
                                        "time": 0.96,
                                        "curve": [0.98, -0.26, 0.717, 1],
                                        "angle": -80.61
                                    },
                                    {
                                        "time": 1.2333
                                    },
                                    {
                                        "time": 1.6,
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 1.9667,
                                        "curve": [0.98, -0.26, 0.717, 1]
                                    }
                                ],
                                "translate": [{
                                        "time": 0,
                                        "x": -69.06,
                                        "y": 0
                                    },
                                    {
                                        "time": 0.5,
                                        "curve": "stepped",
                                        "x": -88.4,
                                        "y": 123.6
                                    },
                                    {
                                        "time": 1.33,
                                        "curve": [0.591, 0, 0.642, 1],
                                        "x": -88.4,
                                        "y": 123.6
                                    },
                                    {
                                        "time": 2.45
                                    },
                                    {
                                        "time": 3.5,
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 4.345,
                                        "curve": [0.591, 0, 0.642, 1]
                                    }
                                ],
                                "scale": [{
                                        "time": 0,
                                        "x": 0.645,
                                        "y": 1.426
                                    },
                                    {
                                        "time": 0.4,
                                        "curve": "stepped",
                                        "x": 0.685,
                                        "y": 1.516
                                    },
                                    {
                                        "time": 1,
                                        "curve": [0.823, 0.24, 0.867, 0.66],
                                        "x": 0.67,
                                        "y": 1.481
                                    },
                                    {
                                        "time": 1.2333
                                    },
                                    {
                                        "time": 1.6,
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 1.9667,
                                        "curve": [0.823, 0.24, 0.867, 0.66]
                                    }
                                ],
                                "shear": [{
                                        "time": 0,
                                        "x": 0,
                                        "y": 4.63
                                    },
                                    {
                                        "time": 0.43,
                                        "curve": "stepped",
                                        "x": -5.74,
                                        "y": 4.63
                                    },
                                    {
                                        "time": 1.123,
                                        "curve": [0.823, 0.24, 0.867, 0.66],
                                        "x": 1.67,
                                        "y": 34.481
                                    },
                                    {
                                        "time": 1.28
                                    },
                                    {
                                        "time": 1.667,
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 1.923,
                                        "curve": [0.823, 0.24, 0.867, 0.66]
                                    }
                                ]
                            }
                        },
                        "slots": {
                            "slot-name": {
                                "color": [{
                                        "time": 0,
                                        "color": "ffffff3e"
                                    },
                                    {
                                        "time": 0.0667,
                                        "color": "ffffff00",
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 0.1333,
                                        "color": "fffffffe",
                                        "curve": [0.823, 0.24, 0.867, 0.66]
                                    }
                                ],
                                "attachment": [{
                                        "time": 0,
                                        "name": "front-fist-open"
                                    },
                                    {
                                        "time": 0.0667,
                                        "name": null
                                    }
                                ]
                            }
                        },
                        "ik": {
                            "constraint-name": [{
                                    "time": 0,
                                    "mix": 0.75,
                                    "blendPositive": true
                                },
                                {
                                    "time": 0.1333
                                }
                            ]
                        },
                        "transform": {
                            "constraint-name": [{
                                    "time": 0,
                                    "rotateMix": 0.784,
                                    "translateMix": 0.659,
                                    "scaleMix": 0.423,
                                    "shearMix": 0.358
                                },
                                {
                                    "time": 0.0667
                                }
                            ]
                        },
                        "deform": {
                            "skin-name": {
                                "slot-name": {
                                    "mesh-attachment-name": [{
                                            "time": 0,
                                            "offset": 16,
                                            "vertices": [-0.18341, -4.60426, -0.25211, -6.33094]
                                        },
                                        {
                                            "time": 0.0667,
                                            "vertices": [-0.18341, -4.60426, -0.25211, -6.33094]
                                        }
                                    ]
                                }
                            }
                        },
                        "events": [{
                                "time": 0,
                                "name": "footstep",
                                "int": -3,
                                "float": 0.123,
                                "string": "some-string"
                            },
                            {
                                "time": 1.1333,
                                "name": "footstep"
                            }
                        ],
                        "drawOrder": [{
                            "time": 0.3,
                            "offsets": [{
                                    "slot": "smoke-puff1-bg2",
                                    "offset": 24
                                },
                                {
                                    "slot": "smoke-puff1-fg4",
                                    "offset": -4
                                }
                            ]
                        }]
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let animations = spineModel?.animations {
            
            if let idleAnimation = animations.first(where: { $0.name == "idle" }) {
                
                XCTAssertNotNil(idleAnimation.groups.first(where: { $0.identifier == "bones" }))
                XCTAssertNotNil(idleAnimation.groups.first(where: { $0.identifier == "slots" }))
                XCTAssertNotNil(idleAnimation.groups.first(where: { $0.identifier == "ik" }))
                XCTAssertNotNil(idleAnimation.groups.first(where: { $0.identifier == "transform" }))
                XCTAssertNotNil(idleAnimation.groups.first(where: { $0.identifier == "deform" }))
                XCTAssertNotNil(idleAnimation.groups.first(where: { $0.identifier == "events" }))
                XCTAssertNotNil(idleAnimation.groups.first(where: { $0.identifier == "draworder" }))
                
            } else {
                
                XCTFail("idleAnimation should not be nil")
            }
            
        } else {
            
            XCTFail("animations should not be nil")
        }
        
    }
    
    func testBoneAnimationModel() {
        
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
                "animations": {
                    "idle": {
                        "bones": {
                            "bone-name": {
                                "rotate": [{
                                        "time": 0,
                                        "angle": 55.63
                                    },
                                    {
                                        "time": 0.8,
                                        "curve": "stepped",
                                        "angle": -70.59
                                    },
                                    {
                                        "time": 0.96,
                                        "curve": [0.98, -0.26, 0.717, 1],
                                        "angle": -80.61
                                    },
                                    {
                                        "time": 1.2333
                                    },
                                    {
                                        "time": 1.6,
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 1.9667,
                                        "curve": [0.98, -0.26, 0.717, 1]
                                    }
                                ],
                                "translate": [{
                                        "time": 0,
                                        "x": -69.06,
                                        "y": 0
                                    },
                                    {
                                        "time": 0.5,
                                        "curve": "stepped",
                                        "x": -88.4,
                                        "y": 123.6
                                    },
                                    {
                                        "time": 1.33,
                                        "curve": [0.591, 0, 0.642, 1],
                                        "x": -88.4,
                                        "y": 123.6
                                    },
                                    {
                                        "time": 2.45
                                    },
                                    {
                                        "time": 3.5,
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 4.345,
                                        "curve": [0.591, 0, 0.642, 1]
                                    }
                                ],
                                "scale": [{
                                        "time": 0,
                                        "x": 0.645,
                                        "y": 1.426
                                    },
                                    {
                                        "time": 0.4,
                                        "curve": "stepped",
                                        "x": 0.685,
                                        "y": 1.516
                                    },
                                    {
                                        "time": 1,
                                        "curve": [0.823, 0.24, 0.867, 0.66],
                                        "x": 0.67,
                                        "y": 1.481
                                    },
                                    {
                                        "time": 1.2333
                                    },
                                    {
                                        "time": 1.6,
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 1.9667,
                                        "curve": [0.823, 0.24, 0.867, 0.66]
                                    }
                                ],
                                "shear": [{
                                        "time": 0,
                                        "x": 0,
                                        "y": 4.63
                                    },
                                    {
                                        "time": 0.43,
                                        "curve": "stepped",
                                        "x": -5.74,
                                        "y": 4.63
                                    },
                                    {
                                        "time": 1.123,
                                        "curve": [0.823, 0.24, 0.867, 0.66],
                                        "x": 1.67,
                                        "y": 34.481
                                    },
                                    {
                                        "time": 1.28
                                    },
                                    {
                                        "time": 1.667,
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 1.923,
                                        "curve": [0.823, 0.24, 0.867, 0.66]
                                    }
                                ]
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let animations = spineModel?.animations {
            
            if let idleAnimation = animations.first(where: { $0.name == "idle" }) {
                
                if let bonesGroup = idleAnimation.groups.first(where: { $0.identifier == "bones" }) {
                    
                    if let bonesAnimationModels = bonesGroup.models as? [BoneAnimationModel] {
                        
                        if let boneAnimationsModels = bonesAnimationModels.first(where: { $0.bone == "bone-name" }) {

                            // bone rotate keyframes
                            
                            if let boneAnimationsRotateTimeline = boneAnimationsModels.timelines.first(where: { $0.identifier == "rotate" }) {
                                
                                if let boneAnimationRotateModels = boneAnimationsRotateTimeline.models  as? [BoneKeyframeRotateModel] {
                                    
                                    XCTAssertTrue(boneAnimationRotateModels.count == 6)
                                    
                                } else {
                                    
                                    XCTFail("boneAnimationRotateModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTFail("boneAnimationsRotateTimeline should not be nil")
                            }
                            
                            // bone translate keyframes
                            
                            if let boneAnimationsTranslateTimeline = boneAnimationsModels.timelines.first(where: { $0.identifier == "translate" }) {
                                
                                if let boneAnimationTranslateModels = boneAnimationsTranslateTimeline.models  as? [BoneKeyframeTranslateModel] {
                                    
                                    XCTAssertTrue(boneAnimationTranslateModels.count == 6)
                                    
                                } else {
                                    
                                    XCTFail("boneAnimationTranslateModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTFail("boneAnimationsTranslateTimeline should not be nil")
                            }
                            
                            // bone scale keyframes
                            
                            if let boneAnimationsScaleTimeline = boneAnimationsModels.timelines.first(where: { $0.identifier == "scale" }) {
                                
                                if let boneAnimationScaleModels = boneAnimationsScaleTimeline.models  as? [BoneKeyframeScaleModel] {
                                    
                                    XCTAssertTrue(boneAnimationScaleModels.count == 6)
                                    
                                } else {
                                    
                                    XCTFail("boneAnimationScaleModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTFail("boneAnimationsScaleTimeline should not be nil")
                            }
                            
                            // bone shear keyframes
                            
                            if let boneAnimationsShearTimeline = boneAnimationsModels.timelines.first(where: { $0.identifier == "shear" }) {
                                
                                if let boneAnimationShearModels = boneAnimationsShearTimeline.models  as? [BoneKeyframeShearModel] {
                                    
                                    XCTAssertTrue(boneAnimationShearModels.count == 6)
                                    
                                } else {
                                    
                                    XCTFail("boneAnimationShearModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTFail("boneAnimationsShearTimeline should not be nil")
                            }
                            
                        } else {
                            
                            XCTFail("boneAnimationsModels should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("bonesAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("bonesGroup should not be nil")
                }
                
            } else {
                
                XCTFail("idleAnimation should not be nil")
            }
            
        } else {
            
           XCTFail("animations should not be nil")
        }
        
    }
    
    func testSlotAnimationModel() {
        
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
                "animations": {
                    "idle": {
                        "slots": {
                            "slot-name": {
                                "color": [{
                                        "time": 0,
                                        "color": "ffffff3e"
                                    },
                                    {
                                        "time": 0.0667,
                                        "color": "ffffff00",
                                        "curve": "stepped"
                                    },
                                    {
                                        "time": 0.1333,
                                        "color": "fffffffe",
                                        "curve": [0.823, 0.24, 0.867, 0.66]
                                    }
                                ],
                                "attachment": [{
                                        "time": 0,
                                        "name": "front-fist-open"
                                    },
                                    {
                                        "time": 0.0667,
                                        "name": null
                                    }
                                ]
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let animations = spineModel?.animations {
            
            if let idleAnimation = animations.first(where: { $0.name == "idle" }) {
                
                if let slotsGroup = idleAnimation.groups.first(where: { $0.identifier == "slots" }) {
                    
                    if let slotsAnimationModels = slotsGroup.models as? [SlotAnimationModel] {
                        
                        if let slotAnimationsModels = slotsAnimationModels.first(where: { $0.slot == "slot-name" }) {
                            
                            // slot attachment keyframes
                            
                            if let slotAnimationsAttachmentTimeline = slotAnimationsModels.timelines.first(where: { $0.identifier == "attachment" }) {
                                
                                if let slotAnimationAttachmentModels = slotAnimationsAttachmentTimeline.models  as? [SlotKeyframeAttachmentModel] {
                                    
                                    XCTAssertTrue(slotAnimationAttachmentModels.count == 2)
                                    
                                } else {
                                    
                                    XCTFail("slotAnimationAttachmentModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTFail("slotAnimationsAttachmentTimeline should not be nil")
                            }
                            
                            // slot color keyframes
                            
                            if let slotAnimationsColorTimeline = slotAnimationsModels.timelines.first(where: { $0.identifier == "color" }) {
                                
                                if let slotAnimationColorModels = slotAnimationsColorTimeline.models  as? [SlotKeyframeColorModel] {
                                    
                                    XCTAssertTrue(slotAnimationColorModels.count == 3)
                                    
                                } else {
                                    
                                    XCTFail("slotAnimationColorModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTFail("slotAnimationsColorTimeline should not be nil")
                            }
                            
                        } else {
                            
                            XCTFail("slotAnimationsModels should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("slotsAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("slotsGroup should not be nil")
                }
                
            } else {
                
                XCTFail("idleAnimation should not be nil")
            }
            
        } else {
            
            XCTFail("animations should not be nil")
        }
        
    }
    
    func testIKConstraintAnimationModel() {
        
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
                "animations": {
                    "idle": {
                        "ik": {
                            "constraint-name": [{
                                    "time": 0,
                                    "mix": 0.75,
                                    "blendPositive": true
                                },
                                {
                                    "time": 0.1333
                                }
                            ]
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let animations = spineModel?.animations {
            
            if let idleAnimation = animations.first(where: { $0.name == "idle" }) {
                
                if let ikGroup = idleAnimation.groups.first(where: { $0.identifier == "ik" }) {
                    
                    if let ikConstraintsAnimationModels = ikGroup.models as? [IKConstraintAnimationModel] {
                        
                        if let ikConstraintAnimationsModel = ikConstraintsAnimationModels.first(where: { $0.constraint == "constraint-name" }) {
                            
                            XCTAssertTrue(ikConstraintAnimationsModel.keyframes.count == 2)

                            
                        } else {
                            
                            XCTFail("ikConstraintAnimationsModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("ikConstraintsAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("ikGroup should not be nil")
                }
                
            } else {
                
                XCTFail("idleAnimation should not be nil")
            }
            
        } else {
            
            XCTFail("animations should not be nil")
        }
        
    }
    
    func testTransformConstraintAnimationModel() {
        
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
                "animations": {
                    "idle": {
                        "transform": {
                            "constraint-name": [{
                                    "time": 0,
                                    "rotateMix": 0.784,
                                    "translateMix": 0.659,
                                    "scaleMix": 0.423,
                                    "shearMix": 0.358
                                },
                                {
                                    "time": 0.0667
                                }
                            ]
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let animations = spineModel?.animations {
            
            if let idleAnimation = animations.first(where: { $0.name == "idle" }) {
                
                if let transformGroup = idleAnimation.groups.first(where: { $0.identifier == "transform" }) {
                    
                    if let transformConstraintsAnimationModels = transformGroup.models as? [TransformConstraintAnimationModel] {
                        
                        if let transformConstraintAnimationsModel = transformConstraintsAnimationModels.first(where: { $0.constraint == "constraint-name" }) {
                            
                            XCTAssertTrue(transformConstraintAnimationsModel.keyframes.count == 2)
                            
                            
                        } else {
                            
                            XCTFail("transformConstraintAnimationsModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("transformConstraintsAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("transformGroup should not be nil")
                }
                
            } else {
                
                XCTFail("idleAnimation should not be nil")
            }
            
        } else {
            
            XCTFail("animations should not be nil")
        }
        
    }
    
    func testDeformSkinAnimationModel() {
        
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
                "animations": {
                    "idle": {
                        "deform": {
                            "skin-name": {
                                "slot-name": {
                                    "mesh-attachment-name": [{
                                            "time": 0,
                                            "offset": 16,
                                            "vertices": [-0.18341, -4.60426, -0.25211, -6.33094]
                                        },
                                        {
                                            "time": 0.0667,
                                            "vertices": [-0.18341, -4.60426, -0.25211, -6.33094]
                                        }
                                    ]
                                }
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let animations = spineModel?.animations {
            
            if let idleAnimation = animations.first(where: { $0.name == "idle" }) {
                
                if let deformGroup = idleAnimation.groups.first(where: { $0.identifier == "deform" }) {
                    
                    if let deformSkinsAnimationModels = deformGroup.models as? [DeformSkinAnimationModel] {
                        
                        if let deformSkinAnimationModel = deformSkinsAnimationModels.first(where: { $0.skin == "skin-name" }) {
                            
                            if let deformSlotAnimationModel = deformSkinAnimationModel.slots.first(where: { $0.slot == "slot-name" }) {
                                
                                if let deformMeshAnimationModel = deformSlotAnimationModel.meshes.first(where: { $0.mesh == "mesh-attachment-name" }) {
                                    
                                    XCTAssertTrue(deformMeshAnimationModel.keyframes.count == 2)
                                    
                                } else {
                                    
                                    XCTFail("deformMeshAnimationModel should not be nil")
                                }
                                
                            } else {
                                
                                XCTFail("deformSlotAnimationModel should not be nil")
                                
                            }
                            
                        } else {
                            
                            XCTFail("deformSkinAnimationModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTFail("deformSkinsAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("deformGroup should not be nil")
                }
                
            } else {
                
                XCTFail("idleAnimation should not be nil")
            }
            
        } else {
            
            XCTFail("animations should not be nil")
        }
        
    }
    
    func testEeventAnimationModel() {
        
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
                "animations": {
                    "idle": {
                        "events": [{
                                "time": 0,
                                "name": "footstep",
                                "int": -3,
                                "float": 0.123,
                                "string": "some-string"
                            },
                            {
                                "time": 1.1333,
                                "name": "footstep"
                            }
                        ]
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let animations = spineModel?.animations {
            
            if let idleAnimation = animations.first(where: { $0.name == "idle" }) {
                
                if let eventsGroup = idleAnimation.groups.first(where: { $0.identifier == "events" }) {
                    
                    if let eventsAnimationKeyframes = eventsGroup.models as? [EventKeyfarameModel] {
                        
                        XCTAssertTrue(eventsAnimationKeyframes.count == 2)
                        
                    } else {
                        
                        XCTFail("eventsAnimationKeyframes should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("eventsGroup should not be nil")
                }
                
            } else {
                
                XCTFail("idleAnimation should not be nil")
            }
            
        } else {
            
            XCTFail("animations should not be nil")
        }
        
    }
    
    func testDrawOrderAnimationModel() {
        
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
                "animations": {
                    "idle": {
                        "drawOrder": [{
                            "time": 0.3,
                            "offsets": [{
                                    "slot": "smoke-puff1-bg2",
                                    "offset": 24
                                },
                                {
                                    "slot": "smoke-puff1-fg4",
                                    "offset": -4
                                }
                            ]
                        }]
                    }
                }
            }
            """.data(using: .utf8)!
        
        //when
        let spineModel = try? JSONDecoder().decode(SpineModel.self, from: json)
        
        //then
        if let animations = spineModel?.animations {
            
            if let idleAnimation = animations.first(where: { $0.name == "idle" }) {
                
                if let drawOrederGroup = idleAnimation.groups.first(where: { $0.identifier == "draworder" }) {
                    
                    if let drawOrderAnimationKeyframes = drawOrederGroup.models as? [DrawOrderKeyframeModel] {
                        
                        if let drawOrderAnimationKeyframe = drawOrderAnimationKeyframes.first {
                            
                            XCTAssertEqual(drawOrderAnimationKeyframe.time, 0.3, accuracy: TimeInterval.ulpOfOne)
                            
                            if let offsets = drawOrderAnimationKeyframe.offsets {
                                
                                XCTAssertTrue(offsets.count == 2)
                                
                            } else {
                                
                                XCTFail("offsets should not be nil")
                            }
    
                        } else {
                            
                            XCTFail("drawOrderAnimationKeyframe should not be nil")
                        }

                    } else {
                        
                        XCTFail("drawOrderAnimationKeyframes should not be nil")
                    }
                    
                } else {
                    
                    XCTFail("drawOrederGroup should not be nil")
                }
                
            } else {
                
                XCTFail("idleAnimation should not be nil")
            }
            
        } else {
            
            XCTFail("animations should not be nil")
        }
    }
}
