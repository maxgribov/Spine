//
//  ColorModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import SpriteKit

struct ColorModel: Equatable {
    
    let value: String
    
    init(value: String) {
        
        self.value = value
    }
}

//MARK: - Helpers

extension ColorModel {
    
    var rgbaValue: UInt32 {
        
        var result: UInt32 = 0
        Scanner(string: value).scanHexInt32(&result)
        
        return result
    }
    
    var red: CGFloat { CGFloat((rgbaValue & 0xFF000000) >> 24) / 255.0 }
    var green: CGFloat { CGFloat((rgbaValue & 0x00FF0000) >> 16) / 255.0 }
    var blue: CGFloat { CGFloat((rgbaValue & 0x0000FF00) >> 8) / 255.0 }
    var alpha: CGFloat { CGFloat(rgbaValue & 0x000000FF) / 255.0 }
    
    func mix(with color: ColorModel) -> ColorModel {
        
        let rgbaResultValue: UInt32 = rgbaValue & color.rgbaValue
        let stringValue = String(format:"%2x", rgbaResultValue)
        
        return ColorModel(value: stringValue)
    }
}

//MARK: - Decoding

extension ColorModel: Decodable {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }
}
