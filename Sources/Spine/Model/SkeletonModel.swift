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
