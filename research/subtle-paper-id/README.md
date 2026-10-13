# Unobtrusive paper IDs: designing thin borders for many robust identifiers

Review date: 2026-10-09. Scope: Quest/Pixel cameras, four black L corners, and thin colored or monochrome top-edge lines. **A literature review independent of implementation and physical-device videos.** Not an exhaustive survey or patent clearance.

## Conclusions first

- **Black L corners, thin saturated colored segments and a well-separated codebook are the closest prototype candidate to the current goal.** “Color is the most robust” is unproven. Compare black L corners with fixed monochrome slots under identical conditions. This is a design judgment, not a measured ranking. [S1–S7]
- **Prior work exists.** Dynamicland's Framecodes (2016) encode identifiers in borders; AprilTag Flexible Layouts (2019) separate detection boundaries from data placement. The idea need not be invented from scratch, but existing readers do not automatically read arbitrary L corners and thin lines. Confidence: medium, based on primary sources. [S1,S4]
- **Pixels across the thinnest dimension constrain the design before ID capacity does.** Lengthening a line does not prevent color mixing, blur and registration errors when its thickness collapses to 1–2 pixels. No universal minimum mm/pixel size can be guaranteed from the literature. Confidence: high; several independent systems report distance and small-feature limitations. [S3–S6,S9]
- **Hundreds or thousands of IDs are conceivable, but four colors in six slots give 4,096 raw combinations, not robust usable IDs.** Guaranteed correction of one color substitution bounds a six-slot dictionary at no more than 215 IDs (derivation below). Actual capacity depends on the generated dictionary and camera evaluation. [S7,S8 and mathematical derivation]
- **Watermarking is a separate route to lower visibility.** StegaStamp embeds 56 bits in photographs and decodes after printing/capture, but cannot be applied unchanged to a thin white-paper top edge. Lightweight ten-target Quest-browser operation is not guaranteed. It is not the immediate first choice. Confidence: medium, original paper. [S16,S17]

## 1. Two meanings of “unobtrusive”

**Thinner** and **paler** are different. Thin features lose imaging pixels; pale features lose contrast against the background. To preserve the desired appearance, first reduce area while retaining line contrast and saturation. Pastel colors or subtle intensities on white paper may overlap under shadows, exposure and white-balance changes. This is optical design reasoning, not a comparison measured in this environment. [S5,S6]

Using the long top edge avoids occupying text/figures and gives slots more horizontal space. Connected segments, however, require estimating boundaries between adjacent colors. Start with **thin but vivid short lines in fixed slots, separated by small white gaps**, rather than a faint continuous band. With geometrically determined cells, adjacent identical colors need not be segmented as separate connected regions. [S1,S4 and design proposal]

Assign geometry to the L corners and identity to the line sequence. Four fully symmetric corners leave orientation and sheet grouping ambiguous; use start marks, asymmetric placement or an orientation-aware separated dictionary. When sheets touch or overlap, choosing the four closest corners can mix corners from different sheets. [S4,S7 and projective-geometry reasoning]

## 2. Closest precedents and transferable ideas

