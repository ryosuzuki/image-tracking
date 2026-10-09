# Twenty things the recognized sheet could display

These are independent of the recognition design. The same physical sheet can host any registered content. Every item below is a **prospective concept**, not an implemented demo claim.

| # | Content | Spatial / dynamic behavior | Minimal build |
|---|---|---|---|
| 01 | Volcano cross-section | Lava rises through a cutaway on the paper | Simple mesh + slider + animation |
| 02 | Solar system | Planets orbit above the sheet; cards set speed | Spheres + orbital curves |
| 03 | Molecule kit | Bringing atom cards together proposes bonds | Colored spheres + rule-based connections |
| 04 | Electric circuit | Battery/resistor cards connect; current is animated | Lines + simple circuit model |
| 05 | Water cycle | Rain and evaporation traverse a miniature landscape | Height mesh + particles |
| 06 | Magnetic field | Move two magnet cards to change field lines | Dipole visualization; labeled approximation |
| 07 | Wave interference | Two source cards generate overlapping waves | Analytic surface deformation |
| 08 | Vector field | Move a source card; arrows follow direction | Instanced arrows |
| 09 | Function surface | Parameter cards alter a plotted 3D function | Grid mesh + parameter mapping |
| 10 | Data terrain | Chart bars/terrain grow from printed data axes | Small authored dataset + bars |
| 11 | Anatomical layers | Reveal successive layers of an organ model | Licensed meshes + layer toggle |
| 12 | Mechanical assembly | Parts hover in an exploded view, then assemble | Primitives + sequence animation |
| 13 | Miniature architecture | A building rises from its footprint; show floors | Procedural walls + floor slider |
| 14 | Ecosystem | Species cards alter a small population simulation | Simple agents + visible assumptions |
| 15 | Reaction sandbox | Pair reagent cards to reveal approved educational reactions | Curated lookup + particles |
| 16 | Music sequencer | Card location controls timing; adjacency composes a phrase | Audio clock + quantized card state |
| 17 | Story diorama | Character/event cards create miniature scenes | Authored assets + state machine |
| 18 | Instruction replay | A small ghost demonstrates the next assembly step | Recorded/author-built pose sequence |
| 19 | Live system dashboard | A sheet hosts a changing graph, with data-age indicator | Local test feed + chart |
| 20 | Agent workspace | Plan, evidence and artifact cards connect; progress changes over time | Structured local state + explicit links |

## First three demos

1. **Volcano:** single-sheet anchor accuracy, a real 3D object and a readable animation. Add a small calibration cube first to isolate shader/pose failures from content complexity.
2. **Molecule kit:** three simultaneous physical identities and deterministic relationships. Clearly distinguish physical sheet motion from an inferred chemical rule.
3. **Wave interference:** moving two sheets changes a continuous simulation; demonstrates that the system is dynamic, not just revealing a pre-recorded model.

Keep geometry attached to the paper's plane, with height in meters and uncluttered labels. Make interaction available through controller/ray first; hand interaction is a separate acceptance lane. Content cannot count as accepted until materials render correctly in both eyes, world alignment is observed, and loss/reacquisition behavior is visible in the actual device recording.

Prefer local deterministic content for this acceptance pass. Live agent generation, network fetches and model import can be added after tracking/rendering is stable; they must not block the basic demonstration.
