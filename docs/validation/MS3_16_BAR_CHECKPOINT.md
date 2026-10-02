# MS3 — sixteen-bar source authoring checkpoint

Parent: `208a1af11c4448a054cc24e81603ed3446c0c55f`.

The author requests genuine sixteen-bar source-MIDI passages, preservation of each block's motifs, motif-led handoffs, restrained fills and rearrangement for the nine existing virtual instruments. Reference: https://www.youtube.com/watch?v=8yu502IyV0o . Full video/transcript access failed; its specific method has not been verified or implemented.

## Local candidate results — not yet a shipping build

The conversation's tested authoring package reads all 465 original MIDI stems directly and produces 157 genuine sixty-four-beat passages across the forty looping arrangements, plus eight twelve-beat victory fanfares. There are 121,621 arranged notes. Candidate catalog revision: `ms3-s16-bb8878a80d0490fb`.

Twenty-four block-specific recurring interval/rhythm fingerprints and per-passage source anchors guide selection and orchestration. Each passage preserves its complete foreground source voice, with competing Acid/Brass attacks reduced, Industrial/Strings support subordinated, bass/kick timing retained and calm hat density reduced. Same-pitch overlapping gates are shortened at their next source attack to prevent ambiguous MIDI note-offs. No new melodic onsets, pitches, time stretching or tiled two-bar extensions are introduced. Motif identification is a transparent heuristic, not a listening acceptance claim.

Thirty-nine separate one-bar percussion replacement candidates are sourced from the actual arrangements. They are not active runtime fills. The arrangement lacking a qualifying source cell is not given a fabricated bridge.

Thirteen focused local tests passed: full-source coverage, actual MIDI round-trip duration/nine parts, exact source-range lineage, protected motif/foreground retention, bass/kick preservation, same-pitch retrigger handling, polyphony/note/shard bounds, source-derived bridges, graph references, provenance, deterministic outputs, shipping-output guard and legacy curator default/long ties. The complete repository music/integration gates have NOT been run for this candidate. A partial local legacy gate could not complete because the scoped workbench snapshot lacks repository test helpers; this is not a passing full-gate result.

## Artifact location and publication status

The complete readable implementation and tests, candidate MIDI ZIP, source audit, transition map and direction report are delivered as conversation attachments. They have not been committed as runnable source to this branch; this file records their status and does not substitute for their implementation. The isolated branch contains the source-workbench workflow and this checkpoint note. Main, the active audio bank, Workshop and VPS remain unchanged.

## Required continuation

Recover the conversation's source package and review its `tools/music/remap_ms3_sixteen_bar.py`, `tools/music/render_ms3_candidate.py`, optional-note-length change in `tools/music/build_ms2.py` and `tools/test_ms3_sixteen_bar.py`. Apply them to a fresh exact main checkout, preserving intervening work, then rerun the focused tests and complete existing music/integration gates before source publication.

Do NOT copy the isolated candidate catalog over the active bank. Runtime admission permits only 8/12-beat clips; the shipping renderer/tests pin old counts; sample-clock playback retains an original plus a two-period looping buffer. One sixty-four-beat clip nearly exhausts the 32 MiB PCM allowance by itself, preventing safe successor or second-floor preparation. Completion requires bounded long-buffer transport, encoded-file admission, one-pass long-form scheduling, full pinned-Surge regeneration, source/audio/runtime parity, conditional bridge behavior, measured long-form joins and native GMod/Steam Deck listening. Full guide review remains open. Preserve the current sample-clock continuity repair, native fallback, permission/options behavior and local acceptance → Workshop → VPS release sequence.
