# Saved camera and map options

The author requests a third-person perspective checkbox plus separate map size
and opacity sliders while the Steam Deck performance pass continues. Map size
must cover 0.5–1.5 times its current size. Extend the existing non-pausing Options
page and the existing saved preference authority.

Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`. Follow normalized
06 `LOD-UI-OPTIONS-001`, 07 implementation/performance/tuning rules, and the
bounded HUMAN Options paragraphs. Five targeted author amendments are
revision-locked and exact-readback verified before dependent implementation;
the [amendment receipt](PLAYER_OPTIONS_20261007_gdd.json) preserves the exact
old/new text and revisions. The retired streamed Music controls remain removed.

| Preference | Saved client convar | Default | Range |
| --- | --- | --- | --- |
| Third-person camera | `lod_third_person` | Off | Off / On |
| Map size | `lod_map_scale` | 1.0 | 0.5–1.5× current size |
| Map opacity | `lod_map_opacity` | 1.0 | 0–1× current opacity |

These local presentation preferences apply immediately and survive sessions
and Hero changes. Preserve native weapon FOV, VR/vehicle/spectator and authored
cinematic view ownership, server gameplay, map access, Magic expenditure,
forced zero-Magic closing, topology/route caches and the accepted native wall
renderer. Reuse the existing camera's 118-unit pullback, 34-unit lift and 6-unit
trace hull; no new camera tuning is introduced. At default settings, ordinary
first-person view and the existing map appearance are retained. Map layers share
one cached window/scale transform; fitting a small window never rewrites the
requested saved scale. The Options contents scroll on small windows.

The bounded accompanying performance work removes the quadrant overlay's
per-frame rectangle records. A paired warmed headless probe compares exact
parent/candidate submissions and Lua allocation; it is not an FPS measurement.
The instruction booklet describes the new controls. Opt-in native captures
record these three preferences and independently hash the four options/map
sources. The installer manifest has 48 entries: the existing 44 plus these four.

Native camera/UI acceptance and sustained >=40 FPS remain pending. Continue
with the [finite source and native gate](../validation/PLAYER_OPTIONS_20261007.md).
