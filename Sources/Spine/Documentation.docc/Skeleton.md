# ``Spine/Skeleton``

## Topics

### Initializers
- ``init(json:folder:skin:)``
- ``init(_:_:)``
- ``init(_:atlas:)``

### Skins
- ``skinsNames``
- ``applyDefaultSkin()``
- ``apply(skin:)``
- ``action(applySkin:)``

### Animations
- ``animationsNames``
- ``action(animation:)``
- ``run(animation:)``
- ``dropToDefaultsAction()``

### Textures
- ``atlases``
- ``preloadTextureAtlases(withCompletionHandler:)``
- ``preloadTextureAtlases(_:withCompletionHandler:)``

### Physics
- ``setCategoryBitMask(_:)``
- ``setCollisionBitMask(_:)``
- ``setBitMasks(category:collision:)``

### Node Tree
- ``childrenTreeInfo``
- ``regionAttachmentNode(named:)``
- ``slotNode(named:)``
- ``boneNode(named:)``
- ``apply(texture:region:)``

### Other
- ``eventTriggered``
- ``points``
- ``activePoints``

### Deprecated
- ``init(fromJSON:atlas:skin:)``
- ``init(coder:)``
- ``applySkin(named:)``
- ``animation(named:)``
