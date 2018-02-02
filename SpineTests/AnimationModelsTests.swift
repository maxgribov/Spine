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
    
}





