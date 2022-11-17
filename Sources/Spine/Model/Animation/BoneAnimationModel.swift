//
//  BoneAnimationModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct BoneAnimationModel {
    
    let bone: String
    let timelines: [Timeline]
}

//MARK: - Types

extension BoneAnimationModel {

    enum Timeline {
        
        case rotate([BoneKeyframeRotateModel])
        case translate([BoneKeyframeTranslateModel])
        case scale([BoneKeyframeScaleModel])
        case shear([BoneKeyframeShearModel])
    }
}

//MARK: - Decoding

extension BoneAnimationModel: SpineDecodableDictionary {

    enum Keys: String, CodingKey {
        
        case rotate, translate, scale, shear
    }
    
    typealias KeysType = Keys

    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var timelines = [Timeline]()
        
        for timelineKey in container.allKeys {
            
            switch timelineKey {
            case .rotate:
                let rotateKeyframes = try container.decode([BoneKeyframeRotateModel].self, forKey: .rotate)
                let adjustedRotateKeyframes = try adjustedCurves(rotateKeyframes)
                timelines.append(.rotate(adjustedRotateKeyframes))

            case .translate:
                let translateKeyframes = try container.decode([BoneKeyframeTranslateModel].self, forKey: .translate)
                let adjustedTranslateKeyframes = try adjustedCurves(translateKeyframes)
                timelines.append(.translate(adjustedTranslateKeyframes))

            case .scale:
                let scaleKeyframes = try container.decode([BoneKeyframeScaleModel].self, forKey: .scale)
                let adjustedScaleKeyframes = try adjustedCurves(scaleKeyframes)
                timelines.append(.scale(adjustedScaleKeyframes))

            case .shear:
                let shearKeyframes = try container.decode([BoneKeyframeShearModel].self, forKey: .shear)
                let adjustedShearKeyframes = try adjustedCurves(shearKeyframes)
                timelines.append(.shear(adjustedShearKeyframes))
            }
        }
        
        self.bone = name
        self.timelines = timelines
    }
}
