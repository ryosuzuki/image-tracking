# Printable Kit v1

Six authored/public-safe target sheets in both A4 and US Letter: ArUco7/8, colored dots7/8, an asymmetric natural-image exercise, and a blank feature-poor negative control. [Open the kit browser](index.html). PDFs are generated separately as release assets, not committed binaries.

## Size and compatibility

- **ArUco:** OpenCV `DICT_4X4_50`, IDs7/8, one-cell black border. The outer black square is **120 mm**; 10 mm white quiet zone gives a **140 mm target field**.
- **Dots:** exact existing `dot-aruco-20261009-v1` codewords. Adjacent corner-center distance is **120 mm**, dot spacing **8 mm**, radius **2.4 mm**. Target field is **140 mm**. This is not a 120 mm paper/card edge.
- Existing marker modes recognize these IDs by source contract. Current app lessons are selected manually; automatic ID-to-molecule/card/animation mapping is **proposed**, not implemented by these sheets.
- Native marker source and browser marker contracts are checked equal. This kit does not establish fresh native-device, stereo alignment, printed-paper or interaction acceptance.
- Natural-image01 is newly authored geometry, **not** the existing Vuforia20cm target and **not** registered in any native app/database. It is an optional training/prototyping exercise, not a drop-in demo.
- Blank negative control must be evaluated on the cropped **white target field only**. Whole-page labels and ruler contain features and can mislead natural-feature tests.

## Print and measure

Choose the matching A4/Letter PDF. Print at **100% / actual size**, no fit-to-page, no browser headers/footers. Use color for dots. Measure the **100 mm ruler** and the marker metric extent before interpreting pose/scale. No physical print job was executed for this delivery.

For a single page, open its SVG or use the kit browser's print-selected-page button. Ensure browser paper format matches the selected sheet. Browser/driver settings can override CSS physical units; printed dimensions still need measurement. Do not print the PNG alone and assume its pixels imply physical size.

Use matte paper in baseline tests; record printer settings, lighting, distance and failures. Show only one intended target first. Keep the entire target field visible; use distinct IDs for distinct cards. Detection is not proof of binocular world registration.

## Reproduce

Requires Python3, Pillow and ReportLab. Run from any directory:

```sh
python3 -m venv /tmp/mr-kit-env
/tmp/mr-kit-env/bin/pip install Pillow reportlab
/tmp/mr-kit-env/bin/python docs/lecture-hub/print-kit/generate.py --pdf-output /tmp/mr-kit-pdfs
```

`generate.py` reads existing repository-authored marker artwork/contract and creates all local SVG/PNG source pages, `manifest.json`, and two six-page PDFs in the explicitly supplied output directory. It fails closed on changed metric dimensions. PDFs use deterministic ReportLab metadata. Keep durable output under the established Storage workflow location after the storage guard; do not default binary PDFs into public Git.

Independent verification requires OpenCV-contrib and PyMuPDF:

```sh
/tmp/mr-kit-env/bin/pip install opencv-contrib-python-headless pymupdf
/tmp/mr-kit-env/bin/python docs/lecture-hub/print-kit/verify.py /tmp/mr-kit-pdfs
```

Checks compare ArUco bits/IDs against OpenCV's independent dictionary, detect dots with the existing browser tracker in both source PNGs and actual PDF raster crops, reject the blank field, and measure all12 PDF page boxes / exact100mm ruler geometry. These are file/software checks, not optical camera or physical printer accuracy.

Original marker contracts and source-artwork notices remain authoritative. New page layout and asymmetric/negative exercises are authored for this repository; no Pokémon, publisher worksheet or private room pixels are included.
