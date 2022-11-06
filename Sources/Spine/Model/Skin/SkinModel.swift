//
//  SkinModel.swift
//  
//
//  Created by Max Gribov on 06.11.2022.
//

import SpriteKit

struct SkinModel {
    
    let name: String
    let slots: [SkinSlotModel]
}

extension SkinModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case name
        case attachments
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        name = try container.decode(String.self, forKey: .name)
        
        let slotsContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: .attachments)
        
        var slots = [SkinSlotModel]()
        
        for slotKey in slotsContainer.allKeys {
            
            let slotContainer = try slotsContainer.nestedContainer(keyedBy: SkinSlotModel.KeysType.self, forKey: slotKey)
            let slot = try SkinSlotModel(slotKey.stringValue, slotContainer)
            slots.append(slot)
        }

        self.slots = slots
    }
}
