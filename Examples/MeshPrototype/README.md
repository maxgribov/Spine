# Spine Mesh Example

A macOS SpriteKit example with both the experimental renderer and the library mesh runtime. Each renderer provides a character scene and an environment scene.

## Run

From the repository root with Xcode installed:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype
```

To start the library renderer in the environment scene:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --library --integration
```

You can also open this example's package in Xcode and run the MeshPrototype scheme.

## Controls

| Key | Action |
|---|---|
| L | Switch prototype/library renderer |
| Tab | Switch character/environment scene |
| Space | Pause or resume |
| Left / Right | Pause and step by 1/30 second |
| W | Toggle wireframe in the prototype |
| A | Toggle character transparency |
| R | Reflect characters |
| + / - | Change scale |
| 0 | Reset animation and scale |
| C | Toggle automatic camera movement in the environment |

Prototype options include `--bounds mesh` or `--bounds triangle`, and `--group-size 1`, `2` or `4`. Triangle bounds and groups of two are the defaults. State is retained when switching scenes.

## Verification and Benchmarks

These commands are optional developer tools and produce results in the specified output directory:

```sh
swift test --package-path Examples/MeshPrototype
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify /tmp/spine-prototype
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-integration /tmp/spine-integration
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-scenes /tmp/spine-library-scenes
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-mesh /tmp/spine-library-mesh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --benchmark /tmp/spine-benchmark
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --benchmark-groups /tmp/spine-groups
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --benchmark-library-mesh /tmp/spine-library-performance
python3 Examples/MeshPrototype/Scripts/benchmark-library-legacy-matched.py --output /tmp/spine-legacy-matched
```

Library checks preserve the basic runtime's reference images and compare mesh geometry and rendering with independent references. Legacy reference fixtures are kept in `Fixtures/legacy-baseline`. Benchmark CPU, GPU and callback measurements are distinct; callback FPS is not a count of presented frames. Tests and benchmarks need an unlocked, visible desktop for native rendering.

Historical prototype results are summarized in [RESULTS.md](RESULTS.md), [PERFORMANCE.md](PERFORMANCE.md), [CPU-PERFORMANCE.md](CPU-PERFORMANCE.md), [GROUP-PERFORMANCE.md](GROUP-PERFORMANCE.md) and [INTEGRATION.md](INTEGRATION.md). They describe the recorded fixture and machine, not universal performance guarantees. Automated render readbacks do not imply desktop UI automation.

## Asset License

The example contains the official Spine Goblins export from the 4.1 branch, revision `77a5db0ec6d16331f5efbaa7662bba9355bd3424`. Assets are bundled; nothing is downloaded at launch.

Goblins artwork is copyright Esoteric Software LLC. Redistribution must include the original `goblins-license.txt`; commercial use of this artwork is prohibited. These are demonstration assets, not artwork for a commercial game. The library's MIT license does not replace the asset license.
