# Skin composition fixtures

These JSON files, atlas and 4×4 opaque white PNG were authored for this repository;
no external artwork, game checkout or network resources are required. JSON region
colors distinguish hat/clothing/team variants. Logical `front`/`side` placeholders
use the texture path `swatch` to exercise the distinction between names and resources.

`wardrobe.json` contains base/default, two hats (front/back slots), two clothes
(torso/sleeves), bandana, earring, four team variants and empty/partial/escaped skins.
The earring has visible `front` setup; the empty slot has nil setup. `walk` changes front/side/nil, color,
draw order and emits `change`. The hat × clothes × earring × team matrix has 32 outfits.
`mixed.json` adds inactive mesh, linked chain, point and static box states to torso
and a deform timeline. Thus the entire torso is protected for composition.

Tests derive variants for no default, no skins, all introduced non-region types,
a newly exported rare clip, overridden default protection, and escaped `s/~`/`a/~`
keys. These variants are generated from the bundled JSON, not private production data.

From the repository root on macOS:

```sh
swift test --filter 'Composition|SkinDescription'
swift test
swift build
```

`CompositionPublicAPITests` uses the real atlas/PNG via the public provider, checks
all 32 outfits and demonstrates catalog area/conflict checks without `@testable`.

The rectangular parts have separate positions/sizes so both hats, clothing, the
team badge and earring are distinguishable in the standalone public client at
`Examples/SkinComposition`. `walk` also rotates the root for visible phase changes.
