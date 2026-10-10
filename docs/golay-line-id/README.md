# Golay24 thin-line experiment

Black L corners plus two duplicate 24-cell black/white border codes. Constant-weight12 subset of extended binary Golay [24,12,8]: **2576 distinct IDs**, minimum Hamming distance8. Default decoder allows at most1 wrong observed bit and3 missing bits, with unique decoding bound2e+r<8. This is coding capacity, not a device reliability guarantee.

Use matching24-slot targets; existing16-slot papers are incompatible. Asymmetric direction marks are required. No temporal fusion, fallback, held display or smoothing. Normal camera2D, not WebXR.

At unchanged640×880 target coordinates: height8, length14, cell pitch15.13. Fourteen-pixel marks leave1.13 gaps and add50% ID ink relative to eight14-pixel marks in the30-ID16-cell layout. Optional length8 uses smaller marks and14.3% less ink, potentially harder to read.

Private verification before publication: all2576 ideal rendered codes for two lengths5152/5152; rotated/reflected synthetic2400 positive reads correct and2400 negative opportunities rejected; actual blank-camera12 frames emitted no IDs. These are not positive real-camera validation. Fresh Quest optical trials are required before recommending capacity.

The L backend is frozen for repeatable experimental comparison. See `camera.html` and `targets.html?count=10&length=14&thickness=8`.
