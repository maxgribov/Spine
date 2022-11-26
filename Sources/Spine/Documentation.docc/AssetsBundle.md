# Assets from the bundle

The library uses the native SpriteKit texture atlases `SKTextureAtlas`, and the opportunities for adding and editing sprite atlases in Xcode IDE.

Below it will be shown in detail how to correctly upload images to the Xcode bundle of the project so that they are then loaded correctly together with the character.

>Tip: To find out how you can download images from the server, collect them in atlases and use them to install character skins, you can read here:

>Texture atlases of the Spine application itself are not used by the library. So you don't even have to worry about exporting them from there.

>Also you can't use separate images located anywhere in the assets of your Xcode project. All images **must** be collected in sprite atlases. This is due to the optimizations that SpriteKit applies to texture atlases.

## Prepare images for animation

Apple devices have screens with different resolutions, so we usually have to prepare multiple versions of the same image:

![](spine_wiki_assets_raw_images.png)

Since Spine doesn't support multiple resolution images, just use basic version image as `orange_bottle.png` from the example above. Use version `@2x` or `@3x` will lead to the fact that the size of the character when you import in Xcode will be incorrect.

## Organising images in the Spine project

### Default skin

The Spine project always has a default skin named **default** that is created automatically. All images in the root of the `Images` folder must be added to the `default` atlas in the Xcode project later:

![](spine_wiki_assets_spine_default.png)

### Named skin

For each of the skin with the certain name, create a folder with an appropriate name and put all the images for this skin in it:

![](spine_wiki_assets_spine_named.png)

### Multiple skins 

If you have several skins, you must spread out images on folders with the appropriate names. Images not related to any particular skins should be in the root of folder `Images`:

![](spine_wiki_assets_spine_multiple.png)

>Technically it doesn't matter how you organize the images in the Spine project. Spine itself there are no restrictions for this. We just organize the images in such a way that they are easier to spread out into Xcode atlases, and we could have them properly loaded into SpriteKit.

## Adding images to Xcode project

### Folder

Inside the asset catalog `.xcassets` create a new folder. In this folder further we will create sprite atlases for our character:

![](spine_wiki_assets_folder.png)

Choose a name for the folder that makes sense in the context of your project and is understandable to you. Later, we will need this name in the project code.

### Sprite Atlases

Inside the folder, create a new sprite atlas:

![](spine_wiki_assets_atlas.png)

Add images to the atlas and additional versions of images for other resolutions:

![](spine_wiki_assets_atlas_sprites.png)

By the way, you can add image versions for each platform if you need:

![](spine_wiki_assets_sprite_resoulutions.png)

In the end, it should look something like this:

![](spine_wiki_assets_final.png)

This is how the structure of the `Images` folder in the Spine project should look compared to the structure of atlases in the Xcode project:

![](spine_readme_assets.png)

### Namespaces

You **must** enable the `Provides Namespace` option on the folder and all nested atlases in Xcode'a attribute inspector:

![](spine_readme_assets_namespace.png)

>Warning: If you forget to enable this option, the library will simply not be able to upload images for your character
