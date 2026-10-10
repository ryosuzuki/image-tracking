# Golay24 thin-line experiment

Black L corners plus two duplicate 24-cell black/white border codes. Constant-weight12 subset of extended binary Golay [24,12,8]: **2576 distinct IDs**, minimum Hamming distance8. Default decoder allows at most1 wrong observed bit and3 missing bits, with unique decoding bound2e+r<8. This is coding capacity, not a device reliability guarantee.

Use matching24-slot targets; existing16-slot papers are incompatible. Asymmetric direction marks are required. No temporal fusion, held display or smoothing. Guarded fallback is opt-in, default OFF. Normal camera2D, not WebXR.

At unchanged640×880 target coordinates: height8, length14, cell pitch15.13. Fourteen-pixel marks leave1.13 gaps and add50% ID ink relative to eight14-pixel marks in the30-ID16-cell layout. Optional length8 uses smaller marks and14.3% less ink, potentially harder to read.

Private verification before publication: all2576 ideal rendered codes for two lengths5152/5152; rotated/reflected synthetic2400 positive reads correct and2400 negative opportunities rejected; actual blank-camera12 frames emitted no IDs. These are not positive real-camera validation. Subsequent Quest optical monitor trials tested50 distinct IDs, not all2576. Length14/height8 first trial984/1000 correct; length8 591/1000. Length10 had one sampled and three dense wrong007→003 reads, so this dense subtle configuration is not recommended as reliable.

The L backend is frozen for repeatable experimental comparison. See `camera.html` and `targets.html?count=10&length=14&thickness=8`.

Optional guarded low-mass reading: `?lowMassFallback=1&lowMassCascade=1`. Default OFF. Valid primary decoding and known bits are preserved; failed erasures may be filled using lower mass thresholds .045/.040 only when unique checked decoding succeeds. Fresh supplemental reads are labeled 補助読取 and counted separately, never held/temporal. Private paired RAW gains are not an independent optical robustness guarantee.

Saved-RAW independent holdout (350 frames; no new live trial): guarded fallback+cascade improves length8 591→858/1000 correct, length10 891→921/1000, dim584→592/600; motion588/600 unchanged, blank30 remains0IDs. Successful primary IDs and known bits unchanged, zero new observed wrong. Existing length10 wrong ID remains. The stricter `maxErrors=0&maxErasures=2` query rejects the three previously observed dense misreads in offline evidence, but drops other accepted outputs and is not a universal error guarantee.