| Method | Verified facts | Fit and transferable ideas | Qualification |
|---|---|---|---|
| Dynamicland Framecodes, 2016 | Official archive describes recognition/tracking with border-encoded IDs | **Closest direct precedent:** borders as data carriers | Stub page lacks full specification, capacity and minimum width. [S1] |
| Dotframes / Tiny dotframes | Colored dots at each corner; radius reduced from 0.25 to 0.1 inches after 4K introduction | Distributed placement, occlusion redundancy and resolution-supported miniaturization | 5.08 mm diameter describes Dynamicland's setup, not Quest's minimum readable size. [S2,S3] |
| AprilTag Flexible Layouts | Data outside detection boundaries; circular, annular and recursive layouts | **Separate detection from coding**, with low-false-positive code generation | Requires fourfold symmetry and detection black/white boundaries; not automatic support for four open L corners. [S4] |
| ChromaTag | Color differences narrow candidates; black/white boundaries refine geometry | Separate roles for color and geometry | Authors recommend AprilTag for long distance or extreme angles. Similar recall for tags ≥70 px does not establish a thin-line limit. [S5,S6] |
| AprilTag / ArUco | Larger dictionary distances reduce incorrect decoding | Use a **separated dictionary sized only to the required IDs** | tag36h11 uses 587 codes despite 36 bits, not all 2^36 combinations. [S7,S8] |
| CALTag | Grid-cell IDs and CRC; public generation considers distance and rotation | Distributed calibration points, checks, distances and partial observations | A calibration grid, not a finished decorative-line decoder; legacy MATLAB and other code require porting. [S11,S12] |
| TopoTag | Topology plus geometry for ID/pose; authors discuss tens of thousands to millions of IDs | Alternative appearance and capacity design | Requires preserved topology; public library targets research/Win32. Thin-line deformation is not proven to preserve performance. [S13,S14] |
| Pi-Tag | Bibliography/DOI and ChromaTag references confirmed | An entry point to projective-invariant ID/geometry representations | Full original paper was not obtained/read; excluded from capacity/performance comparisons. [S15] |
| StegaStamp | Trained 400×400 decoding, 56-bit payload after correction, print-camera experiments | Low-visibility candidate for photograph-containing paper | Modifies interior images, unlike free interior content and top-edge-only coding. [S16,S17] |
| Digimarc | Official material describes watermarks, SDK/API and physical-product digital IDs | Commercial low-visibility ID/watermark example | Official capability description, not independent replication; SDK price, performance and patent claims unverified. [S18] |
| Code128 and other 1D barcodes | Readers decode bar/space widths and verify checksums | Encoding IDs through line lengths is established | Endpoint errors matter. Replacing vertical bars with horizontal short segments is not readable by the same library automatically. [S10] |

### Variable-length black lines versus fixed monochrome slots

**Both are possible**, but fixed slots are the first control for paper captured at small sizes. Length coding introduces endpoint-position errors and perspective-rectification errors into length ratios. Fixed slots let the L geometry predict cell centers for black/white or color classification. If testing lengths, make the shortest segment sufficiently large and longer segments distinctly different; include start, end, synchronization and checks. Ratios and minimum widths are unmeasured. A Morse-like sequence alone is not a robust paper-ID standard. [S10 and design reasoning]

## 3. Estimate capacity correctly

Raw capacity is q^n for q colors and n data slots. **Do not confuse total segments including synchronization, calibration and checks with ID-data slots.** Detecting an error is not correcting it: a failed checksum need not identify the original ID. [S7,S8,S12]

| Representation | Raw combinations | Mathematical upper bound for guaranteed correction of one slot substitution* |
|---|---:|---:|
| 4 colors, 4 slots | 256 | ≤19 |
| 4 colors, 6 slots | 4,096 | ≤215 |
| 4 colors, 8 slots | 65,536 | ≤2,621 |
| Monochrome, 8 slots | 256 | ≤28 |
| Monochrome, 12 slots | 4,096 | ≤315 |
| Monochrome, 16 slots | 65,536 | ≤3,855 |

* **Hamming sphere-packing bound derived here:** with known orientation and correctly positioned cells, unique correction of any single substitution requires disjoint sets of zero/one-error observations around every codeword. Each set has 1+n(q−1) members, so M≤floor(q^n/[1+n(q−1)]). This is an **upper bound, not an achievable code count**. Rotation/reversal, calibration, restrictions on repeated colors and multiple errors may reduce capacity further. “A color carries two bits” also does not imply exactly a 2× physical-length relationship between monochrome and color codes.

For minimum distance d, correcting t substitutions requires d≥2t+1 in the discrete error model. Treating unknown cells as erasures permits unique recovery of s substitutions and e erasures when 2s+e<d. **Keep ambiguous colors unknown rather than forcing a class.** Misregistration and wrong corner associations lie outside this model. [S7,S8,S12 and distance derivation]

