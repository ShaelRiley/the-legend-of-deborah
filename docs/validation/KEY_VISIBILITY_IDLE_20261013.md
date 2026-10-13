# Jail Key visibility and Hermit portrait API — 13 October 2026

Parent main: `4cd2232a99d3a996f67d0ba7b47df4eb5cc03ec2`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 05 LOD-OBJ-001 / LOD-NPC-IDLE-001 → 07
LOD-NPC-IDLE-TUNING-001 / LOD-TUNE-002; the current explicit author request
governs the new key presentation and pedestal.

## Changes

The Jail Key's tiny placeholder-model bounds did not cover its custom drawing.
It also used a thin horizontal display and a yaw-only label. The client now sets
complete bounds, recovers them on transmission resume and Lua refresh, and
explicitly separates opaque geometry from translucent accents with
RENDERGROUP_BOTH. The upright eight-unit-thick key has a bow, shaft and teeth;
the key and text face the viewer in pitch and yaw, including elevated/below views.
Both materials obey scene depth, so walls still occlude the objective.

One fixed 40×40×28-unit plinth belongs to the existing key entity. Its real
SOLID_BBOX ends at the plinth top; the floating key and label have no collision.
The deck remains at the original key point minus KeycardHeight (40).
Deep blue-violet (48/32/112), ivory (255/248/222), dark trim (18/20/28) and
gold (255/222/104) provide complementary hue and light/dark contrast.
All four sides have gold accents; text and silhouette avoid color-only identity.
The low/narrow hull is below a conservative ordinary 200-impulse/600-gravity
jump apex, with >5 units of vertical budget. This calculation is not native
jump certification. Reduced Effects suppresses bob/pulse. The 14 cached solid
parts add no actors, movable physics objects, lights, RNG or network service.

Original boss drop position, collection point/radius/cadence, nearest-Hero-hull
touch, active/alive admission, boss receipt and progression remain. Collection,
reset and existing objective cleanup retire the same entity and its pedestal.

The portrait error is reproduced without a fabricated client-model method.
SetAutomaticFrameAdvance is a Lua convenience method of scripted base_anim;
a DModelPanel ClientsideModel does not inherit it. The helper now writes the
same AutomaticFrameAdvance property directly, retaining zero playback rate and
the elapsed-time SetCycle clock. The version bump invalidates old cosmetic caches.
The real Damsels.LayoutEntity → FriendlyIdle path is tested with the native
client-model API boundary. All four unarmed NPC roles/caches/cadences remain.

Installer/source observations now include all three Jail Key authorities:
81 installed sources, 77 server-observed and 31 client-render sources.
Capture/profile/transport fixtures retain exact hashes and bounded cadence.
The inherited B28 fixture copied only 48 source declarations; it now reads the
production declaration with an explicit 77-source review assertion and retains
missing/mixed-mount, cache, shutdown and gameplay-isolation checks.

## Evidence and limits

`KEY_VISIBILITY_IDLE_20261013/checks.json` records 36 passing executions / 35
distinct commands, with 905 Lua files parsed. The external focused gate used the
canonical integration matrix's existing checks. The initial plain-Lua map
integration invocation failed because it requires the real-SQLite runner;
the correct existing runner passes 12 full builds / 35 reserved floor paths.
The initial failure and corrected log are retained. All 2,774 tested source files
were verified unchanged after the recheck, before evidence/coordination additions.

The key validator executes actual shared/client/server authorities over 640
view/time/source combinations, with transformed geometry, labels and beacons
inside the render bounds. It checks facing, physical bounds, opaque/translucent
separation, depth, material budget, reduced effects, distance, partial accessors,
full-update/reload recovery and real Think admission/collection. The old key
fails the bounds gate; the old idle helper reproduces the reported nil-method
error. Initial fixture mistakes are preserved, not rewritten as passes.

Relevant boss/key, Hector/finale, guide lore, portrait lifecycle, NPC/service,
staging/succession, native-resource, floor-map, geometry, performance/source and
installer regressions pass. Source doubles cannot prove visible Source geometry,
native collision, actual model/flex appearance, co-op timing or Steam Deck FPS.

The attempted broader 321-suite run was stopped after 144 completed cases:
132 passed, 12 failed. It is incomplete and is not a green full matrix.
Six failures shared the inherited B28 source fixture, repaired here; its relevant
dependents pass in the focused gate. Two unrelated failures also reproduce on
unchanged parent main: old quiz-model expectation in test_event_quiz_generation
line 164 and old ApplyHermitPose expectation in test_minigame_ui line 106.
Four unrelated campaign-coverage cases reached the imposed 180-second timeout.
All failures/partial receipts are retained. Only the B28 fixture changed near
that broad run's termination; production source did not change during it.

Google rejected both the scoped 05/07/01 amendment and the smaller 00 pointer
with FAILED_PRECONDITION. No live GDD synchronization is claimed.
The exact proposed design/tuning and rejection receipts are retained as
gdd_design.json, gdd_rejected_write.json and gdd_rejected_entry_write.json.

## Native finite gate

Fully quit GMod, pull/install main and restart gm_flatgrass. Open Hermit dialogue
and observe the living unarmed portrait without an error. After the boss, approach
and orbit the Jail Key, including an elevated view: observe the physical colored
plinth, recognizable upright key and legible label without disappearance.
Jump onto/over the low plinth and collect normally. Native appearance/jump
acceptance and the existing ≥40 FPS Steam Deck gate remain pending.
No Workshop publication or VPS operation occurred.

## Primary API basis

- [Scripted base_anim setter/property](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/entities/entities/base_anim.lua)
- [Entity render bounds](https://wiki.facepunch.com/gmod/Entity:SetRenderBounds)
- [Opaque/translucent render groups](https://wiki.facepunch.com/gmod/Enums/RENDERGROUP)
- [Solid BBOX collision bounds](https://wiki.facepunch.com/gmod/Entity:SetCollisionBounds)
