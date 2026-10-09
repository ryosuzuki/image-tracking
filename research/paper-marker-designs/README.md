# Paper marker designs beyond ArUco

Research review, 2026-10-09. Scope: a readable paper ID plus reliable paper registration, without an ArUco-style visual appearance. This is a source-based design survey, **not a detector benchmark or an implementation of the alternatives**.

## Executive summary

1. **Distributed colored corner codes are the closest existing match.** Programmable Space explicitly documents seven colored dots at each paper corner, a paper ID recoverable from one corner, and three or four corners needed for size/orientation. It is a community implementation inspired by Dynamicland, not documentation of all current official Realtalk internals. **Confidence: Medium**, direct implementation documentation. [S1][S2]
2. **ID and geometry can be separate subsystems.** A small ID symbol plus known corner anchors is a viable engineering proposal. Four *ordered* corner correspondences yield a planar projective mapping; four identical symmetric L shapes alone leave orientation and paper association ambiguous. **Confidence: Medium**, geometric derivation consistent with homography-based marker systems; the proposed hybrid is not tested here. [S8][S9]
3. **Circular or organic tags offer genuinely different looks**, especially RUNETag, reacTIVision amoeba/yamaarashi, and TopoTag. Their outputs and constraints differ: center/rotation is not automatically a calibrated 3D pose or four paper corners. **Confidence: Medium**, primary documentation. [S3][S4][S5][S6][S7]
4. **No evidence establishes Dynamicland-style dots or a replacement palette as universally most reliable.** Dot size, viewing angle, print, illumination, occlusion and decoding matter. STag's related-work analysis specifically warns about small dot features at long distances and acute angles. **Confidence: Medium**, authoritative paper and implementation limitations, not a measured result on the home setup. [S8][S10][S11]

## What the application actually needs

Keep three outputs separate:

- `paper_id`: which paper/content instance this is;
- `paper_quad`: ordered image-space coordinates of the four paper corners;
- optional `paper_pose`: calibrated 3D position/orientation, with known physical dimensions.

These are not interchangeable. A fiducial can identify itself without locating the whole paper. Once a marker-to-paper transform and enough geometric constraints are known, the paper corners can be *computed*, not necessarily directly detected. A 2D center and rotation from a tabletop tracker is insufficient for an arbitrary perspective view. Planar homography estimation requires four independent ordered point correspondences; a three-corner dot pattern may still provide more than three correspondences because every cluster contains several points. [S1][S3][S8][S9]

For a sheet that bends, a single rigid planar mapping cannot describe the entire surface exactly. This review assumes flat paper and a known marker layout. [S8][S9]

## Verified alternatives and authentic visual references

The links under **Actual design** point to original source illustrations, printable assets, or author figures. They are not AI-generated examples and are not blanket permission to redistribute or modify the assets.

