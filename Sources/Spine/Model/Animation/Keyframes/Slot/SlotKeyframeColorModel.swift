//
//  SlotKeyframeColorModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct SlotKeyframeColorModel {

    var channels: [Channel]

    init(channels: [Channel]) {
        
        self.channels = channels
    }
}

extension SlotKeyframeColorModel {
    
    struct Channel: CurvedKeyframeModel {
        
        let time: TimeInterval
        let value: ColorChannel
        var curve: CurveModel
        
        var values: [Float] { [Float(value)] }
    }
}

extension SlotKeyframeColorModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, color, curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        let color = try container.decode(ColorModel.self, forKey: .color)
        do {
            
            let curve = try container.decode(CurveModel.self, forKey: .curve)
            let keyframes = color.channels.map{ SlotKeyframeColorModel.Channel(time: time, value: $0, curve: curve) }
            self.init(channels: keyframes)
            
        } catch {
            
            if let curveValues = try? container.decode([Float].self, forKey: .curve), curveValues.count == 4 * 4 {
                
                var channels = [SlotKeyframeColorModel.Channel]()
                for (index, channel) in color.channels.enumerated() {
                    
                    let p0 = curveValues[index]
                    let p1 = curveValues[index + 1]
                    let p2 = curveValues[index + 2]
                    let p3 = curveValues[index + 3]
                    let curve = BezierCurveModel(p0: p0, p1: p1, p2: p2, p3: p3)
                    let keyframe = SlotKeyframeColorModel.Channel(time: time, value: channel, curve: .bezier(curve))
                    channels.append(keyframe)
                }
                
                self.init(channels: channels)
                
            } else {
                
                let channels = color.channels.map{ SlotKeyframeColorModel.Channel(time: time, value: $0, curve: .linear) }
                self.init(channels: channels)
            }
        }
    }
}
