# Characters and Environment

The example keeps separate character and environment scenes. Tab switches scenes without resetting playback or controls. The environment scene includes two moving characters, scenery, transparency and a moving camera.

Characters occupy separate depth bands, preserving internal drawing order while moving in front of and behind scenery. Standard SpriteKit sprites and shapes provide the environment. This example is not a physics simulation.

Controls include pause, stepping, wireframe, reflection, scale and alpha. The environment also provides camera motion and zoom. Start it from the repository root:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --integration
```

Historical validation on Apple M1 Max and macOS 26.6 passed ten unit tests and eight image comparisons. Maximum channel difference was 3/255, within the declared integration tolerance; the original renderer checks kept their own tolerances. Scene switching and retained state were checked programmatically, not through desktop UI automation.

Crop/effect ancestors, lighting, normal maps and special blend modes were not covered. Recorded results are in [the integration data](Verification/2026-10-03-integration.json).
