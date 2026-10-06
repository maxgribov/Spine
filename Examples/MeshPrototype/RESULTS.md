# Initial Prototype Results

Historical measurements from October 3, 2026 on Apple M1 Max, macOS 26.6, Xcode 26.6 and Swift 6.3.3. Numerical checks used a Debug build; the Release example also built and launched successfully.

- Three topology and recovery unit tests passed.
- Ten GPU comparison scenarios matched the reference sprites exactly, including alpha, reflection, filtering and transformed geometry.
- Both Goblins skins animated across eight sampled times.
- Official Spine 4.1.56 comparison covered 16 poses and 6,064 coordinates. Maximum position error was 0.0001740588 against a 0.005 tolerance; maximum UV error was 5.9604645e-8 against 1e-6.

Nearest filtering and curve interpolation differences were corrected. Triangle counts were not treated as draw-call counts. These results cover the recorded fixture and machine; live UI automation was not performed. Later performance work is summarized in [PERFORMANCE.md](PERFORMANCE.md).