Thus, progressing from 30 to 100 to 1,000 IDs is reasonable, but does not guarantee that 1,000 IDs fit robustly in the same six colored segments. Fix the required capacity, generate an orientation-aware dictionary with measured minimum distance, and evaluate a camera color-confusion matrix. This is a proposal, not validation of the current code's capacity or distance.

## 4. Thin lines and ten simultaneous sheets: pixels, not just millimeters

For a 210 mm-wide sheet captured at W pixels, a front-facing line t mm thick occupies W×t/210 pixels. The following is **geometry only, not a recognition threshold**.

| Captured sheet width | 1 mm thick | 2 mm thick | 2.6 mm thick | 4 mm thick |
|---:|---:|---:|---:|---:|
| 150 px | 0.71 px | 1.43 px | 1.86 px | 2.86 px |
| 300 px | 1.43 px | 2.86 px | 3.71 px | 5.71 px |
| 600 px | 2.86 px | 5.71 px | 7.43 px | 11.43 px |

**A nearby single sheet may read successfully while ten sheets in one view reduce line thickness to roughly 2 pixels.** For example, five sheets across a 1920 px frame average at most 384 px each even without gaps; a 2.6 mm line occupies about 4.75 px. Margins, field of view, angles and post-capture downsampling reduce this. Processing at 960 px yields about 2.38 px. This is not a measurement of actual Quest acquisition resolution.

Upscaling after rectification cannot restore colors lost during capture. Consider full-resolution ROI reading separated from lower-resolution whole-frame detection. Compression, chroma subsampling, display moiré and motion blur can affect colored lines. Evaluate the acquisition path and treat monitor targets and printed sheets as separate conditions. [S3–S6 and imaging-design reasoning]

### Proposed minimum-size evaluation

Compare thicknesses of 0.75/1/1.5/2/2.6/4 mm with **the same code and layout**. Independently vary segment length across short/standard/long conditions. Record image-space thickness and length. Vary distance and angle; measure color confidence, rejection, wrong IDs and first-read latency. Thin need not mean short: test whether longer thin segments across the top edge help. **These are proposed test conditions, not recommended minimum dimensions.**

## 5. Implementation priorities

1. **Complete the current black-L/top-edge color design:** original-pixel ROIs, same-frame white references and calibration, fixed cells, orientation, 30 separated codes and unknown rejection. Changing the interior must not change the ID. [S1,S4–S8 and proposal]
2. **Compare fixed monochrome cells on identical paper with equal total area.** Do not change color and geometry simultaneously; neither color nor monochrome is assumed superior. [S4–S8 and proposal]
3. **If top-edge-only reads fail, duplicate the ID at the bottom.** This increases visible area but adds tolerance to fingers/occlusion. Check agreement when both read; do not assume independent errors. [S2,S11–S14 and proposal]
4. **Increase required capacity in stages.** Report minimum distance, rotation/reversal collisions and calibration-cell counts for 30/100/1,000 dictionaries. Registering many IDs differs from detecting many in one view. [S7,S8,S12 and proposal]
5. **Keep watermarking a separate experiment.** L geometry plus StegaStamp ROI decoding is interesting when modifying photographs is acceptable, but lightweight-browser porting, training data and white-paper cover suitability are separate development tasks. [S16,S17]

### Numbers to report on Quest / Pixel

- Ten sequential sheets: completion rate for ten IDs, per-ID first-read delay, unknown/wrong IDs and decoding time.
- Ten simultaneous sheets: fraction of frames freshly decoding all ten, plus per-sheet recall. Separate retained/interpolated IDs from raw decoding.
- At least 30 IDs: similar color permutations, reversal, nonmembers, print errors, lighting transitions, hand occlusion, oblique views and movement.
- Do not mix printed sheets with monitors or normal-browser cameras with WebXR/native cameras. Changing ID encoding does not remove camera-API access restrictions.
- Consecutive frames are correlated; “60 of 90 frames” is not general recognition accuracy of 66.7%. Check reproducibility across distinct capture trials. [S4,S5 condition-dependent evaluation and project-specific proposal]

