# CPU Preparation and Shared Materials

Historical Release measurements from October 3, 2026 on Apple M1 Max and macOS 26.6. Animation data is prepared during loading, buffers are reused, and characters on the same atlas page share shader and texture resources. Per-character transforms remain independent.

| Characters | CPU pose before / after, ms | Scene update and encode before / after, ms | GPU before / after, ms | Callback FPS before / after |
|---:|---:|---:|---:|---:|
| 1 | 1.240 / 0.519 | 0.889 / 0.976 | 0.092 / 0.085 | 60 / 60 |
| 10 | 5.322 / 2.120 | 6.032 / 6.007 | 0.186 / 0.149 | 60 / 60 |
| 50 | 27.061 / 10.539 | 31.472 / 29.432 | 0.532 / 0.364 | 15 / 20 |

CPU pose preparation fell by approximately 61% for 50 characters. The separate update/encode path improved less; the measurements do not isolate the contribution of each optimization. Shared resources do not prove a particular draw-call count. Allowing arbitrary sibling order did not improve the measured result.

Image differences stayed within the existing tolerance. These are prototype results from one fixture and device, not a general performance guarantee.

Recorded data: [before](Benchmarks/2026-10-03-cpu-before.json), [after](Benchmarks/2026-10-03-cpu-after.json). Triangle grouping is summarized in [GROUP-PERFORMANCE.md](GROUP-PERFORMANCE.md).
