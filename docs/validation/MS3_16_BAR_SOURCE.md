# MS3 — source-derived sixteen-bar arrangement checkpoint

## Author direction

Replace repeated short snippets with real sixteen-bar passages from the original MIDIs. Keep each block's recognizable motifs as transition glue; use restrained fills when thematic continuity is weak. Rearrange for the existing nine virtual instruments. The supplied reference is https://www.youtube.com/watch?v=8yu502IyV0o . Full video/transcript access failed; this checkpoint must not be represented as an implementation of that guide's particular method.

## Implemented authoring scope

`tools/music/remap_ms3_sixteen_bar.py` reads all 465 original stems directly. It does not concatenate old rendered snippets. The default candidate contains 157 complete 64-beat passages across 40 looping arrangements, plus eight twelve-beat victory one-shots. Every ordinary passage has source material in all four four-bar sections and is not a repeated two-bar tile. The candidate contains 121,621 arranged notes at 130 BPM. Source MIDIs contain no meter events; the inherited 4/4 score grid is explicit, not falsely attributed to source metadata.

Recurring five-onset interval/rhythm cells are ranked for block specificity and cross-role occurrence. Twenty-four top block fingerprints and a local recurring-cell anchor for each ordinary passage are recorded. This is a transparent selection heuristic, not a claim of perceptual motif recognition. An anchored foreground voice retains its complete source part throughout the sixteen bars. Competing Acid/Brass attacks are reduced, Industrial support is subordinated, Strings can sustain beneath the foreground, bass/kick timing is preserved, and calm hats are thinned. Nine MIDI parts are always exported; a sparse source does not manufacture notes merely to make every voice sound constantly.

The canonical curator's new optional maximum-note-length argument lets the candidate retain long authored sustains. Its default remains eight beats, preserving the shipped rebuild. Same-pitch overlapping gates are shortened at the next onset to eliminate ambiguous note-offs. No melodic onsets or pitches are added by the new arranger.

Successor and cross-role handoff rankings combine motif overlap, harmonic profile, root motion, energy and contiguous source adjacency. Thirty-nine separately exported one-bar percussion bridge candidates come from actual same-arrangement cells. They are intended to replace tom/snare/hat slots while preserving the kick/bass foundation, never to stack another kit or force an unready successor. They are not active runtime fills. The one arrangement without a qualifying source cell is left without a fabricated bridge.

## Reproduce

```bash
python3 tools/test_ms3_sixteen_bar.py
python3 tools/music/remap_ms3_sixteen_bar.py --output build/ms3-sixteen-bar
```

Outputs: portable `MS3_16_BAR_MIDI_CANDIDATES.zip`, a source/edit audit, block motifs, graph/handoff mappings, a human-readable direction report, and a non-shipping candidate catalog. The ZIP uses fixed archive metadata and is byte-deterministic. All ordinary MIDI exports have exactly 64 beats and nine named instrument tracks plus the conductor; fanfares and bridge cells are explicitly separate exceptions.

An isolated optional renderer reuses the pinned Surge core and the existing project-owned nine-voice patch bank:

```bash
python3 tools/music/surge/prepare.py --source /tmp/lod-surge-source --build /tmp/lod-surge-build --jobs 4
python3 tools/music/render_ms3_candidate.py --candidate build/ms3-sixteen-bar --surge-module /tmp/lod-surge-build/src/surge-python --jobs 2
```

`--sample` renders eight complete Chill passages rather than the full candidate bank. Every rendered file passes the canonical actual Vorbis decode, duration, finite-sample, silence and peak checks. The renderer writes only under `build/`; it does not replace active audio or the shipping manifest. Rendering is an optional additional gate, not established merely by the source tests.

## Explicit remaining scope — not a game audio release

The active shipping audio remains the sample-clock bank on parent `208a1af11c4448a054cc24e81603ed3446c0c55f`. No Workshop or VPS deployment is included.

Do not copy the candidate catalog onto it. Runtime catalog admission currently accepts only 8/12-beat clips; the shipping renderer and asset tests pin the old counts; the Web Audio transport stores an original plus a two-period overlap-add loop. A 64-beat resident clip alone nearly exhausts its 32 MiB PCM allowance, preventing safe preparation of a successor or a second floor lane. Removing the admission guard or increasing clip length alone would risk another silence regression.

Completion requires a tested bounded long-buffer transport and encoded-file admission, one-pass ordinary phrase scheduling rather than forced short-phrase repeats, complete source/audio/runtime hash parity, deliberate conditional bridge behavior, all existing music and gameplay integration gates, measured long-form joins, and native GMod/Steam Deck listening. Full guide review also remains open. This checkpoint delivers usable, traceable source arrangements while preserving the currently working game.