## 6. Patents and prior art: verified scope

| Publication / primary source | Verified content | Implication |
|---|---|---|
| US7769236B2, Fiala | Claims address markers with two-level codes; independent method claims include edges/polygons/homography/binary decoding/checksums. Google lists Active and adjusted expiry 2029-05-03 | Neither “all border IDs are prohibited” nor “L corners are unrelated” follows. Specific claim mapping is needed. **Aggregator status, not official legal verification.** [S19] |
| US5726435A, original QR patent | Binary matrix and three or more position-detection symbols; Google lists Expired–Lifetime | Expiry of one early QR patent does not establish clearance for other reading methods/improvements. [S20] |
| DENSO official Japanese website | Explicit non-exercise of patent 2938338 for standardized QR | Relevant to QR use, not a blanket license for custom border codes. [S21] |
| Dynamicland Framecodes | Public border-ID precedent from 2016 | Important prior-art material; **the page does not establish whether patents were obtained.** [S1] |
| Digimarc official website | Watermark/identification technology and patent portfolio | Invisible coding is an existing technical area; specific claims and product rights unverified. [S18] |

Patent assessment depends on **jurisdiction, family, claims, current status and implementation**. General search was unavailable and the Google search API returned 429, so this was a limited rereading of known publications. Expiry dates were checked only on an aggregator; fees, prosecution history and scope were not officially verified through USPTO/J-PlatPat. No freedom-to-operate or “no patent issues” claim is made.

## 7. Uncertainties and open issues

- Actual minimum distance of the current 30 color codes, optimal palette, printed-sheet minimum thickness and Quest/Pixel acquisition/processing sizes require device evaluation outside this review.
- Nearby L-corner groups, sheet association, orientation and occluded-corner recovery may be weaknesses. Robust IDs cannot compensate for incorrect paper geometry.
- CALTag and Pi-Tag relevance was confirmed, but their original full papers were not obtained here; no peer-reviewed performance figures from those papers are quoted.
- “More robust” or “a million IDs” describes the authors' conditions/designs, not the custom thin-line system or Quest performance.
- Watermarks offer enormous ID spaces but have separate imaging-area, inference and printing constraints. No universal winner for visibility, capacity and ten-target robustness was established.

## 8. Research log and confidence

| Stage | Action | Result |
|---|---|---|
| 0 Existing work | Memory search and prior paper-ID-method / marker-design reports | Memory handler unregistered; started from existing primary sources and boundaries, without repeating the broad survey |
| 1 Closest examples | Retrieved Framecodes, Tiny dotframes and Flexible Layouts | Confirmed border IDs, size/resolution and arbitrary-layout conditions |
| 2 Counterevidence | Read ChromaTag distance, angle and 70 px evaluation | Rejected the claim that color is always stronger |
| 3 Extensions | CALTag generator, Pi-Tag DOI, TopoTag, StegaStamp paper/code and Digimarc | Organized CRC/rotation distance, unavailable-paper limits and watermark alternatives |
| 4 Mathematics | q^n, distances, one-error sphere packing and pixel conversion | Distinguished theoretical/practical capacity and mm/camera pixels |
| 5 Patents | Fiala/QR publications and listed status; DENSO primary source | Limited review; no guarantee of legal status or permitted implementation |
| 6 Verification | Source reachability, retrieved text, bibliography and claims | 21 source records in English/Japanese; compared methods/limits, without claiming exhaustive coverage or saturation |

Confidence: **High** = at least three independent lines support the principle (small-feature pixel limitations). **Medium** = one or two authoritative primary sources (method, capacity, specification). **Proposal** = project-specific design reasoning. **Unverified** = device performance or official patent status. A paper and its authors' repository are not independent demonstrations.

## Sources (checked 2026-10-09)

Sources include original papers, official implementations/archives, commercial primary sources and patent publications. Previously verified full texts for S2, the original S7 paper and S9 are reused; the others were retrieved directly in this review. Sources are English and Japanese. This does not mean 21 independent experiments.

