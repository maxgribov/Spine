//
//  ColorModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import SpriteKit

struct ColorModel: Equatable {
    
    let value: String
    
    let rgbaValue: UInt32
    
    let redChannel: ColorChannelModel
    let greenChannel: ColorChannelModel
    let blueChannel: ColorChannelModel
    let alphaChannel: ColorChannelModel
    
    init(value: String) {
        
        self.value = value
        
        let rgbaValue = Self.rgbaValue(fom: value)
        self.rgbaValue = rgbaValue
        self.redChannel = .init(value: CGFloat((rgbaValue & 0xFF000000) >> 24) / 255.0)
        self.greenChannel = .init(value: CGFloat((rgbaValue & 0x00FF0000) >> 16) / 255.0)
        self.blueChannel = .init(value: CGFloat((rgbaValue & 0x0000FF00) >> 8) / 255.0)
        self.alphaChannel = .init(value: CGFloat(rgbaValue & 0x000000FF) / 255.0)
    }
}

//MARK: - Helpers

extension ColorModel {
        
    var channels: [ColorChannelModel] { [redChannel, greenChannel, blueChannel, alphaChannel] }
    var red: CGFloat { redChannel.value }
    var green: CGFloat { greenChannel.value }
    var blue: CGFloat { blueChannel.value }
    var alpha: CGFloat { alphaChannel.value }

    func mix(with color: ColorModel) -> ColorModel {
        
        let rgbaResultValue: UInt32 = rgbaValue & color.rgbaValue
        let stringValue = String(format:"%2x", rgbaResultValue)
        
        return ColorModel(value: stringValue)
    }
    
    static func rgbaValue(fom value: String) -> UInt32 {
        
        var result: UInt32 = 0
        Scanner(string: value).scanHexInt32(&result)
        
        return result
    }
}

//MARK: - Decoding

extension ColorModel: Decodable {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(value: value)
    }
}
