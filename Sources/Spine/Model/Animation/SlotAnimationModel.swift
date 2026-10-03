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
    let numericTimelines: [NumericTimelineModel]
    let meshDecodeErrors: [Error]
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
        var numericTimelines: [NumericTimelineModel] = []
        var meshDecodeErrors: [Error] = []
        
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
                
            case .rgb, .alpha:
                do {
                    let frames=try container.decode([SlotNumericKeyframeModel].self,forKey:timelineKey)
                    let keys=try frames.map { frame -> NumericTimelineModel.Key in
                        let values:[Float]
                        if timelineKey == .alpha {values=[frame.value ?? 1]}
                        else {
                            guard let color=frame.color else {throw DecodingError.keyNotFound(SlotNumericKeyframeModel.Keys.color,.init(codingPath:container.codingPath+[timelineKey],debugDescription:"Missing RGB color."))}
                            values=[Float(color.red),Float(color.green),Float(color.blue)]
                        }
                        return .init(time:frame.time,values:values,curves:frame.curves)
                    }
                    numericTimelines.append(.init(name:timelineKey.rawValue,keys:keys))
                } catch {meshDecodeErrors.append(error)}
            case .rgba:
                var keyframesContainer = try container.nestedUnkeyedContainer(forKey: .rgba)
                var keyframes = [SlotKeyframeColorModel]()
                while keyframesContainer.isAtEnd == false {
                    
                    let keyframe = try keyframesContainer.decode(SlotKeyframeColorModel.self)
                    keyframes.append(keyframe)
                }
                numericTimelines.append(.init(name:"rgba",keys:keyframes.map {
                    .init(time:$0.channels.first?.time ?? 0,values:$0.channels.map {Float($0.value)},curves:$0.channels.map(\.curve))
                }))
                meshDecodeErrors.append(contentsOf:keyframes.compactMap(\.meshCurveError))
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
        self.numericTimelines = numericTimelines
        self.meshDecodeErrors = meshDecodeErrors
    }
}


