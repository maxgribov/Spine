//
//  SlotAnimationModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct SlotAnimationModel {
    
    let slot: String
    let timelines: [Timeline]
}

//MARK: - Types

extension SlotAnimationModel {
    
    enum Timeline {
        
        case attachment([SlotKeyframeAttachmentModel])
        case color([SlotKeyframeColorModel])
        case colorDark([SlotKeyframeColorDarkModel])
    }
}

extension SlotAnimationModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case attachment, rgb, alpha, rgba, rgba2
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var timelines = [Timeline]()
        
        for timelineKey in container.allKeys {
            
            switch timelineKey {
            case .attachment:
                var keyframesContainer = try container.nestedUnkeyedContainer(forKey: .attachment)
                var keyframes = [SlotKeyframeAttachmentModel]()
                while keyframesContainer.isAtEnd == false {
                    
                    let keyframe = try keyframesContainer.decode(SlotKeyframeAttachmentModel.self)
                    keyframes.append(keyframe)
                }
                timelines.append(.attachment(keyframes))
                
            case .rgba:
                var keyframesContainer = try container.nestedUnkeyedContainer(forKey: .rgba)
                var keyframes = [SlotKeyframeColorModel]()
                while keyframesContainer.isAtEnd == false {
                    
                    let keyframe = try keyframesContainer.decode(SlotKeyframeColorModel.self)
                    keyframes.append(keyframe)
                }
                let channelKeyframes = keyframes.map { $0.channels }.transposed()
                var channelKeyframesAdjusted = [[SlotKeyframeColorModel.Channel]]()
                for column in channelKeyframes {
                    
                    let columnAdjusted = try adjustedCurves(column)
                    channelKeyframesAdjusted.append(columnAdjusted)
                }
                
                channelKeyframesAdjusted = channelKeyframesAdjusted.transposed()
                var keyframesAdjusted = [SlotKeyframeColorModel]()
                for row in channelKeyframesAdjusted {
                    
                    let keyframe = SlotKeyframeColorModel(channels: row)
                    keyframesAdjusted.append(keyframe)
                }

                timelines.append(.color(keyframesAdjusted))
                
            default:
                break
                
                //TODO: - Implementation required for rgb + alpha
                //TODO: - [Spine Pro] rgba2
            }
        }
        
        self.slot = name
        self.timelines = timelines
    }
}


