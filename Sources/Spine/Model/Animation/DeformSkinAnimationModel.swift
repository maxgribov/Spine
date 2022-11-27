//
//  DeformSkinAnimationModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct DeformSkinAnimationModel {
    
    let skin: String
    let slots: [Slot]
}

//MARK: - Types

extension DeformSkinAnimationModel {
    
    struct Slot {
        
        let slot: String
        let meshes: [Mesh]
        
        struct Mesh {
            
            let mesh: String
            let keyframes: [DeformKeyframeModel]
        }
    }
}

//MARK: - Decoding

extension DeformSkinAnimationModel: SpineDecodableDictionary {

    typealias KeysType = SpineNameKey

    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {

        var slots = [Slot]()

        for slotKey in container.allKeys {

            let slotContainer = try container.nestedContainer(keyedBy: Slot.KeysType.self, forKey: slotKey)
            let slotAnimation = try Slot(slotKey.stringValue, slotContainer)
            slots.append(slotAnimation)
        }
        
        self.skin = name
        self.slots = slots
    }
}

extension DeformSkinAnimationModel.Slot: SpineDecodableDictionary {

    typealias KeysType = SpineNameKey

    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {

        var meshes = [Mesh]()

        for meshKey in container.allKeys {

            var meshContainer = try container.nestedUnkeyedContainer(forKey: meshKey)
            let meshAnimation = try Mesh(meshKey.stringValue, &meshContainer)
            meshes.append(meshAnimation)
        }
        
        self.slot = name
        self.meshes = meshes
    }
}

extension DeformSkinAnimationModel.Slot.Mesh: SpineDecodableArray {

    init(_ name: String, _ container: inout UnkeyedDecodingContainer) throws {

        var keyframes = [DeformKeyframeModel]()
        while container.isAtEnd == false {

            keyframes.append(try container.decode(DeformKeyframeModel.self))
        }

        self.mesh = name
        self.keyframes = keyframes
    }
}
