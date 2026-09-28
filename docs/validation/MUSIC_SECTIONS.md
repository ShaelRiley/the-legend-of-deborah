# Pulse-first music validation

Gameplay/tooling commit: `9e45465` on main, parent
`67cb7dbf7343d05cd52c3f429e33322a8fc30248`. The complete identity and source
digest are in `music_sections/receipt.json`; logs and earlier attempts are in
`music_sections/evidence.zip`. This closeout adds evidence only.

The full canonical matrix completed **286/287**, including **802 Lua syntax
files**. Its one nonpass was the existing B23 campaign wandering-ecology suite
reaching its 600-second wall-clock limit after 29 campaigns, without an assertion
failure. An isolated rerun of the identical command, all 32 campaigns / 640
dungeons and all original assertions passed in **446.698 seconds**, with a
1200-second allowance. The source digest matched before/after both runs.
Thus all **287 registered suites have passing coverage on the same source**;
this is not a claim that the first matrix was 287/287. The timeout is retained.

Music-specific evidence includes 132 section/client assertions, 20 offline
classifier assertions and 26 real ingestion assertions. It covers loud drones
and isolated impacts versus recurring pulse, intro/breakdown/outro exclusion,
cue validation and authored overrides, real Vorbis decode, atomic rejection,
legacy enrichment, rise/fall classification, buffer readiness, entry rotation,
quiet/pulse renewal, saturated and failed-overlap fallback, late callback
invalidation, one-shot victory and no extra block-name announcement.

Two-minute simulated active and calm runs remain inside their required cue
class and make just two initial native URL requests per track by reusing a
buffered pair. The stricter audio fixture rejects calls after native Stop.
The earlier 35/35 focused gate predates final pair reuse and lifetime hardening;
final coverage comes from the complete matrix and isolated rerun above.

Live GDD 05 `LOD-MUSIC-CUES-001` and 07 `LOD-MUSIC-CUES-IMPL` were updated and
read back, including the author's rhythmic-primacy clarification. Native tab
structure and existing date elements were preserved. Relevant readback is in
`music_sections/gdd-readback.json`. Operator documentation, player guidance and
both generated manual renderings are synchronized.

**Native acceptance remains pending.** Heuristic analysis is not musical
judgment; authored overrides and audition are available. No real hosted catalog
was available to reprocess. Cue-less assets keep their old compatibility path
until offline reimport at a new version; active/offered plans stay frozen.
Native seek precision/cost, listening quality, Steam Deck frame time/memory and
cold-network behavior were not measured. Follow `../MUSIC_SECTION_DIRECTION.md`
for the finite native gate. Streaming still defaults Off. No Workshop publication
or VPS deployment occurred.