- **S1** [Dynamicland Framecodes, 2016](https://dynamicland.org/archive/2016/Framecodes), Official archive text.
- **S2** [Dynamicland Dotframes, 2017](https://dynamicland.org/archive/2017/Dotframes), Primary source verified in a prior report.
- **S3** [Dynamicland Tiny dotframes, 2022](https://dynamicland.org/archive/2022/Tiny_dotframes), Official archive text.
- **S4** [Krogius et al., Flexible Layouts for Fiducial Tags, IROS 2019](https://april.eecs.umich.edu/media/pdfs/krogius2019iros.pdf), Full original paper, particularly §IIIA/IIID/IV.
- **S5** [DeGol et al., ChromaTag, ICCV 2017](https://openaccess.thecvf.com/content_ICCV_2017/papers/DeGol_ChromaTag_A_Colored_ICCV_2017_paper.pdf), Original paper, §5/6.
- **S6** [ChromaTag public implementation](https://github.com/CogChameleon/ChromaTag), README/calibration issues verified in a prior report.
- **S7** [Olson, AprilTag, 2011](https://april.eecs.umich.edu/media/pdfs/olson2011tags.pdf) / [tag36h11 generator](https://github.com/AprilRobotics/apriltag/blob/master/tag36h11.c), 36 bits, distance 11 and 587 codes rechecked in source.
- **S8** [OpenCV ArUco official tutorial source](https://github.com/opencv/opencv/blob/4.x/doc/tutorials/objdetect/aruco_detection/aruco_detection.markdown), Dictionary capacity/distance, corners and pose.
- **S9** [STag: A Stable Fiducial Marker System](https://arxiv.org/abs/1707.06292), Reuses full-text verification from the earlier review; long-distance limits of thin features.
- **S10** [ZXing Code128Reader](https://github.com/zxing/zxing/blob/master/core/src/main/java/com/google/zxing/oned/Code128Reader.java), Width sequences and checksum.
- **S11** [CALTag public implementation](https://github.com/brada/caltag), README, generation/detection I/O and maintenance limits.
- **S12** [CALTag generate_pattern.py](https://github.com/brada/caltag/blob/master/GeneratePattern/generate_pattern.py), CRC, rotation, distance and bit-count implementation.
- **S13** [TopoTag, arXiv:1908.01450](https://arxiv.org/abs/1908.01450), Original abstract, DOI 10.1109/TVCG.2020.2988466.
- **S14** [TopoTag library](https://github.com/herohuyongtao/topotag), Research-use/Win32 scope verified in the earlier report.
- **S15** [Pi-Tag, DOI 10.1007/s00138-012-0469-6](https://doi.org/10.1007/s00138-012-0469-6), Crossref metadata matches S5 references; full text not obtained.
- **S16** [Tancik et al., StegaStamp, CVPR 2020](https://openaccess.thecvf.com/content_CVPR_2020/papers/Tancik_StegaStamp_Invisible_Hyperlinks_in_Physical_Photographs_CVPR_2020_paper.pdf), Original full paper, §4/5.
- **S17** [StegaStamp public implementation](https://github.com/tancik/StegaStamp), 100 bits → 56 after ECC; recommended 1920×1080 video, legacy TensorFlow and detector-training limitations.
- **S18** [Digimarc Technology Overview](https://www.digimarc.com/technology-overview), Official technology/digital identifier/watermark/SDK description; marketing performance claims are not independent validation.
- **S19** [US7769236B2](https://patents.google.com/patent/US7769236B2/en), Publication text, claims and listed status.
- **S20** [US5726435A](https://patents.google.com/patent/US5726435A/en), Original QR patent publication and listed status.
- **S21** [DENSO QR standardization and non-exercise of rights (Japanese source)](https://www.qrcode.com/about/standards.html), Official Japanese primary source.

Previously published report: [Comparison of existing marker designs](https://github.com/ryosuzuki/image-tracking/blob/main/research/paper-marker-designs/README.md).
