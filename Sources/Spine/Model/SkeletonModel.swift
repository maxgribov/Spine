//
//  SkeletonModel.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

///The skeleton section stores metadata about the skeleton.
struct SkeletonModel {

    ///A hash of all the skeleton data. This can be used by tools to detect if the data has changed since the last time it was loaded.
    let hash: String
    ///The version of Spine that exported the data. This can be used by tools to enforce a particular Spine version to be used.
    let spine: String
    /// The x,y coordinates of the bottom left corner of the AABB for the skeleton's attachments as it was in the setup pose in Spine.
    let position: CGPoint
    /**
     The AABB size for the skeleton's attachments as it was in the setup pose in Spine
     
     - width: The AABB width for the skeleton's attachments as it was in the setup pose in Spine. This can be used as a general size of the skeleton, though the skeleton's AABB depends on how it is posed.
     - height: The AABB height for the skeleton's attachments as it was in the setup pose in Spine.
     */
    let size: CGSize
    ///The dopesheet framerate in frames per second, as it was in Spine. Assume 30 if omitted. Nonessential.
    let fps: CGFloat
    
    ///The images path, as it was in Spine. Nonessential.
    let images: String?
    
    /// The audio path, as it was in Spine. Nonessential.
    let audio: String?
}

//MARK: - Decodable

extension SkeletonModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case hash, spine, x, y, width, height, fps, images, audio
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        hash = try container.decode(String.self, forKey: .hash)
        spine = try container.decode(String.self, forKey: .spine)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        position = .init(x: x, y: y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        size = .init(width: width, height: height)
        fps = try container.decodeIfPresent(CGFloat.self, forKey: .fps) ?? 30
        images = try container.decodeIfPresent(String.self, forKey: .images)
        audio = try container.decodeIfPresent(String.self, forKey: .audio)
    }
}


//MARK: - Slot

///The slots section describes the draw order and the available slots where attachments can be assigned.
struct SlotModel {
    
    ///The slot name. This is unique for the skeleton.
    let name: String
    ///The name of the bone that this slot is attached to.
    let bone: String
    ///The color of the slot for the setup pose. This is an 8 character string containing 4 two digit hex numbers in RGBA order. Assume "FF" for alpha if alpha is omitted. Assume "FFFFFFFF" if omitted.
    let color: ColorModel
    ///The dark color of the slot for the setup pose, used for two color tinting. This is a 6 character string containing 3 two digit hex numbers in RGB order. Omitted when two color tinting is not used.
    let dark: ColorModel?
    ///The name of the slot's attachment for the setup pose. Assume no attachment for the setup pose if omitted.
    let attachment: String?
    ///The type of blending to use when drawing the slot's visible attachment: normal, additive, multiply, or screen.
    let blend: BlendModeModelType?
    
    /**
     Initializes a new SlotModel.
     
     - Parameters:
         - name: Required
         - bone: Required
         - color: Optional, default: FFFFFFFF
         - dark: Optional
         - attachment: Optional
         - blend: Optional, default: .normal
     
     - Returns: new SlotModel.
     */
    init(_ name: String, _ bone: String, _ color: String?, _ dark: String?, _ attachment: String?, _ blend: String?) {
        
        self.name = name
        self.bone = bone
        self.color = ColorModel(color ?? "FFFFFFFF")
        self.dark = ColorModel(dark)
        self.attachment = attachment
        self.blend = BlendModeModelType(blend)
    }
    
    enum BlendModeModelType: String {
        
        case normal
        case additive
        case multiply
        case screen
        
        init?( _ value: String?) {
            
            guard let value = value else {
                return nil
            }
            
            self.init(rawValue: value)
        }
    }
}

extension SlotModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case name
        case bone
        case color
        case dark
        case attachment
        case blend
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let name: String = try container.decode(String.self, forKey: .name)
        let bone: String = try container.decode(String.self, forKey: .bone)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        let dark: String? = try container.decodeIfPresent(String.self, forKey: .dark)
        let attachment: String? = try container.decodeIfPresent(String.self, forKey: .attachment)
        let blend: String? = try container.decodeIfPresent(String.self, forKey: .blend)
        
        self.init(name, bone, color, dark, attachment, blend)
    }
}
