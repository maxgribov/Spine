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
            
            if let idleAnimation = animations.filter({ $0.name == "idle" }).first {
                
                XCTAssertNotNil(idleAnimation.groups.filter({ $0.identifier == "bones" }).first, "bones group should not be nil")
                XCTAssertNotNil(idleAnimation.groups.filter({ $0.identifier == "slots" }).first, "slots group should not be nil")
                XCTAssertNotNil(idleAnimation.groups.filter({ $0.identifier == "ik" }).first, "ik group should not be nil")
                XCTAssertNotNil(idleAnimation.groups.filter({ $0.identifier == "transform" }).first, "transform group should not be nil")
                XCTAssertNotNil(idleAnimation.groups.filter({ $0.identifier == "deform" }).first, "deform group should not be nil")
                XCTAssertNotNil(idleAnimation.groups.filter({ $0.identifier == "events" }).first, "events group should not be nil")
                XCTAssertNotNil(idleAnimation.groups.filter({ $0.identifier == "draworder" }).first, "draworder group should not be nil")
                
            } else {
                
                XCTAssertNotNil(nil, "idleAnimation should not be nil")
            }
            
        } else {
            
            XCTAssertNotNil(nil, "animations should not be nil")
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
            
            if let idleAnimation = animations.filter({ $0.name == "idle" }).first {
                
                if let bonesGroup = idleAnimation.groups.filter({ $0.identifier == "bones" }).first {
                    
                    if let bonesAnimationModels = bonesGroup.models as? [BoneAnimationModel] {
                        
                        if let boneAnimationsModels = bonesAnimationModels.filter({ $0.bone == "bone-name" }).first {

                            // bone rotate keyframes
                            
                            if let boneAnimationsRotateTimeline = boneAnimationsModels.timelines.filter({ $0.identifier == "rotate"}).first {
                                
                                if let boneAnimationRotateModels = boneAnimationsRotateTimeline.models  as? [BoneKeyframeRotateModel] {
                                    
                                    XCTAssertTrue(boneAnimationRotateModels.count == 6)
                                    
                                } else {
                                    
                                    XCTAssertNotNil(nil, "boneAnimationRotateModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTAssertNotNil(nil, "boneAnimationsRotateTimeline should not be nil")
                            }
                            
                            // bone translate keyframes
                            
                            if let boneAnimationsTranslateTimeline = boneAnimationsModels.timelines.filter({ $0.identifier == "translate"}).first {
                                
                                if let boneAnimationTranslateModels = boneAnimationsTranslateTimeline.models  as? [BoneKeyframeTranslateModel] {
                                    
                                    XCTAssertTrue(boneAnimationTranslateModels.count == 6)
                                    
                                } else {
                                    
                                    XCTAssertNotNil(nil, "boneAnimationTranslateModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTAssertNotNil(nil, "boneAnimationsTranslateTimeline should not be nil")
                            }
                            
                            // bone scale keyframes
                            
                            if let boneAnimationsScaleTimeline = boneAnimationsModels.timelines.filter({ $0.identifier == "scale"}).first {
                                
                                if let boneAnimationScaleModels = boneAnimationsScaleTimeline.models  as? [BoneKeyframeScaleModel] {
                                    
                                    XCTAssertTrue(boneAnimationScaleModels.count == 6)
                                    
                                } else {
                                    
                                    XCTAssertNotNil(nil, "boneAnimationScaleModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTAssertNotNil(nil, "boneAnimationsScaleTimeline should not be nil")
                            }
                            
                            // bone shear keyframes
                            
                            if let boneAnimationsShearTimeline = boneAnimationsModels.timelines.filter({ $0.identifier == "shear"}).first {
                                
                                if let boneAnimationShearModels = boneAnimationsShearTimeline.models  as? [BoneKeyframeShearModel] {
                                    
                                    XCTAssertTrue(boneAnimationShearModels.count == 6)
                                    
                                } else {
                                    
                                    XCTAssertNotNil(nil, "boneAnimationShearModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTAssertNotNil(nil, "boneAnimationsShearTimeline should not be nil")
                            }
                            
                        } else {
                            
                            XCTAssertNotNil(nil, "boneAnimationsModels should not be nil")
                        }
                        
                    } else {
                        
                        XCTAssertNotNil(nil, "bonesAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTAssertNotNil(nil, "bonesGroup should not be nil")
                }
                
            } else {
                
                XCTAssertNotNil(nil, "idleAnimation should not be nil")
            }
            
        } else {
            
            XCTAssertNotNil(nil, "animations should not be nil")
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
            
            if let idleAnimation = animations.filter({ $0.name == "idle" }).first {
                
                if let slotsGroup = idleAnimation.groups.filter({ $0.identifier == "slots" }).first {
                    
                    if let slotsAnimationModels = slotsGroup.models as? [SlotAnimationModel] {
                        
                        if let slotAnimationsModels = slotsAnimationModels.filter({ $0.slot == "slot-name" }).first {
                            
                            // slot attachment keyframes
                            
                            if let slotAnimationsAttachmentTimeline = slotAnimationsModels.timelines.filter({ $0.identifier == "attachment"}).first {
                                
                                if let slotAnimationAttachmentModels = slotAnimationsAttachmentTimeline.models  as? [SlotKeyframeAttachmentModel] {
                                    
                                    XCTAssertTrue(slotAnimationAttachmentModels.count == 2)
                                    
                                } else {
                                    
                                    XCTAssertNotNil(nil, "slotAnimationAttachmentModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTAssertNotNil(nil, "slotAnimationsAttachmentTimeline should not be nil")
                            }
                            
                            // slot color keyframes
                            
                            if let slotAnimationsColorTimeline = slotAnimationsModels.timelines.filter({ $0.identifier == "color"}).first {
                                
                                if let slotAnimationColorModels = slotAnimationsColorTimeline.models  as? [SlotKeyframeColorModel] {
                                    
                                    XCTAssertTrue(slotAnimationColorModels.count == 3)
                                    
                                } else {
                                    
                                    XCTAssertNotNil(nil, "slotAnimationColorModels should not be nil")
                                }
                                
                            } else {
                                
                                XCTAssertNotNil(nil, "slotAnimationsColorTimeline should not be nil")
                            }
                            
                        } else {
                            
                            XCTAssertNotNil(nil, "slotAnimationsModels should not be nil")
                        }
                        
                    } else {
                        
                        XCTAssertNotNil(nil, "slotsAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTAssertNotNil(nil, "slotsGroup should not be nil")
                }
                
            } else {
                
                XCTAssertNotNil(nil, "idleAnimation should not be nil")
            }
            
        } else {
            
            XCTAssertNotNil(nil, "animations should not be nil")
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
            
            if let idleAnimation = animations.filter({ $0.name == "idle" }).first {
                
                if let ikGroup = idleAnimation.groups.filter({ $0.identifier == "ik" }).first {
                    
                    if let ikConstraintsAnimationModels = ikGroup.models as? [IKConstraintAnimationModel] {
                        
                        if let ikConstraintAnimationsModel = ikConstraintsAnimationModels.filter({ $0.constraint == "constraint-name" }).first {
                            
                            XCTAssertTrue(ikConstraintAnimationsModel.keyframes.count == 2)

                            
                        } else {
                            
                            XCTAssertNotNil(nil, "ikConstraintAnimationsModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTAssertNotNil(nil, "ikConstraintsAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTAssertNotNil(nil, "ikGroup should not be nil")
                }
                
            } else {
                
                XCTAssertNotNil(nil, "idleAnimation should not be nil")
            }
            
        } else {
            
            XCTAssertNotNil(nil, "animations should not be nil")
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
            
            if let idleAnimation = animations.filter({ $0.name == "idle" }).first {
                
                if let transformGroup = idleAnimation.groups.filter({ $0.identifier == "transform" }).first {
                    
                    if let transformConstraintsAnimationModels = transformGroup.models as? [TransformConstraintAnimationModel] {
                        
                        if let transformConstraintAnimationsModel = transformConstraintsAnimationModels.filter({ $0.constraint == "constraint-name" }).first {
                            
                            XCTAssertTrue(transformConstraintAnimationsModel.keyframes.count == 2)
                            
                            
                        } else {
                            
                            XCTAssertNotNil(nil, "transformConstraintAnimationsModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTAssertNotNil(nil, "transformConstraintsAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTAssertNotNil(nil, "transformGroup should not be nil")
                }
                
            } else {
                
                XCTAssertNotNil(nil, "idleAnimation should not be nil")
            }
            
        } else {
            
            XCTAssertNotNil(nil, "animations should not be nil")
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
            
            if let idleAnimation = animations.filter({ $0.name == "idle" }).first {
                
                if let deformGroup = idleAnimation.groups.filter({ $0.identifier == "deform" }).first {
                    
                    if let deformSkinsAnimationModels = deformGroup.models as? [DeformSkinAnimationModel] {
                        
                        if let deformSkinAnimationModel = deformSkinsAnimationModels.filter({ $0.skin == "skin-name" }).first {
                            
                            if let deformSlotAnimationModel = deformSkinAnimationModel.slots.filter({ $0.slot == "slot-name" }).first {
                                
                                if let deformMeshAnimationModel = deformSlotAnimationModel.meshes.filter({ $0.mesh == "mesh-attachment-name" }).first {
                                    
                                    XCTAssertTrue(deformMeshAnimationModel.keyframes.count == 2)
                                    
                                } else {
                                    
                                    XCTAssertNotNil(nil, "deformMeshAnimationModel should not be nil")
                                }
                                
                            } else {
                                
                                XCTAssertNotNil(nil, "deformSlotAnimationModel should not be nil")
                                
                            }
                            
                        } else {
                            
                            XCTAssertNotNil(nil, "deformSkinAnimationModel should not be nil")
                        }
                        
                    } else {
                        
                        XCTAssertNotNil(nil, "deformSkinsAnimationModels should not be nil")
                    }
                    
                } else {
                    
                    XCTAssertNotNil(nil, "deformGroup should not be nil")
                }
                
            } else {
                
                XCTAssertNotNil(nil, "idleAnimation should not be nil")
            }
            
        } else {
            
            XCTAssertNotNil(nil, "animations should not be nil")
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
            
            if let idleAnimation = animations.filter({ $0.name == "idle" }).first {
                
                if let eventsGroup = idleAnimation.groups.filter({ $0.identifier == "events" }).first {
                    
                    if let eventsAnimationKeyframes = eventsGroup.models as? [EventKeyfarameModel] {
                        
                        XCTAssertTrue(eventsAnimationKeyframes.count == 2)
                        
                    } else {
                        
                        XCTAssertNotNil(nil, "eventsAnimationKeyframes should not be nil")
                    }
                    
                } else {
                    
                    XCTAssertNotNil(nil, "eventsGroup should not be nil")
                }
                
            } else {
                
                XCTAssertNotNil(nil, "idleAnimation should not be nil")
            }
            
        } else {
            
            XCTAssertNotNil(nil, "animations should not be nil")
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
            
            if let idleAnimation = animations.filter({ $0.name == "idle" }).first {
                
                if let drawOrederGroup = idleAnimation.groups.filter({ $0.identifier == "draworder" }).first {
                    
                    if let drawOrderAnimationKeyframes = drawOrederGroup.models as? [DrawOrderKeyframeModel] {
                        
                        if let drawOrderAnimationKeyframe = drawOrderAnimationKeyframes.first {
                            
                            XCTAssertEqual(drawOrderAnimationKeyframe.time, 0.3)
                            XCTAssertTrue(drawOrderAnimationKeyframe.offsets.count == 2)
                            
                        } else {
                            
                            XCTAssertNotNil(nil, "drawOrderAnimationKeyframe should not be nil")
                        }

                    } else {
                        
                        XCTAssertNotNil(nil, "drawOrderAnimationKeyframes should not be nil")
                    }
                    
                } else {
                    
                    XCTAssertNotNil(nil, "drawOrederGroup should not be nil")
                }
                
            } else {
                
                XCTAssertNotNil(nil, "idleAnimation should not be nil")
            }
            
        } else {
            
            XCTAssertNotNil(nil, "animations should not be nil")
        }
        
    }
    
}





