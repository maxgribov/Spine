//
//  Skeleton+Nodes.swift
//  
//
//  Created by Max Gribov on 27.11.2022.
//

import Foundation
import SpriteKit

public extension Skeleton {
    
    /**
     Information about the structure of child nodes in a convenient tree form that can be printed in the console.
     
     ```swift
     let character = try Skeleton(json: "goblins-ess", folder: "goblins", skin: "goblin")
     character.name = "goblin1"
     
     print(character.childrenTreeInfo)
     ```
     
     ```console
     Skeleton goblin1 children tree:
     bone:root
     -bone:hip
     --bone:torso
     ---bone:neck
     ----bone:head
     -----slot:head
     ------attachment:head
     -----slot:eyes
     ------attachment:eyes-closed
     ...
     ```
     */
    var childrenTreeInfo: String {
        
        var result = "Skeleton \(name ?? "") children tree:\n"
        
        for child in childrenNamesTree {
            
            result += String(repeating: "-", count: child.level)
            result += child.name
            result += "\n"
        }
        
        return result
    }
    
    /**
     Returns the `region attachment` node with a specific name if it could be found in the children tree.
     
     Region attachment node is a `SKSpriteNode` and can display an image. All images of your character are contained in such nodes.
     
     More info about attachments:
     [http://esotericsoftware.com/spine-attachments](http://esotericsoftware.com/spine-attachments)
     
     - Parameter named: region attachment node name. The name must not contain the `attachment:` prefix (as can be seen in the printout of `childrenNamesTree`). The prefix may change over time. Use only the name itself without the prefix.
     - Returns: region attachment node
     */
    func regionAttachmentNode(named: String) -> SKSpriteNode? {
        
        let nodeName = RegionAttachment.generateName(named)
        guard let node = self["//\(nodeName)"].first as? SKSpriteNode else {
            return nil
        }
        
        return node
    }
    
    /**
     Returns the `slot` node with a specific name if it could be found in the children tree.

     Slot node is a `SKNode` and contains all character attachments. Usually only one attachment is visible at a time. Switching the visibility of a attachments inside a slot is usually done with animations.
     
     More info about slots:
     [http://esotericsoftware.com/spine-slots](http://esotericsoftware.com/spine-slots)
     
     - Parameter named: slot node name. The name must not contain the `slot:` prefix (as can be seen in the printout of `childrenNamesTree`). The prefix may change over time. Use only the name itself without the prefix.
     - Returns: slot node
     */
    func slotNode(named: String) -> SKNode? {
        
        let nodeName = Slot.generateName(named)
        guard let node = self["//\(nodeName)"].first else {
            return nil
        }
        
        return node
    }
    
    /**
     Returns the `bone` node with a specific name if it could be found in the children tree.

     Bone node is a `SKSpriteNode` controls the position, rotation and size of all child nodes. The bone node usually should not contain images. It is implemented as a child of `SKSpriteNode` for one reason: `SKNode` lacks an important property - `anchorPoint`
     
     More info about bones:
     [http://esotericsoftware.com/spine-bones](http://esotericsoftware.com/spine-bones)
     
     - Parameter named: slot node name. The name must not contain the `bone:` prefix (as can be seen in the printout of `childrenNamesTree`). The prefix may change over time. Use only the name itself without the prefix.
     - Returns: bone node
     */
    func boneNode(named: String) -> SKSpriteNode? {
        
        let nodeName = Bone.generateName(named)
        guard let node = self["//\(nodeName)"].first as? SKSpriteNode else {
            return nil
        }
        
        return node
    }
    
    /**
     Applies texture to region attachment node if possible.

     The method provides a convenient way to manually replace the texture of any character attachment.
     
     >Tip: It is usually not necessary to manually install textures in attachments. Everything happens automatically during the standard character initialization and when switching skins. This feature is needed exclusively for more advanced techniques of working with character images.
     
     >Warning: The dimensions and position of the image are determined by the node itself. By applying a new texture, you may find that it does not display exactly as you expected.

     - Parameter texture: the texture you want to apply
     - Parameter named: region attachment node name. The name must not contain the `attachment:` prefix (as can be seen in the printout of `childrenNamesTree`). The prefix may change over time. Use only the name itself without the prefix.
     
     - Throws: `SpineError.unableApplyTextureToRegionAttachmentNode` if region attachment node can't be found.
     */
    func apply(texture: SKTexture, region named: String) throws {
        
        guard let node = regionAttachmentNode(named: named) else {
            throw SpineError.unableApplyTextureToRegionAttachmentNode(named)
        }
        
        node.texture = texture
    }
}

//MARK: - Private

extension Skeleton {
    
    var childrenNamesTree: [(level: Int, name: String)] {
        
        SKNode.childrenNamesTree(level: 0, node: self)
    }
}


