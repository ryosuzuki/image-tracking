# QR camera prototype
Camera-space 2D multi-QR ID reader using jsQR 1.4.0 (Apache-2.0), vendored locally. No OCR or page-image matching. Up to ten decode attempts per frame via rectangular masking. Nearby or overlapping codes may be hidden by masking. Real-device robustness is unmeasured. Black L marks on cards are layout examples, not tracked. IDs paper-001 to paper-010; preserve white QR quiet zones.
Open index.html over HTTPS, start camera, show targets.html on a second device. Stop releases camera tracks.
Integration target origin/main; owner agent4; owned allowlist docs/qr-camera/. Synthetic decoding does not establish real-camera accuracy.
