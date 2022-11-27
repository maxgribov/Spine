//
//  ColorModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import SpriteKit

typealias ColorChannel = CGFloat

struct ColorModel: Equatable {
    
    let rgbaValue: UInt32
    
    let red: ColorChannel
    let green: ColorChannel
    let blue: ColorChannel
    let alpha: ColorChannel
    
    init(value: String) {
        
        var result: UInt32 = 0
        Scanner(string: value).scanHexInt32(&result)

        self.init(value: result)
    }
    
    init(value: UInt32) {
        
        rgbaValue = value
        red = CGFloat((value & 0xFF000000) >> 24) / 255.0
        green = CGFloat((value & 0x00FF0000) >> 16) / 255.0
        blue = CGFloat((value & 0x0000FF00) >> 8) / 255.0
        alpha = CGFloat(value & 0x000000FF) / 255.0
    }
}

//MARK: - Helpers

extension ColorModel {
        
    var skColor: SKColor { .init(red: red, green: green, blue: blue, alpha: alpha) }
    var channels: [ColorChannel] { [red, green, blue, alpha] }

    func add(color: ColorModel) -> ColorModel {
        
        ColorModel(value: rgbaValue & color.rgbaValue)
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
