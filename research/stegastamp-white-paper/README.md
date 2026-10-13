# Can StegaStamp work on white paper? A renewed review

Review date: 2026-10-09 (America/Denver). The review records 26 sources: academic papers, primary websites, official implementations, developer forums and bibliographic APIs. Multiple documents from the same authors or organization are not counted as independent replications. This is a literature review; no new printing or Quest benchmark was performed.

## Summary

- **Accepting white paper as input is different from remaining unobtrusive and readable by a real camera.** StegaStamp's author explicitly notes that changes to flat colors are conspicuous and recommends retraining on similar images in response to a failed black-and-white document experiment. 🟡 Primary-source confidence: [issue 10](https://github.com/tancik/StegaStamp/issues/10).
- **The pretrained model is not the first choice for an untouched white margin.** It targets photographs, not IDs hidden in a thin top-edge line. 🟡 [Paper §4 and §5.5](https://arxiv.org/pdf/1904.05343), [official implementation](https://github.com/tancik/StegaStamp).
- **“About 900” cannot be confirmed as a deployment count.** At review time, GitHub reported 885 stars and the formal publication record in OpenAlex reported 491 citations. The former might explain the number, but the original screen was unavailable. 🟡 [GitHub API](https://api.github.com/repos/tancik/StegaStamp), [OpenAlex](https://api.openalex.org/works/https://doi.org/10.1109/CVPR42600.2020.00219).
- **TrustMark is the next comparison candidate.** Browser decoding and a printing demo exist, but they do not establish success on white margins or ten simultaneous Quest targets. 🟡 [FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md), [JS](https://github.com/adobe/trustmark/blob/main/js/README.md), [Know How](https://www.adobe.com/max/2024/sessions/project-know-how-gs3-8.html).

## 1. What the technology does

StegaStamp (CVPR 2020) feeds an image and message to a neural encoder, which makes small RGB changes across the image. A camera crop is rectified and a neural decoder recovers the bits. It is not nearest-neighbor matching against registered images, but neither does it identify completely unmodified paper. It uses 400×400 inputs and 100-bit codewords; the standard implementation allocates 56 message bits, 40 BCH bits and 4 padding bits. The 56 bits provide approximately 7.2×10^16 theoretical IDs, not that many simultaneously tracked targets. 🟡 [Paper §4 and supplement](https://arxiv.org/pdf/1904.05343), [encode_image.py](https://github.com/tancik/StegaStamp/blob/master/encode_image.py), [models](https://github.com/tancik/StegaStamp/blob/master/models.py).

The original evaluation used 100 natural ImageNet images and 18 printer/display-camera combinations, reporting mean bit accuracy of 98.7% over 1,890 captured images. That is neither “98.7% white-paper ID recognition” nor a ten-target success rate. Experimental photographs, author videos and publication records are available, but do not guarantee transfer to the current Quest setup. 🟡 [Paper §5.2](https://arxiv.org/pdf/1904.05343), [author page](https://www.matthewtancik.com/stegastamp), [CVPR](https://openaccess.thecvf.com/content_CVPR_2020/html/Tancik_StegaStamp_Invisible_Hyperlinks_in_Physical_Photographs_CVPR_2020_paper.html).

## 2. Blank paper, white margins and monochrome documents

| Target | Evidence | Assessment |
|---|---|---|
| Photographs or textured artwork | Original print-camera experiments | A substantial demonstrated method, dependent on distance and hardware |
| Monochrome documents | User reports degraded appearance and failed phone-camera decoding | No success guarantee with the pretrained model |
| Large white margins or flat colors | Author explicitly identifies visible modifications | Not an easy setting for hiding changes |
| A thin top edge only | Pretrained implementation modifies a 400×400 image | Not directly supported; redesign or training is needed |
| Black L corners plus a watermark on white paper | L corners could rectify the region | An untested design hypothesis |

Sources for the table: [paper §5.5](https://arxiv.org/pdf/1904.05343), [monochrome-document issue 10](https://github.com/tancik/StegaStamp/issues/10), [encoder](https://github.com/tancik/StegaStamp/blob/master/encode_image.py). A white-paper PNG can be supplied as input, but the output contains subtle color or intensity patterns. The method does not read an ID from a completely white region with nothing printed on it. 🟡 Implementation-grounded explanation.

Issue 10 is particularly direct: the questioner reports poor watermark appearance on monochrome documents and failure to extract it from phone photographs. Tancik recommends retraining on similar images and adjusting hyperparameters, adding **“a flat color … Any modification would be very visible.”** The paper's §5.5 also states that residuals can be perceptible in large low-frequency regions. 🟡 [Author response](https://github.com/tancik/StegaStamp/issues/10), [paper](https://arxiv.org/pdf/1904.05343). A single user report is not a statistical failure rate, but provides a concrete reason to question generalization to blank paper. [Non-natural-image issue 44](https://github.com/tancik/StegaStamp/issues/44) is supporting anecdotal evidence, not an independent evaluation. 🔴 User-report confidence.

The detector introduces a separate constraint. The official README describes detection as size-sensitive and noisy, recommends 1920×1080 video and notes that detector training code is not included. Reports that detection requires a white border concern region detection, not the ability to hide IDs in a white surface. L-corner rectification could replace part of region detection, but cannot compensate for insufficient decoding signal. 🟡/🔴 [README](https://github.com/tancik/StegaStamp), [issue 5](https://github.com/tancik/StegaStamp/issues/5), [training code](https://github.com/tancik/StegaStamp/blob/master/train.py).

## 3. Interpreting “900”: citations versus adoption

The [GitHub API](https://api.github.com/repos/tancik/StegaStamp) snapshot from 2026-10-09 showed **885 stars and 224 forks**. These measure interest and copying, not deployment in 885 products. The [formal publication DOI in OpenAlex](https://api.openalex.org/works/https://doi.org/10.1109/CVPR42600.2020.00219) showed **491 citations**, with a record update dated 2026-10-08. A [title search](https://api.openalex.org/works?search=StegaStamp&per-page=5) also returned a separate preprint record with 28 citations; without deduplicating citing papers, 491+28 should not be reported as the total. 🟡 Database values at retrieval time.

Google Scholar and Semantic Scholar cover and merge records differently, so their counts may differ. Semantic Scholar returned HTTP 429 and Google search did not return usable result text in this review. **A claim of approximately 900 Scholar citations remains unverified**, as does the site the user originally saw. The official README describes a research code release, not the total number of real deployments worldwide. 🟡 [Official README](https://github.com/tancik/StegaStamp), [OpenAlex search](https://api.openalex.org/works?search=StegaStamp&per-page=5).

## 4. Successors and the limits of practical claims

| Method | Evidence of existence | White-paper / Quest qualification |
|---|---|---|
| StegaStamp | Original paper, print-camera demo and public model | Visible changes on white regions; detector bottleneck |
| TrustMark | 100-bit watermark, BCH, Python/JS and printing demo | Ten simultaneous white-paper targets under matching conditions not measured |
| RoSteALS | Research hiding data in autoencoder latents | Not specifically a white-paper top-edge code |
| Stable Signature | Signature embedded in generated-image decoder | Different from a general-purpose blank-paper tag |
| VideoSeal | Official image/video watermarking implementation | Not proof of print-camera decoding on plain paper |

Primary comparison sources: [StegaStamp](https://arxiv.org/pdf/1904.05343), [TrustMark](https://arxiv.org/abs/2311.18297), [RoSteALS](https://arxiv.org/abs/2304.03400), [Stable Signature](https://github.com/facebookresearch/stable_signature), [VideoSeal](https://github.com/facebookresearch/videoseal). “Invisible” or “robust” in a name does not establish robustness on small, untextured paper.

**Why compare TrustMark next:** Adobe's official FAQ discusses RGB input, CMYK conversion before printing, and increasing strength from 1.0 to 1.5 to survive printing on paper, cards and some other materials. It links the Adobe MAX 2024 **Project Know How** demo. Higher strength trades off visibility; negligible visual impact on white paper is not established. 🟡 [Printing FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md), [official Know How demo](https://www.adobe.com/max/2024/sessions/project-know-how-gs3-8.html).

TrustMark converts a 100-bit raw payload to BCH-protected IDs, selecting correction strength and capacity by schema. JS decoding can use ONNX and WebGPU, but the README example uploads images; it is not a finished Quest multi-target camera application. Models are tens of MB, and reported GPU timings are from the author's environment, not Quest measurements. 🟡 [Implementation](https://github.com/adobe/trustmark), [configuration](https://github.com/adobe/trustmark/blob/main/python/CONFIG.md), [JS](https://github.com/adobe/trustmark/blob/main/js/README.md), [FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md).

⚡ **Reconciling printing support with camera failures:** the TrustMark FAQ shows a printing demo, whereas [issue 21](https://github.com/adobe/trustmark/issues/21) reports successful upload decoding but camera failure, later closing with only **“Solved”**. The resolution conditions are unstated. Success in a particular implementation and environment does not guarantee arbitrary distance, lighting, exposure or target size. 🔴 User report; 🟡 conditional official claim.

CAI's Durable Content Credentials combine metadata, watermarking and fingerprinting; TrustMark appears in the C2PA soft-binding list. This indicates operational integration, but cannot be converted into **900 deployments of StegaStamp itself** or a count of robust blank-paper reads. 🟡 [CAI](https://contentauthenticity.org/blog/durable-content-credentials), [C2PA list](https://github.com/c2pa-org/softbinding-algorithm-list), [TrustMark FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md).

## 5. Recommendations for this design

**Design judgment, not demonstrated performance:** for the current goal—freely editable white-paper content, an unobtrusive top edge and black L corners—first improve a thin, high-contrast explicit code. A faint, large-area watermark in white margins introduces separate visibility, camera-decoding and processing-cost questions. StegaStamp's large ID capacity does not remove a target's camera-pixel shortage. [Paper §5.5](https://arxiv.org/pdf/1904.05343), [author response](https://github.com/tancik/StegaStamp/issues/10), [TrustMark FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md).

**If testing, proceed in small stages:** make equal-area flat-white, text-only and photograph-containing covers. Compare StegaStamp with TrustMark at strengths 1.0 and 1.5. Progress from digital decoding to one printed sheet, one Quest sheet and ten sheets. Use L corners to rectify the same region; measure recovered bits, ECC validity, wrong IDs, appearance and speed separately. Record print size, camera-pixel area and distance. This is an experimental proposal, not work performed in this review. [StegaStamp encoder](https://github.com/tancik/StegaStamp/blob/master/encode_image.py), [TrustMark configuration](https://github.com/adobe/trustmark/blob/main/python/CONFIG.md).

**Patents and terms:** StegaStamp's official code uses the MIT license. TrustMark states that its code and downloaded models are MIT-licensed. Code licensing is not a comprehensive freedom-to-operate determination for related patents. This report reassesses white-paper suitability and does not assess new patent claim scope. [StegaStamp LICENSE](https://github.com/tancik/StegaStamp/blob/master/LICENSE), [TrustMark README](https://github.com/adobe/trustmark).

## Research log

| Round | Question / query | Method | Findings and next step |
|---|---|---|---|
| 1 | StegaStamp white blank images / citations | Existing notes; web tools → direct HTTP | Memory/web handlers unavailable; used prior report and original paper |
| 2 | Paper §5.5 / code capacity / ImageNet evaluation | Full PDF and official code | Confirmed white-region visibility and 56-bit payload |
| 3 | White documents / low frequency / camera | Issue inventory and author replies | Issue 10 supplies direct counterevidence; do not conflate with issue 5 |
| 4 | Citations versus stars / OpenAlex DOI and preprint | Public APIs | 885 stars, 491 formal citations, 28 preprint citations; Scholar unverified |
| 5 | TrustMark print blank / browser / deployment | FAQ, paper, JS, MAX, CAI and C2PA | Printing examples and product connections, but no blank-paper guarantee |
| 6 | Camera failure / subsequent methods | Issues, RoSteALS, Stable Signature and VideoSeal | User counterexamples and differences in scope |

A Japanese-language query for StegaStamp, white paper and watermarking was also attempted, but Google retrieval did not return actual results; no independent Japanese evaluation was added. This is a source-grounded suitability review, not a determination of total adoption or an exhaustive related-work corpus.

## Open Questions

- Was the “about 900” figure stars or Scholar citations? Only the original page can resolve this.
- Print-camera success rates and visibility for pretrained or retrained StegaStamp on white paper/margins.
- Visual acceptability of TrustMark strength 1.5 on white paper and Quest inference speed.
- Paper size and camera-pixel count needed to provide sufficient watermark signal for ten simultaneous targets.
- Distinguishing standards listings, research demos and actual product deployments; public sources do not provide deployment counts.

## Sources

All sources were retrieved on 2026-10-09. API values are dated snapshots and may change at the linked endpoints. Multiple code/README documents from one study are not independent validations.

| # | Source | Type |
|---|---|---|
| 1 | [StegaStamp original paper](https://arxiv.org/pdf/1904.05343) | Academic |
| 2 | [CVPR publication page](https://openaccess.thecvf.com/content_CVPR_2020/html/Tancik_StegaStamp_Invisible_Hyperlinks_in_Physical_Photographs_CVPR_2020_paper.html) | Academic |
| 3 | [Author project page](https://www.matthewtancik.com/stegastamp) | Primary website |
| 4 | [Official README](https://github.com/tancik/StegaStamp) | Implementation |
| 5 | [encode_image.py](https://github.com/tancik/StegaStamp/blob/master/encode_image.py) | Implementation |
| 6 | [models.py](https://github.com/tancik/StegaStamp/blob/master/models.py) | Implementation |
| 7 | [train.py](https://github.com/tancik/StegaStamp/blob/master/train.py) | Implementation |
| 8 | [Monochrome-document issue 10 and author reply](https://github.com/tancik/StegaStamp/issues/10) | Developer forum |
| 9 | [Non-natural-image issue 44](https://github.com/tancik/StegaStamp/issues/44) | Developer forum |
| 10 | [Detection white-border issue 5](https://github.com/tancik/StegaStamp/issues/5) | Developer forum |
| 11 | [OpenAlex formal publication record](https://api.openalex.org/works/https://doi.org/10.1109/CVPR42600.2020.00219) | Bibliographic API |
| 12 | [OpenAlex title search](https://api.openalex.org/works?search=StegaStamp&per-page=5) | Bibliographic API |
| 13 | [GitHub statistics API](https://api.github.com/repos/tancik/StegaStamp) | Implementation statistics |
| 14 | [TrustMark paper](https://arxiv.org/abs/2311.18297) | Academic |
| 15 | [TrustMark official implementation](https://github.com/adobe/trustmark) | Implementation |
| 16 | [TrustMark FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md) | Primary website |
| 17 | [TrustMark JS](https://github.com/adobe/trustmark/blob/main/js/README.md) | Implementation |
| 18 | [TrustMark configuration](https://github.com/adobe/trustmark/blob/main/python/CONFIG.md) | Implementation |
| 19 | [Project Know How](https://www.adobe.com/max/2024/sessions/project-know-how-gs3-8.html) | Primary website / demo |
| 20 | [CAI Durable Content Credentials](https://contentauthenticity.org/blog/durable-content-credentials) | Primary website |
| 21 | [C2PA soft-binding list](https://github.com/c2pa-org/softbinding-algorithm-list) | Standards implementation |
| 22 | [TrustMark camera issue 21](https://github.com/adobe/trustmark/issues/21) | Developer forum |
| 23 | [RoSteALS](https://arxiv.org/abs/2304.03400) | Academic |
| 24 | [Stable Signature](https://github.com/facebookresearch/stable_signature) | Implementation |
| 25 | [VideoSeal](https://github.com/facebookresearch/videoseal) | Implementation |
| 26 | [StegaStamp license](https://github.com/tancik/StegaStamp/blob/master/LICENSE) | Implementation |
