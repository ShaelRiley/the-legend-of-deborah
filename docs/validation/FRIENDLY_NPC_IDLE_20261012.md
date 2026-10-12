# Living unarmed friendly NPCs — 12 October 2026

Parent main: `b839ee68e37850ab05764358e0fb903c8260e4dd`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 05 LOD-NPC-IDLE-001 → 07 LOD-NPC-IDLE-TUNING-001.
The user requested the animation correction and consultation with the imported
writers' room. The three paired passes and Quinn/Ned assembly are retained in
`docs/lore/room/20261012_idle.md`.

## Implementation

The Hermit and equipment-quiz Game Master now use `models/player/monk.mdl`.
Wounded Scavenger and Prison Surveyor use the matching animated
`models/player/Group03/male_07.mdl`. Their faces, silhouettes, existing colors,
entity origins, collision bounds, Use admission and service settlement remain.
The guide's dialogue portrait uses the same new model/animation resolver.

One client-only helper resolves positive-duration named unarmed sequences, never
sequence zero or a generic NPC idle/activity. Elapsed time drives the base cycle
once per rendered frame; no FrameAdvance double clock, additional entity, RNG
stream, global NPC scan or server Think service. Bones/flexes cache per entity,
model, role and version. Face/upper-body motion is capped at 20Hz (10Hz with
Reduced Effects) within 1024 units, or in the visible portrait. The drawn base
idle continues outside that range. Role/model/refresh changes clear applicable
previous offsets, unsupported optional bones/flexes are safe, and server/native
sequence overwrites are corrected to the resolved unarmed sequence.

The four roles have distinct breathing/gesture/face rhythms. The Hermit smiles,
nods and offers an empty palm; Game Master adds an expectant tilt; Scavenger
guards his torso without a forced smile; Surveyor has measured glances and a
restrained explanation. Independently phased blinks reopen both eyes. Quiz
suppression remains ahead of all animation/model paint. Current rescued women
retain their existing native idles; Deborah succession, the deliberately frozen
granite statue, machinery and authored giant Hector/crowbar projection are
preserved. The legacy static Hermit pose is used only by that projection.

Existing source verification now includes all eight changed NPC authorities:
66 installer sources, 62 server-observed sources, 23 client-render sources.
Hash caching and transport cadence remain unchanged.

## Evidence and limits

`FRIENDLY_NPC_IDLE_20261012/checks.json` records 15 selected production regressions
and four syntax/shell/whitespace checks. All pass. The changed Lua set has 17
files; the final fixture-only correction is parsed again. Existing SQLite
service/quiz settlement, incident lifecycle, event UI, guide lore, portrait
lifecycle, all-damsel staging, Hermit returns, succession, giant Hector resources,
performance capture/profile, population transport and repeat installer checks
pass. The new validator executes the real animation helper, event Draw and
server guide Initialize with explicit native-boundary doubles. It proves
cycling, cache/admission, blinks, distinct profiles, safe lookup, spent-quiz
suppression, the new guide model and unchanged guide hull.

Preserved fixture failures: the first quiz invocation used the plain runner
instead of its required real-SQLite bridge; the new guide-initialization double
initially lacked AddNetworkString and then scripted-entity constant inheritance.
Corrected fixtures pass without changing gameplay code. Installer/profile
fixtures also contained stale pre-existing source counts/omitted paths; these
were updated to the current watched declarations, retaining all hash and
transport assertions. Failed logs/receipts remain alongside final checks.

The GDD was updated before game edits, then read back. Existing 05/07 paragraphs
are byte-for-text intact at shifted indexes. Google rejected the larger HUMAN
insert with FAILED_PRECONDITION; a compact complete summary and exact 05/07
pointers succeeded, followed by named-style verification. No existing text was
deleted or rebuilt. Readback excerpts are retained with this checkpoint.

These checks do not prove Source mesh/bone orientation, visible hand/face
appearance, network timing, native acceptance or Steam Deck FPS. No native
Garry's Mod runtime is present here. No Workshop/VPS operation was performed.

## Native finite gate

Fully quit GMod, pull/install this main checkpoint, restart `gm_flatgrass`, then
approach the staging Hermit. Observe breathing, nods, blinks and the empty palm;
press E to observe the matching living portrait. In the three humanoid service
events, check distinct unarmed movement, planted feet, legible prompts and the
existing offers/claims; a spent Game Master remains hidden. Check Reduced
Effects and reset/rebuild, and preserve the pending stationary Steam Deck
comparison. Native acceptance precedes Workshop parity and matching VPS release.

## Native API/model basis

- [Stock monk/citizen player-model registry](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/player_manager.lua)
- [Player base idle definitions](https://github.com/robotboy655/gmod-animations/blob/master/gm_base_m.qci)
- [Model-specific sequence lookup](https://wiki.facepunch.com/gmod/Entity:LookupSequence)
- [Client bone offsets](https://wiki.facepunch.com/gmod/Entity:ManipulateBoneAngles)
- [Flex-controller bounds](https://wiki.facepunch.com/gmod/Entity:SetFlexWeight)