| System | Appearance / ID | Geometry available | Fit for paper / limitations | Actual design |
|---|---|---|---|---|
| Programmable Space, Dynamicland-inspired | RGB/black seven-dot corner codes; each corner identifies the paper | Distributed paper geometry from 3–4 corners | Closest fit; open center; occlusion/lighting issues explicitly noted | [Source photo](https://raw.githubusercontent.com/jhaip/programmable-space/master/src/files/test-paper-dots/1.jpg), [sensing diagram](https://raw.githubusercontent.com/jhaip/programmable-space/master/docs/paper-dot-sensing.png) [S1] |
| reacTIVision amoeba | Organic black/white topology; default 216-symbol set | ID, image position and rotation through TUIO | Attractive organic look; principally tabletop tracking, not automatically full paper perspective | [Original printable set](https://raw.githubusercontent.com/mkalten/reacTIVision/master/symbols/amoeba/default.pdf) [S3][S4] |
| reacTIVision yamaarashi | Circular segmented ring plus central motif; README states 65,535 additional symbols | Same framework's fiducial tracking outputs | Compact alternative; requires current 1.6 implementation support, not the older website release | [Original printable set](https://raw.githubusercontent.com/mkalten/reacTIVision/master/symbols/yamaarashi/yamaarashi.pdf) [S3] |
| RUNETag | Coded circular dot layers; free center | ID and calibrated pose from dot correspondences | Strong aesthetic match, interior left for content; fine features need enough pixels | [Source sample](https://raw.githubusercontent.com/mziccard/RuneTagDrawer/master/runeTags/R43-5-print.bmp), [author project](https://www.dsi.unive.it/~bergamasco/runetag/) [S5][S6][S8] |
| WhyCon | Plain black ring with white center | Efficient circle localization; calibrated position | Plain ring has no unique printed identity and no visible in-plane heading. Do not confuse tracked continuity with encoded ID | [Original ring](https://raw.githubusercontent.com/lrse/whycon/master/patterns/circle.pdf) [S7][S12] |
| WhyCode extension | Ring with necklace-code identity | Adds encoded ID to WhyCon-family localization | Better identity fit than plain WhyCon; current generator link in README did not resolve during this review, so print-ready generation remains unverified | [Implementation and instructions](https://github.com/jiriUlr/whycon-ros) [S13] |
| TopoTag | Solid dots and hollow dots; topological organization, customizable shapes | ID and single-image calibrated geometric pose | A promising monochrome dot option; preserving topology is mandatory. Released library is research-only, Win32, not a ready WebXR port | [Actual source photograph](https://raw.githubusercontent.com/herohuyongtao/topotag/master/test/data/TopoTag_3x3_circle.png), [author teaser](https://herohuyongtao.github.io/research/publications/topo-tag/teaser.png) [S9][S14] |
| STag | Square outside, circle and organic binary pattern inside | Homography from square, refinement from circle, ID | Useful geometry/identity lesson; still visually square rather than a pure dot scheme; original repository is no longer actively maintained | [Author Figure 5, PDF p.7](https://arxiv.org/pdf/1707.06292), [implementation](https://github.com/bbenligiray/stag) [S8][S15] |
| ChromaTag | Opponent-color inner code, black/white outer edges | ID and geometrical localization | Illustrates separation of fast color detection from precise grayscale localization; still a square tag, not a Dynamicland drop-in | [Actual toy-data image](https://raw.githubusercontent.com/CogChameleon/ChromaTag/master/Data/1476733468520505.jpg), [paper](https://openaccess.thecvf.com/content_ICCV_2017/papers/DeGol_ChromaTag_A_Colored_ICCV_2017_paper.pdf) [S10][S11] |
| CCTag | Concentric circles with coded ring geometry | Identified circular fiducial and precise image localization | Real alternative with printable library; known geometry or extra anchors needed for full paper registration. Preserve margins and planar support | [Original printable markers](https://github.com/alicevision/CCTag/tree/develop/markersToPrint), [implementation](https://github.com/alicevision/CCTag) [S17] |
| Natural-image target | Normal textured illustration or artwork identifies the sheet | SDK image-target registration with known size/layout | Most visually invisible option; repeated patterns, weak texture and simple line art may provide poor features. Distinct artworks required | [Official target design guidance](https://developer.vuforia.com/library/vuforia-engine/images-and-objects/image-targets/best-practices-designing-and-developing-image-based-targets/) [S16] |

## Plain L lines instead of L-shaped dot groups

**Possible, but not a drop-in replacement.** A printed L gives an intersection and two line directions, not the colored seven-dot identity. An alternative detector would threshold/segment the lines, fit them, find their intersections and associate them with a paper. ID must come from an extra motif, color/shape variation, OCR, natural-image features or another code. [S1][S8][S9]

A practical proposed design is **four restrained black L brackets plus one small identity motif**. The motif also establishes orientation; association must be checked against sheet dimensions, convexity and reprojection error. With several papers touching or overlapping, “nearest four brackets” is not a sufficient association rule. This is our proposal, not an existing verified Dynamicland detector. [S1][S8][S9]

An asymmetric bracket (one longer arm, or a single extra dot at a designated corner) can provide direction without changing the aesthetic much. This only resolves direction if the decoder explicitly uses it; decoration does not automatically add robustness. [S8][S9]

## Can the colors change without lowering accuracy?

**Yes in principle, but there is no guarantee either way.** A fixed RGB-ratio classifier tuned for red, green, blue and black will not correctly recognize arbitrary replacement colors until its thresholds or color model are changed. Paper ID codes and printing assets must change consistently with that classifier. This review does not claim the current four colors are optimal. [S1][S11]

What matters is separation in the **captured camera colors**, not only appearance on a monitor:

- Printer pigments, illumination spectrum, exposure and white balance move the observed clusters.
- A low-saturation pastel can approach the white paper; dark colors can approach black underexposure.
- Projected graphics can alter the apparent paper/marker color; test with the projector running.
- ChromaTag uses opponent colors to reject candidates, while retaining grayscale edges for precise localization; its README explicitly lists color-calibration tooling as a development task. This supports calibrated color/geometry separation, not the claim that any fashionable palette works. [S1][S10][S11]

Compare at equal dot size and layout, then measure corner recall, wrong-ID rate, jitter and recovery after occlusion under daylight, warm light, dim light and projection. Test exposure/white-balance transitions and several sheets together. Use camera samples to choose separated color clusters; reject uncertain matches rather than always forcing an ID. This is a recommended evaluation protocol, not benchmark evidence. [S1][S8][S10]

## Recommendations for this project

1. **Keep distributed corners, improve visual treatment first.** Preserve the current code and detector while testing spacing, dot size and white clearance. This is the lowest-change baseline, not guaranteed to win. [S1]
2. **Prototype L-bracket geometry + a separate small ID.** It aligns exactly with “paper ID plus four corners” and offers the cleanest page. A lightweight circular/dot code is attractive, but an orientation and multi-paper association mechanism is essential. New detector required. [S8][S9]
3. **Study RUNETag and TopoTag before inventing a ring codec.** RUNETag provides a free center; TopoTag provides a well-documented topology/geometry design. Evaluate pixel budget and licensing before porting. [S5][S9][S14]
4. **Try amoeba/yamaarashi when visual character matters more than tiny corner footprints.** They are real printable designs and have a maintained cross-platform framework. Add geometric anchors or a known-layout perspective solver if full paper quadrilaterals are required. [S3][S4]
5. **Use natural-image tracking only when the paper already contains unique, feature-rich artwork.** Avoid treating generic blank or repetitive worksheets as equally good targets. [S16]

## Conflicts and uncertainty

- reacTIVision's older website describes 1.5.1, while its current GitHub README describes 1.6 and yamaarashi. Use the matching code/version rather than assuming the older download supports the new symbols. [S3][S4]
- WhyCon repositories differ in maintenance state and features. The plain ring source is not a unique-ID code; WhyCode is the extension. The WhyCode generator link returned unavailable in this session. [S7][S12][S13]
- TopoTag's performance superiority is an **author result on their dataset**, not verified on this project's camera or against the local dot detector. Its published library is research-only. [S9][S14]
- RUNETag's robustness to occlusion and STag's warning about fine dots are not contradictory: redundancy can help partial occlusion while small features still suffer resolution/blur limitations. [S5][S8]
- Pi-Tag and CALTag were considered but not promoted to the illustrated shortlist: no independently verified original asset/capability chain was completed in this review. Do not infer they are invalid methods.

## Open questions

- Which camera resolution, paper size and working distance must the design support?
- Is the camera overhead and fixed, or hand-held with strong perspective change?
- Must three corners suffice when a hand covers the fourth, and for how long?
- What is the required number of unique papers versus simultaneously visible papers?
- Can the printer/projector maintain palette separation under the actual room lighting?
- Does a full Web implementation matter more than visual aesthetics or pose stability?

## Research log

| Round | Queries / source strategy | Findings / stopping scope |
|---|---|---|
| 0 | Workspace skill review and prior-memory search | Memory tool unavailable; did not treat it as evidence. Read deep-research, survey and Git workflows. |
| 1 | Dynamicland dots; TopoTag/Pi-Tag/ChromaTag; WhyCon/WhyCode/reacTIVision; RUNE/Chilitags/CALTag | General search frontends challenged/blocked; switched to primary project sites, GitHub metadata and direct papers. |
| 2 | Primary repositories, code README, printable symbols, author project pages | Verified identity versus geometry; excluded unrelated `whycode` editor repository. |
| 3 | STag, TopoTag, ChromaTag and WhyCon PDF acquisition and targeted reading; RUNETag author documentation | Cross-checked pose constraints, fine-dot limits, palette and licensing; inspected authentic assets. |
| 4 | L-bracket hybrid and changed-color failure modes; version/maintenance differences | Produced bounded design review, not a claim of exhaustive literature saturation or measured reliability. |

## Sources

Sources are grouped by evidence identity: a paper and its repository are not independent replication.

- **S1 — community implementation:** [Jacob Haip, Programmable Space](https://github.com/jhaip/programmable-space), physical-object documentation and authentic paper photograph.
- **S2 — official context:** [Dynamicland](https://dynamicland.org/). Context and official archive, not a specification of the community detector.
- **S3 — primary implementation:** [reacTIVision 1.6 README and symbols](https://github.com/mkalten/reacTIVision).
- **S4 — official project website:** [reacTIVision](https://reactivision.sourceforge.net/), historical release/docs.
- **S5 — author research project:** [RUNETag](https://www.dsi.unive.it/~bergamasco/runetag/), design and pose description; code bundle retrieved.
- **S6 — community generator:** [RuneTagDrawer](https://github.com/mziccard/RuneTagDrawer), authentic stored bitmap samples, not a new detector.
- **S7 — primary implementation:** [WhyCon](https://github.com/lrse/whycon), capabilities and printable ring.
- **S8 — academic paper:** [Benligiray et al., STag: A Stable Fiducial Marker System](https://arxiv.org/abs/1707.06292), 28-page manuscript retrieved; design, related-work and limitations inspected; Figure 5 on PDF p.7.
- **S9 — academic paper:** [Yu et al., TopoTag](https://arxiv.org/abs/1908.01450), 12-page manuscript retrieved; method and limitations inspected; flexible design and geometric pose.
- **S10 — academic paper:** [DeGol et al., ChromaTag, ICCV 2017](https://openaccess.thecvf.com/content_ICCV_2017/papers/DeGol_ChromaTag_A_Colored_ICCV_2017_paper.pdf), 10-page manuscript retrieved; abstract, color method and evaluation inspected.
- **S11 — primary implementation:** [ChromaTag](https://github.com/CogChameleon/ChromaTag), MIT license, data and calibration development status.
- **S12 — academic paper:** [Krajnik et al., A Practical Multirobot Localization System](https://raw.githubusercontent.com/wiki/gestom/WhyCon/papers/2015_JINT_whycon.pdf), 20-page draft retrieved; design and localization inspected, DOI 10.1007/s10846-014-0041-x.
- **S13 — primary implementation:** [WhyCon/WhyCode](https://github.com/jiriUlr/whycon-ros), necklace-code extension and generator instructions.
- **S14 — author implementation:** [TopoTag library](https://github.com/herohuyongtao/topotag), research-only usage terms and Win32 limitation.
- **S15 — author implementation:** [STag](https://github.com/bbenligiray/stag), maintenance/fork note and original figures.
- **S16 — official SDK documentation:** [Vuforia image-target design guidance](https://developer.vuforia.com/library/vuforia-engine/images-and-objects/image-targets/best-practices-designing-and-developing-image-based-targets/).

- **S17 — primary implementation / academic citation:** [AliceVision CCTag](https://github.com/alicevision/CCTag), original printable markers, planar-support warning and CVPR 2016 paper DOI 10.1109/CVPR.2016.67.

## Artifact rights and verification

Authentic images were downloaded and visually inspected for the private design comparison. The public repository retains source links rather than redistributing a collage with mixed or unclear rights. reacTIVision's printable amoeba and yamaarashi pages explicitly state **CC BY-NC-SA**; TopoTag's released library states **research use only**. Neither should be silently relabeled as this repository's license. [S3][S14]

No detector, original implementation folder or model was changed. This report is not evidence that any candidate has run on the home Mac Studio. The next step is an actual controlled print-and-camera benchmark, not more untested aesthetics.
