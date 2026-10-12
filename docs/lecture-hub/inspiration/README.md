# Spatial inspiration / lecture showcase

A visual companion to the separate paper library. This collection preserves 95 X references and ten video links from the complete 43-page original AR Research Showcase, adds 72 distinct saved-source posts and four historical Inspiration videos, and adapts ten historical idea themes into classroom exercises.

- 191 cards; 180 authentic source previews; 43 lecture picks.
- Eight themes; collection and text filters; source descriptions and discussion prompts.
- `Present selection` follows the current filters, with arrow-key navigation and fullscreen.
- `Watch` uses the original X video or original host embed, with an original-source fallback. No third-party videos are reuploaded.
- Concept films, creator examples, archived descriptions and proposed exercises remain distinguishable from independently evaluated research.
- The existing 49-entry paper dataset is unchanged.

## Implementation

Static GitHub Pages assets, no build step. `inspiration.json` is the public curated manifest, and `inspiration-data.js` contains its exact data for browser use without a fetch dependency. `gallery.js` implements search, filters, presentation and media lifecycle. Preview images retain creator attribution on the associated card.

## Source boundaries

Ideas (438 notes), Inspiration (663 notes) and three saved bookmark snapshots (1,915 records) were screened. Selection is topical, not an exhaustive publication of private archives. Public metadata for 157 posts was recovered; five use saved descriptions and five retain source-slide evidence only. The other course decks and the full OneDrive media library are not claimed exhausted. Full video playback and independent system accuracy are not implied by metadata or a poster.

Private provenance and exact source/hash receipts are retained under the existing Storage output hierarchy, not this public repository. No credential, correspondence, raw notebook dump or account membership ledger is included.

## Verification / delivery

Completion owner: task-agent. Integration target: origin/main. Owned paths: this directory and the parent `index.html` navigation/entry section only.

Before publication, real-browser checks covered manifest counts, all 180 image loads, showcase coverage, search, collection filtering, idea labels, presentation keyboard navigation, Escape/close, original-host sample video playback, stopping media on close, mobile overflow, and JavaScript errors. The original course video thumbnails and 166 post previews were inspected visually. The final hosted page is checked again after publication; its immutable delivery receipt lives outside this commit.
