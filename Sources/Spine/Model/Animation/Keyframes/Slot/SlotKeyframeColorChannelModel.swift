//
//  File.swift
//  
//
//  Created by Max Gribov on 17.11.2022.
//

import Foundation

struct SlotKeyframeColorChannelModel: CurvedKeyframeModel {
    
    let time: TimeInterval
    let channel: ColorChannelModel
    var curve: CurveModel
    
    var values: [Float] { [Float(channel.value)] }
}
