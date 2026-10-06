# Triangle Bounds Performance

Historical prototype measurements from October 3, 2026 on Apple M1 Max and macOS 26.6, using Release builds. Restricting rendering to individual triangle bounds reduced estimated covered area by 6–8 times and GPU time by 1.6–2.2 times.

| Characters | GPU time before / after, ms | CPU preparation before / after, ms | Callback FPS |
|---:|---:|---:|---:|
| 1 | 0.152 / 0.092 | 1.14 / 1.22 | Approximately 60 |
| 10 | 0.347 / 0.185 | 4.71 / 5.35 | Approximately 60 |
| 50 | 1.175 / 0.529 | 23.77 / 27.10 | Approximately 15 |

The 50-character scene remained CPU-bound. GPU and CPU measurements came from different rendering paths and must not be added to claim a native frame duration. Covered area is an estimate, not a fragment or draw-call counter.

Both bounds modes remain available, with triangle bounds used by default. Existing image tolerances were preserved. Measurements apply to this fixture and device, not other platforms or arbitrary artwork.

Recorded data: [benchmark](Benchmarks/2026-10-03-m1-max.json). Subsequent CPU improvements are summarized in [CPU-PERFORMANCE.md](CPU-PERFORMANCE.md).
