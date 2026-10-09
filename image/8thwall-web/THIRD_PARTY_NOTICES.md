# Third-party attribution

The prepared SVG contour and graph-axis method in `scripts/prepare-math-figures.mjs` adapts `src/Figures.js` from [ucalgary-ilab/augmented-math](https://github.com/ucalgary-ilab/augmented-math), commit `9ebf72a8ccb4844707bb87be34b31f201cbbcf00`.

The following license covers the adapted author code. Textbook images, paper crops and source artwork retain their own upstream provenance and copyright.

```text
MIT License

Copyright (c) 2023 Ryo Suzuki

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## MediaPipe

The bundled browser worker uses `@mediapipe/tasks-vision` 1.1.0 by the MediaPipe Authors, licensed under Apache-2.0. Its license is included at `public/pose/LICENSE.apache-2.0.txt`; WASM files are copied from that pinned package. The separate Lite model URL and SHA-256 are retained in `public/pose/provenance.json`. Official sample image/video inputs remain local test evidence and are not distributed as app inputs. The moving video includes upstream visualization overlays; all exports label it as a composite fixture.
