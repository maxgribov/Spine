# Triangle Grouping

The prototype can render one, two or four consecutive triangles per SpriteKit node. Two triangles per node are the default; the other modes remain available for comparison. Groups preserve attachment boundaries, drawing order and transparency.

Historical Release measurements from October 3, 2026 on Apple M1 Max and macOS 26.6:

| Characters | Triangles per node | Sprite nodes | CPU pose, ms | Update and encode, ms | GPU, ms | Callback FPS |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 226 | 0.599 | 0.951 | 0.084 | 60 |
| 1 | 2 | 117 | 0.539 | 0.690 | 0.090 | 60 |
| 1 | 4 | 63 | 0.561 | 0.773 | 0.105 | 60 |
| 10 | 1 | 1572 | 2.127 | 6.005 | 0.149 | 60 |
| 10 | 2 | 806 | 2.067 | 3.978 | 0.172 | 60 |
| 10 | 4 | 471 | 1.967 | 3.958 | 0.201 | 60 |
| 50 | 1 | 7860 | 10.447 | 29.573 | 0.366 | 20 |
| 50 | 2 | 4030 | 9.010 | 19.363 | 0.466 | 30 |
| 50 | 4 | 2355 | 8.525 | 19.164 | 0.565 | 30 |

Two-triangle groups provided the preferred CPU/GPU tradeoff on this fixture. Four-triangle groups reduced node counts further without increasing callback FPS. Node counts are not draw-call counts, and callback FPS is not a measurement of presented frames.

Nine unit tests and existing image checks passed. Another 160 grouping comparisons stayed within the existing 2/255 tolerance; official Spine pose checks also passed. These prototype measurements do not predict performance on other devices.

Recorded data: [benchmark](Benchmarks/2026-10-03-triangle-groups.json), [image comparisons](Benchmarks/2026-10-03-triangle-groups-images.json).
