# Current author direction — Steam Deck performance

October 5, 2026: optimize the post-music-removal build for sustained >=40 FPS
on Steam Deck, Proton, windowed, Arch Linux Desktop mode. Reported baseline is
approximately 15 FPS, not an instrumented measurement. This implementation pass
supersedes historical sequencing, preserving game rules, population, progression,
safe arrival, authored bosses and ambient/event audio. Validated non-force pushes
to main are authorized; Workshop publication and VPS deployment remain held for
native acceptance. See [current evidence](validation/STEAM_DECK_20261005.md).

The current candidate extends the existing Reduced Effects setting with spatial
batches of the original container hulls and simpler diffuse lighting; section
hues, UVs, warning overlays and native collision remain. It skips render work for
invisible collision boxes and retains unchanged render bounds. The canonical
navigation cache retains completed sanctuary routes without evicting the existing
72 home-distance trees; mixed-source testing repaired the first checkpoint's
shared-tree regression. Exact paths, gate/event/filter invalidation, population,
combat and progression remain protected.

`lod_perf_start 180` adds bounded, opt-in rendered-frame evidence after wall
preparation/warmup, including active-play percentiles, five-second pacing windows,
configuration, source verification and resource snapshots. Source checks and
synthetic work reductions are evidence of implementation, not native FPS.
The first exact-source native capture timed out with all 1,542 walls unbatched
and zero frame samples. This is unmeasured FPS. Its population observer ran, but
the console truncated the full source list and the separate DATA file could not
be located. The repair removes the duplicate wayfinding appearance writer,
lets batches consume the canonical desired sampler, bounds preparation before
sampling, and mirrors existing population evidence automatically into the client
capture. See [native failure, repair and finite retest](validation/STEAM_DECK_20261005_NATIVE_REPAIR.md).
The next exact-source capture on main 438c3d8 measured 18.71 FPS (1,529 active
frames / 81.72 seconds; p95 113.06 ms) and the supplied video shows missing wall
surfaces. Replacement batching was ready with all 1,448 originals hidden when
sampling began. This fails visual acceptance and does not meet the 40 FPS target.
Native wall rendering is restored by default while keeping Reduced Effects and
the other optimizations. Batching is retained only behind the explicit, unsaved
`lod_wall_batches 1` test switch; native draw errors restore every original and
stop retrying. Exact native failure remains unproven; bounds/count/static tests
cannot certify rasterized visibility. See [visibility repair and evidence](validation/STEAM_DECK_20261005_WALL_VISIBILITY.md).

The author accepts native wall visibility on exact clean main 6dc145d: "Walls
look good again." The new capture verifies all seven renderer/41 population
sources, with batches disabled and zero hidden originals throughout its live
windows. It measures 13.68 active FPS / 41.80 seconds, p95 137.926 ms, on a larger
1,868-wall maze. Different generated workload prevents a controlled comparison
with the earlier 1,448-wall run. The 40 FPS target still fails.

The next source checkpoint repairs a demonstrated perpetual appearance loop:
138,048 applications without becoming idle. The sole native writer now applies
material/color/skin once per exact model and invalidation lifetime, preserving
the original appearance and <=192-model batch. Native getter acknowledgement
remains diagnostic rather than a reason to rewrite the same appearance forever.
World/palette/model-owner/mode/refresh changes reapply it. Keep the now-accepted
native renderer; experimental batching remains opt-in. See [fresh evidence and
idle-writer repair](validation/STEAM_DECK_20261005_WALL_IDLE.md).

The next native action after source publication is a fully restarted gm_flatgrass
capture with `lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180`,
preserving Proton, windowed Arch Desktop, resolution, graphics settings and
loaded population. Wall bodies must remain visible; live section applications
must stop increasing after construction/reconciliation. Return
performance_client_latest.txt + console_latest.txt. A separate population file
is not required. New repair FPS and sustained 40 FPS acceptance remain open.
Workshop and VPS remain outside this pass.

---

# Current author direction — ambient audio and core gameplay

Music System 3 is extracted into the separate `ShaelRiley/ms3-music-system`
repository with all original banks, sources, synthesis tooling and a manual
browser/WebView player. Deborah returns to ambient sounds and short event cues.
Keycard/jail-key discovery, unlock, learning, leveling and rescue cues no longer
depend on a music switch. Options exposes saved event-cue volume, Always Run and
Reduced Effects. All adaptive music code, download registration, hooks, banks,
source tooling and executable music-only tests leave this game repository.

This explicit October 4, 2026 author direction supersedes all historical music
requirements and pending music acceptance below. It does not reopen or redesign
combat, progression, enemies, bosses, VR or the ambient-sound lifecycle. Original
music evidence remains in the extracted repository; lightweight historical notes
below retain their historical status. Local native acceptance remains separate
from source checks. No Workshop publication or VPS deployment is part of this
source extraction/removal checkpoint.

Next native action: fully restart the updated local build on gm_flatgrass,
collect a keycard and open its gate. Verify the short discovery/unlock cues,
ambient and combat audio, and the absence of continuous music. Continue core
systems work after this finite audio regression check.

---

# Current repair checkpoint — gate-reveal enemy engagement

Source parent is verified main `2f4c968518ff29cb9ef206b3f9906d797b017ee1`, preserving
all authored modular bosses and the feat/music/VR work. A real generated-gate
regression reproduces an empty opening-pressure reservation: an enemy near the
Hero cannot acquire them under its native home leash, yet forces ready enemies
to withdraw. New reservations now require one current, native-eligible target;
stationary threat geometry, stale-route handoff, warning cancellation and actual
Watcher close-defense dispatch are repaired through existing authorities.

See [repair evidence and finite native procedure](validation/GATE_ENEMY_ENGAGEMENT_20261003.md).
Preserve sanctuary, combined opening quotas, native acquisition cadence/owned
states, full telegraphs, graph/gates and boss ownership. The publication reply
supplies the exact final source digest, complete matrix receipt, remote SHA and
CI result. Native GMod acceptance is still open; no Workshop/VPS operation.

Next: after exact-source restart on gm_flatgrass, open a gate and observe nearby
eligible enemies entering their actual attacks, including Soldier warning and
Watcher close retaliation, then verify reciprocal sanctuary safety. Keep all
previous native acceptance debts open.

---

# Current checkpoint — complete authored modular boss production

Source parent is verified main `96ab02aa78254eed9bfccb5b06dca947b82abd9f`. The original live GDD body was fully corrected and readback-verified before gameplay work. Exact authored order now routes eighteen new primary modules at Dungeons 2–19, retaining Gordon at 1 and Gordon→Hector at 20. Chuck alone owns Dungeon 14; Jane is subordinate. Timer-only automatic failure, retained no-Hero state and safe authored key locations remain authoritative.

The common registry/encounter owner extends canonical RPG damage/status/Push, native death/loot, Motion V2, graph/arena, music and key/jail/rescue. All mature authored routines, special completion, physical arenas, diagnostics and player manual are integrated. Read [production/acceptance](BOSS_PRODUCTION_ACCEPTANCE.md) and [exact implementation tuning](BOSS_IMPLEMENTATION_TUNING.md). The final publication reply supplies the exact child commit and frozen complete-gate receipt; do not substitute a focused pass or prior source count.

Native GMod visual/physics/input/co-op/Steam Deck acceptance remains open. After exact-source restart on gm_flatgrass, use the finite roster procedure in the acceptance record, prioritizing Chuck/Jane authority, Melf frozen identities, Button route/E timing, Joilette three-Cleaner recovery, flight/Strider cover/collision and the retained Gordon→Hector finale. Preserve all earlier feat/music/hit-stun acceptance debts. Source push only; no Workshop/VPS authorization.

---

# Current checkpoint — final feat rebalance

Implements the complete author ledger in `docs/briefs/FEAT_REBALANCE_20261002.md`
from remote-main baseline `b81e8b95c55df2c6f7f5eb8a4ef7292700aef68e` via recovered
validated checkpoint `e2997b15469ff335c2991d4f585770e8f0b4116c`. Existing music
and hit-stun floor repairs remain intact. The catalog now contains 114 ordinary
feats, six fallbacks and nine capstones, with retired ranks/CROSS ownership and
stored drafts repaired through the canonical migration authority.

`docs/FEAT_REBALANCE_ACCEPTANCE.md` records the exact inventory, review repairs
and native procedure. Publication `b5bf93bfc16828ac722113bb358d57b5026d2000` passed
the fresh 305-suite source gate. Separate VR CI then found a stale six-menu test
after removal of the Haste toggle. The repaired test now verifies the five
retained actions and is explicitly included in the final 306-suite frozen-source
matrix. This genuine expanded gate is distinct from the abandoned transfer's
unverified planned count. Verify the final remote commit and its Music/VR CI;
source checks are not native acceptance. No Workshop/VPS operation is authorized.

Primary live GDD rows match the ledger. Two duplicate corrections are applied and
readback-verified in tabs 06/07 (additive life capacity and Russian Asset's
at-least-15 funding/exactly-15 spend). Nine HUMAN duplicates remain blocked by
`FAILED_PRECONDITION` and a cancelled final attempt despite explicit permission.
Do not call GDD duplicate cleanup complete; preserve the successful corrections.

Next native action after verified source publication: fully restart/update GMod,
then run the compact acceptance session, prioritizing Russian Asset input and
vulnerability, movement/collision, ring reversal and stale-refund rejection.
Keep earlier music listening and hit-stun floor-presentation acceptance open.

---

# Current repair — MS3 song-first compositions

Author reports that the sixteen-bar system remains musically disjunct. Parent is `a73cafd2a7678bafe4bf84e8b4132af449546baa`, preserving intervening Gordon/gameplay work. Current direction supersedes randomized excerpt choice and immediate ordinary floor/tension replacement: play source-ordered driving edits through, preserve whole calm songs in staging, and let ordinary requests choose the next song. Boss/victory/Off, staging changes and new dungeon plans remain exceptions.

All 465 sources map to 40 continuous song edits plus eight short fanfares. No selected-window ranking, per-chunk foreground reassignment, competing-melody thinning or added exit fill remains in the active builder. A complete source performance is rendered once before bounded PCM slicing. Internal slices have no synthesis reset or per-chunk normalization; the player retains the 32-MiB ceiling and native compatibility fallback. Exact source windows and retained beat evidence are in `MS3_SONG_AUDIT.json`.

Run complete source/music/integration, real full-bank decode and actual browser song traversal gates before main publication. `validation/MS3_SONG.md` and its final receipt distinguish completed gates from native listening. The video remains inaccessible. Google rejected the live GDD amendment; `validation/MS3_SONG_GDD_AMENDMENT.md` preserves it. No Workshop/VPS action.

Next native action after verified source publication: fully quit/update/install main, enable Options → Music on gm_flatgrass, and remain in ordinary maze play for a complete song while crossing stairs and encountering changing danger. It should keep developing in order rather than switch every sixteen bars. Also check staging/deployment, boss, genuine victory and Off/On. Native perceptual continuity and Steam Deck performance remain unaccepted until heard.

---

# Current author-directed checkpoint — MS3 sixteen-bar source integration

From main `208a1af11c4448a054cc24e81603ed3446c0c55f`, the author authorizes source publication of genuine sixteen-bar arrangements and bounded playback. The canonical mapper now reads all 465 originals into 157 sixty-four-beat passages plus eight short fanfares (121,557 notes); catalog `ms3-s16-e5961c1e5e7bf8cd` matches Surge bank `ms2-surge-1d9386ddd67218a5`, 166 files / 46,853,341 bytes. Seven weak source-mapped exits contain baked percussion replacement fills. The new compact-tail loop avoids duplicate whole buffers and keeps the 32-MiB limit. Ordinary phrases advance after one pass; short-boundary role/stair response and healthy resident holds remain.

The active checkpoint includes source/MIDI/provenance parity, complete music and integration gates, actual decoding and browser-rendered long joins. See `docs/validation/MS3_LONGFORM.md` for exact evidence and outstanding limitations; source publication is not native acceptance. The guide video remains inaccessible/unverified. Google again rejected the live tuning insertion with `FAILED_PRECONDITION`; `MS3_LONGFORM_GDD_AMENDMENT.md` preserves it. This supersedes the earlier source-only candidate and two-bar hold design where they conflict, not their historical evidence.

Next native action: fully quit/update/install the exact published main, enable Options → Music on gm_flatgrass, and listen through at least two complete passages plus danger and a stair crossing/reversal. Confirm evolving sixteen-bar material, useful loudness, uninterrupted joins and clean Off/On. If a defect remains, collect `lod_music_client_status` twice and the normal console/summary logs. No Workshop/VPS action is included; local acceptance → Workshop parity → matching VPS remains the release order.

---

# Current repair checkpoint — MS3 sample-clock phrase continuity

The author reports rhythmic and dynamic segmentation on main 90510057c608f8e2beec9debc6ceec36b35d14f3. The previous frame-start/fast-seek repair is failed continuity evidence. The current authorized checkpoint moves capable clients to scheduled AudioBuffer playback of the same bundled Surge recordings, with the existing native backend retained for compatibility. This is rendered playback, not live synthesis. See docs/validation/MS3_SAMPLE_CLOCK.md for the design, measured gates, constraints and the still-required native audition. Source/automated audio validation never establishes in-game perceptual acceptance. No Workshop or VPS deployment.

---

# Current repair checkpoint — MS2 smooth phrase joins

Verified main `e633cd13fed0908ff424fb2da5190285cbc22407` is the repair parent. The author reports short clips changing too quickly and clearly audible fades at their joins, calls this MS3 and requests a quick fix with resident looping until replacement readiness. Native smoothness is failed evidence, not accepted continuity.

The canonical composer holds each ordinary phrase for four successful passes (14.77 seconds); roles/stairs/once-only victory remain responsive. Routine native joins use constant gain and natural release overlap. Offline full+tail arrangement bounds keep the shared peak guard from ducking at every join. If the same-role successor is not prepared, reuse the resident musical buffer on its eight-beat grid for at most two repeats within eight seconds; reject stale replacement and retry a complete phrase boundary. Preserve master gain 4, saved volume, peak ceiling 0.8 and all resource/lifecycle contracts. The encoded bank remains unchanged. See [focused evidence](validation/MS2_JOINS.md).

Live GDD 00 → 01 → 05/06/07 and the author Surge brief govern. Google rejected the tuning insertion with `FAILED_PRECONDITION`; its exact authorized-but-unapplied request is preserved. Complete music, actual decode and canonical integration gates precede source publication. Next native action: fully quit/update/install exact main, enable Options → Music and listen through several routine joins plus stairs for a steady level and unobtrusive transitions. Native Source smoothness and performance remain pending. No Workshop/VPS deployment.

---

# Previous repair checkpoint — MS2 intermittent phrase continuity

Remote main `174b011a62dd676285435feed2e551e8a3bf26bf` is the repair parent. The author initially reports silence, then hears intermittent music after several minutes or an audio-option toggle (cause uncertain). Their client diagnostic shows enabled/ready rendered playback, two channels, no reported backend error, quality 0 and nine native late skips. This is runtime-observed intermittent audibility and a failed continuity gate, not acceptance of the louder mix. Preserve the exact report in [MS2_CONTINUITY_NATIVE_REPORT.json](validation/MS2_CONTINUITY_NATIVE_REPORT.json).

Production regressions reproduce two causes of whole-phrase gaps: a prepared phrase discarded by a 100 ms frame hitch, and a correct native start treated as failed when its DHTML acknowledgement arrives 300 ms later. The native seam now admits prepared-frame delays up to 150 ms by fast-seeking past elapsed audio and retaining the original musical epoch. The existing 60 ms readiness tolerance still rejects late file opens. Larger frame delays resynchronize at a future bar. The composer separately waits up to one second for the result message; it never starts audio itself. One token per lane, bounded channels/opens/PCM, master gain 4, shared peak ceiling 0.8, saved volume, permissions, role/stair/victory behavior and the complete encoded bank remain constraints. Actual native state/position/volume and phase-join/ack-timeout diagnostics are available in client status.

Live GDD 00 → 01 → 06/07 and the explicit Surge brief govern. The tuning write received `FAILED_PRECONDITION`; [the authorized but unapplied request](validation/MS2_CONTINUITY_GDD_AMENDMENTS.json) is preserved. See [finite evidence](validation/MS2_CONTINUITY.md). Run the complete music gate, actual decode and canonical integration matrix before source publication. Next native action: fully quit/update/install exact main, enable Options → Music and listen for at least two minutes through staging, danger and a stair crossing. No entire missing phrases should occur during ordinary frame pressure. If gaps persist, run `lod_music_client_status` twice a second apart (composer statistics arrive asynchronously) and preserve both lines plus `console_latest.txt` and `rpg_summary_latest.txt`. No Workshop or VPS operation is included.

---

# Previous repair checkpoint — MS2 audible playback level

The author confirms music is audible on recovered main `b0f86dccedae3093355c239cd9608662b80cfd58`, but far too quiet. Median decoded Chill is about −36.81 dBFS, falling to −42.00 dBFS at the saved default 0.55 volume. The canonical native phrase seam now applies gain 4 (+12.04 dB), with one shared estimated score peak ceiling of 0.8. Existing decoded-peak metadata bounds floor lanes, natural tails, the quiet bridge and gains awaiting their 30 Hz writes. Decreases precede increases; each increase uses only remaining headroom. The common reduction preserves square-root stair weights and arrangement dynamics. Saved volume, Off, the catalog/composer, server authority and all encoded audio remain regression constraints.

Live GDD 00 → 01 → 06/07 and the explicit author Surge brief govern. Google rejected the tuning insertion with `FAILED_PRECONDITION`; its exact authorized but unapplied text is in [MS2_LOUDNESS_GDD_AMENDMENTS.json](validation/MS2_LOUDNESS_GDD_AMENDMENTS.json). The metadata-only producer change refreshes renderer provenance without changing synthesis or the bank's 59,993,192 audio bytes. See [focused evidence](validation/MS2_LOUDNESS.md).

Required source gates remain the complete music gate, actual full-bank decode and canonical integration matrix. Prior playback audibility is now runtime observed; louder balance still requires fresh native evidence. Next action: fully quit/update/install exact published main, enable Options → Music, and compare staging, danger and a stair crossing at the current volume setting. Confirm useful loudness, clear musical balance and no distortion; lower the slider to confirm control. Preserve `lod_music_client_status`, `console_latest.txt` and `rpg_summary_latest.txt` only if a defect remains. Workshop and VPS are separate actions.

---

# Previous repair checkpoint — MS2 playback recovery

The author reports silence on Surge main `795001f1fa27dc9c99a5d79ae845ed78a2a7a0da`. Production regressions reproduce an expired HTML startup deadline repeatedly extending the ten-second native-failure retry, and a later gap timeout overwriting the first audio-open error. Startup readiness/teardown now clear that panel's deadline; only a live initializing panel may time out. The first native error survives later open/bridge/gap failures, and status exposes the fixed remaining backoff and pending startup. The unchanged catalog, audio bank, server authority and host Options remain regression constraints. See [focused evidence](validation/MS2_SURGE_RECOVERY.md).

Required source gates remain the complete music gate, actual audio decode and canonical integration matrix. Native silence is reported; its initial engine diagnostic was not recoverable, so audibility after this correction requires fresh evidence. Next action: fully quit/update/install the exact published source, start LoD on gm_flatgrass, enable Options → Music and listen in staging. If silent, run `lod_music_client_status` and preserve its exact output plus `console_latest.txt` and `rpg_summary_latest.txt`. Source publication does not publish Workshop or deploy the VPS.

---

# Previous author-directed checkpoint — MS2 Surge backbone

From verified main `c4fb2c0c497b661f0fa7bb972a5c3fe6683b3517`, the author replaces primary live note synthesis with offline custom Surge XT 1.3.4 rendering and bounded local Ogg phrase playback. The eight-block/48-arrangement/1,402-phrase/170,860-note catalog and server MusicDirector remain authoritative. Bank `ms2-surge-0f7591eb682f3b2b` contains 1,402 phrases plus one bridge at 59,993,192 encoded bytes. Acid has strong held-note filter movement; readable patches, pinned external build glue, complete hashes/levels and a 47.7-second audition are committed. No Surge runtime dependency or soundtrack streaming is required.

The ES5 composer keeps authored successor selection on a fixed 130 BPM clock. Native playback uses absolute deadlines, discards missed musical time, and bounds channels to eight / pending opens to two / estimated PCM admission to 32 MiB. Role bars, reversible stairs, once-only fanfare/Chill, private new-block announcements, default-Off and host Options enablement remain. Old per-note mutations/fills, +6% tempo slew and +22-cent lift are superseded; +8% critical gain remains. See [implementation](MUSIC_SYSTEM.md), [budgets](MUSIC_PERFORMANCE.md) and [finite evidence/native procedure](validation/MS2_SURGE.md). The authorized live GDD write failed with `FAILED_PRECONDITION`; its exact unapplied amendment is preserved.

Required source gates: `python3 tools/test_music_gate.py --output /tmp/ms2-surge-gate`, actual decode via `node tools/test_music_audio.js`, and canonical `python3 tools/test_checkpoint_g_integration.py`. Native acceptance is pending: fully quit/update/install exact main, start LoD on gm_flatgrass, enable Music in Player Menu → Options, then hear staging/deployment/calm/danger/combat/relaxation/stairs/reversal/boss/fanfare/Chill/Off–On and inspect `lod_music_client_status`. Judge coherent dance-synth timbre, Acid movement, musical joins, no catch-up, smooth stairs, immediate Off and Steam Deck performance. Workshop and VPS remain separate, untouched actions.

---

# Previous repair checkpoint — MS2 Options enablement

The author now confirms native music plays with `lod_music_enabled 1; lod_music 1` on main `93e793cfb35bc0dbef81cb2b079a385ff935578d`, but selecting Music in Options does not start it. This isolates the remaining defect to UI enablement: the old checkbox controls only `lod_music` and can appear checked while the server master is Off. Playback itself is now natively observed under explicit permission; broader musical/performance acceptance remains separate.

The existing MusicDirector demand channel now carries an explicit Options-enable intent. Only the listen-server host or a superadmin may use it to turn the master On. Ordinary startup/reconnect demand preserves default-Off; a player's Off remains personal. The host/operator checkbox displays both local preference and master permission, and its read-only refresh cannot alter settings. The new production-Options regression covers the queued client command, server grant, paced plan/state delivery, renderer handoff, per-player Off and denied remote enablement. See [repair evidence](validation/MS2_OPTIONS_REPAIR.md).

Next native action: fully quit/update/install main, start LoD on gm_flatgrass and toggle Options → Music Off/On. Music must resume without console commands. Preserve `console_latest.txt` plus `rpg_summary_latest.txt` if the menu path fails. The prior console-enabled audibility report is positive evidence; this menu repair still requires its own fresh test.

---

# Previous repair checkpoint — MS2 complete-bank JSON admission

The author reports that music remains silent on main `6abd1e2786a075888d27d6f510a3d48226f18353`, while the Options correction is visible. The earlier path repair is insufficient: GMod's default JSON decoder limits the total number of keys to 15,000. The actual bundled catalog contains 41,125 keys and 62 of the 63 note pages exceed that limit (largest 16,988), so both admission stages reject the score. Only trusted, byte-bounded bundled catalog/note decoding now uses the documented `ignoreLimits` argument; schema/note validation, cache budgets and network decoder limits remain in force.

The permanent catalog suite now runs production server/client loading against every real arrangement and note page with that native key boundary. It reproduces catalog rejection before repair and note-delivery rejection with the catalog-only fix, then admits all 48 arrangements, 1,402 phrases and 170,860 notes with both fixes. See [repair evidence](validation/MS2_JSON_REPAIR.md). Run the finite music/audio gate and publish the exact verified source. Fully quit/update/install GMod, load LoD on gm_flatgrass, enable `lod_music_enabled 1; lod_music 1` and listen in staging/gameplay. Native audibility remains pending fresh evidence; preserve `console_latest.txt` plus `rpg_summary_latest.txt` if failure persists.

---

# Previous repair checkpoint — MS2 catalog loading

The author's first native MS2 attempt on main `bc3cf1967ebdc77e98c5fc028ef6337c9e7139fe` reported silence and `Couldn't include file 'lod\\ms2\\catalog.lua' - File not found or is empty` from `sh_music.lua` during `sv_music.lua` startup. The catalog exists in the repository; the nested loader incorrectly assumed include paths always resolve from the gamemode root. Catalog, engine, note pages and client distribution now use the explicit `legend_of_deborah/gamemode/lod/ms2/` virtual path. Missing mounts produce a precise diagnostic before attempting a noisy include. The user also requests removal of the stale server-disabled Music message; Options now retains the location/danger description without a recurring status callback.

The strengthened music fixture models nested and rootless include contexts and a client using server-delivered Lua without loose files. The new production-path regression reproduces the old failure, checks server catalog admission, client engine/note handoff, every actual distributed score file and missing-mount recovery. Run the finite music gate and GitHub CI. After pulling/installing, fully restart GMod, load LoD on gm_flatgrass, enable `lod_music_enabled 1; lod_music 1` and listen in staging/gameplay. Native audibility remains pending fresh evidence; prior offline audio/source results did not establish native acceptance. See [repair evidence](validation/MS2_LOADING_REPAIR.md).

---

# Previous author-directed checkpoint — Music System 2

Repository `ShaelRiley/the-legend-of-deborah`, canonical `main`; implementation parent `b4f9f67e2d837e71da1a194dc655a212fd74ff4c`. The author explicitly replaces the bandwidth-heavy MS1 score with a complete local MIDI/synth system and authorizes source publication and cleanup. This checkpoint supersedes the older streaming-music provisioning sequence below; preserve intervening VR/gameplay work.

Eight authored blocks and all 48 MIDI arrangements are compiled into 1,402 curated phrases, with original-source lineage, D-Dorian cleanup, nine instrument parts, cadence/energy successor graphs and portable MIDI exports. The existing reactive MusicDirector retains permission/default-Off, seeded physical-floor plans, staging/portal continuity, pressure, bosses, victory receipts and Die Logger ownership. MS2 adds local synthesis, procedural performance variation, periodic fills, a shared musical clock, restrained timer BPM/expression and bounded native fallback. MS1's downloader/origin/upload/cue implementation and obsolete tests are retired; historical evidence remains historical.

Read [MUSIC_SYSTEM.md](MUSIC_SYSTEM.md), [MS2_CATALOG.md](MS2_CATALOG.md), [resource budgets](MUSIC_PERFORMANCE.md) and [validation](validation/MS2.md). The finite gate is `python3 tools/test_music_gate.py --output /tmp/ms2-gate`; add `MS2_CHROMIUM` for actual offline Web Audio. GDD navigation 00 → 01 → 05/06/07 was followed. Google Docs rejects the authorized amendment with FAILED_PRECONDITION and its fallback browser session is view-only; [the unapplied amendment](validation/MS2_GDD_AMENDMENTS.json) is preserved. Explicit current author direction governs this design change.

Next native action: fully quit/update/install main, load LoD on gm_flatgrass and enable `lod_music_enabled 1; lod_music 1`. Play staging → portal → danger/stairs/reversal → boss → actual rescue/fanfare → Chill, then toggle Music Off/On and inspect `lod_music_client_status`. Confirm audible instruments, uninterrupted phrasing, restrained urgency, once-only fanfare and clean Off on the intended PC/Steam Deck. Source and offline audio results do not establish Source/DHTML/co-op/FPS acceptance. Preserve existing native/release gates; no Workshop/VPS deployment is included in this checkpoint. Keep console_latest.txt plus rpg_summary_latest.txt for contradictory runtime evidence.

---

# Current user-directed branch checkpoint — VRMod server provisioning repair

The current user explicitly requests VR support published as TheMemeticist on
`master`. The earlier compatibility checkpoint is merged into main
`5b1b29166e03dfbc2faeca3634ddf379d0d84e6b`, but the live server reported its
VRMod addon missing. This repair bundles the complete pinned Lua/content addon,
installs and verifies it before every dedicated-server start, registers client
content, and requires actual VR networking in the deployment health gate.
Native startup also exposed weapon-definition hook return values stopping later
map initialization; those callbacks now allow the lifecycle dispatch to continue.
Controller menus, camera ownership and shared life/Tetris actions remain at
their existing seams. Gameplay authorities and physical-keyboard Special Move
recipes remain the baseline. `lod_vr_start` diagnoses the remaining client
prerequisites and requests the upstream VR startup command.

Finite gate: `python3 tools/test_vr_gate.py`; evidence and remaining headset/
multiplayer gates are in `validation/VR_COMPATIBILITY.md`. Deploy the source and
fully restart the service to load the dependency. This checkpoint does not
deploy the live VPS or publish a Workshop package. The current
music checkpoint and its separate deployment/acceptance work remain below.

# Previous main checkpoint — six-role music folder/ZIP catalog

The author requests Chill = Tension 1, Tensions 2–4, Boss and Fanfare, with the
first block as every missing-role default. From main `79faf3d`, the existing
music ingestion authority now accepts a complete folder/ZIP library, creates
manifests/versions/cues/chunks offline and publishes one validated catalog. Chill
also serves staging/post-fanfare; active/offered plans stay frozen. An explicit
cue rebuild preserves authored overrides; unchanged ordinary imports skip analysis.

Finite evidence: `validation/MUSIC_FOLDER_CATALOG.md`, 41/41 selected suites,
813 Lua syntax checks and 80 new real-audio/import assertions. The Google Docs
amendment failed with FAILED_PRECONDITION; its unapplied text is preserved in
`validation/MUSIC_FOLDER_GDD_AMENDMENTS.json`. Current explicit author direction
governs. No music origin, recordings, native acceptance or deployment is claimed.
Next: use `history/MS1_MUSIC_FOLDER_IMPORT.md` to provision HTTPS, import before a new campaign,
then test the exact source through Chill → tension/stairs → boss → rescue/fanfare
→ Chill. Retain default-Off and local acceptance → Workshop parity → matching VPS.

---

# Prior checkpoint — Options Always Run repair

The author reports that selecting Always Run does not produce running and
expressly authorizes commit/push. From verified main `673590c`, the existing
shared PlayerOptions movement seam now scales horizontal requests as well as
their effective speed cap. Walking-sized/analog requests previously stayed at
walking speed despite the raised ceiling. A zero native client cap is now
resolved from the move cap before publishing matching limits to both realms.

Live GDD 00 → 01 → 06 LOD-UI-OPTIONS-001 governs; no design change. The existing
Options binding, physical sprint modifier, Soldier rules and movement effects
remain authoritative. The failed-parent reproduction and 11/11 passing selected
checks (including 813 Lua syntax checks) are recorded in
`validation/AUTORUN_20260928.md`. Native acceptance remains pending: restart on
the published source, enable Options → Always Run, move normally, then hold the
sprint key to walk and release it to resume running. Preserve the other native
gates and local acceptance → Workshop parity → matching VPS release order.

---

# Prior checkpoint — universal enemy close defense

The author requests visible attacks from rare creatures and retaliation under
sustained crowbar pressure. From verified main `863f7fe`, native behavior now
offers an existing-service physical close defense before specialist wrappers;
committed primary attacks retain their controller. All hostiles share the existing
three-second melee-stagger recovery, and stock attack-sequence resolution covers
models whose NPC activity request falls back to idle. Preserve the recent skeleton
player-animation repair and existing combat/lifecycle/arrival authorities.

Live GDD 00 → 01 → 03/07 was read. Google rejected the design-amendment write;
the proposed text remains in `validation/ENEMY_CLOSE_DEFENSE_GDD_AMENDMENTS.json`
and has not changed the live GDD. Current explicit author direction governs this
correction. The finite source gate passes 47/47 selected suites and 813 Lua syntax
checks; see `validation/ENEMY_CLOSE_DEFENSE_20260928.md` and its checks receipt.

Native acceptance remains pending. Next: fully restart/install and maintain
crowbar pressure on a close rare enemy on gm_flatgrass; observe the warning,
counterattack and evasion, including device/skeleton visuals when encountered.
Preserve remaining native gates and local acceptance → Workshop parity → matching
VPS release order. Source publication only.

---

# Prior checkpoint — skeleton player animations

The author reports T-posing skeletons and expressly authorizes the source push.
From verified main `9d3c202`, the shared hostile resolver now uses stock GMod
player activity families/weapon holds for the skeleton model, with attack gestures
as overlays. Both model-swap constructors select idle immediately; Motion V2
drives player move_x/y from its existing kinematic movement. Preserve complete
player bases across flinches/death and avoid activity-alias cycle restarts.

The finite gate passes 15/15 selected regressions and 811 Lua syntax checks;
see `validation/SKELETON_ANIMATION_20260928.md` and its checks receipt.
Native appearance remains pending. Next: fully restart/install and observe an
event skeleton and fallen-player copy through idle, pursuit, attack and damage
on gm_flatgrass. Preserve existing gameplay, performance work and remaining
native gates; local acceptance → Workshop parity → matching VPS remains in force.

---

# Prior checkpoint — custom-system quantization

Shael reports good Steam Deck performance on renderer main `cdb85e6` and requests
further custom-system simplification. The finite pass replaces event-route text
signatures with a blocked/open mask, caches exact loot budgets by integer depth,
uses squared near-look cone comparisons before visibility traces, and prepares
projectile trails once per visible snapshot. Preserve authored formulas, dice,
movement, collision, enemy population, timing and the accepted renderer.

Live GDD 00 → 01 → 07 LOD-IMPL-001–004 governs; no authored tuning changes.
`validation/SYSTEM_QUANTIZATION_20260928.md` records 38/38 selected checks,
810 Lua syntax checks, exact-value/route/endpoint comparisons and bounded work
counts. Native performance improvement for this candidate is not measured.
Next: fully restart/install the verified source and play ordinary gm_flatgrass
through targeting/loot, projectile combat and Skeleton-blockade resolution.
Retain outstanding native gates and local acceptance → Workshop parity → matching
VPS; source publication only.

---

# Prior checkpoint — low-end renderer follow-up

The repeated Steam Deck slowdown report promotes a renderer follow-up from main
`c55a4a4aea77994e8c80725b621e0ef86f856e81`. Extend the existing bounded TexturedBox
cache with weak per-entity mesh/transform reuse, and extend generated geometry's
rear-plane rejection to known perspective side/top/bottom planes. Preserve live
dimensions/transforms, world-planar UVs, the 256-mesh ceiling, map/full-update
recovery, hidden false floors, materials, all game rules and current startup fixes.

Live GDD 00 -> 01 -> 07 LOD-IMPL-004 governs; no new tuning or design amendment.
`validation/LOW_END_RENDER_20260928.md` freezes scope, paired operation counts and
the finite selected integration gate: 32/32 passed plus 808 Lua syntax checks.
Native FPS/fan behavior remains unmeasured.
Next: install verified main, play ordinary gm_flatgrass through a full camera turn,
stairs and combat, and report smoothness/any missing geometry. Preserve outstanding
native gates and local acceptance -> Workshop parity -> matching VPS. Source only.

---

# Prior checkpoint — immediate staging campaign-failure repair

The author reports two immediate Campaign Failed resets while still in staging.
This repair extends main `b5a829355291fcae11e963d8891dd9441719b0e7`.
The final regression reproduces a matching failure against that parent: campaign
31676 reaches staging on layout 14, but its Skeleton occupies entry-apron cell
1:9:0. Native Initialize schedules removal; IsValid and later positive HP let
construction finish before the next tick reports the required hostile lost.

Skeleton placement now uses the existing EntrySafety spawn-cell authority.
Event construction rejects native entities marked for deletion and rechecks all
tracked resources before committing the complete plan. The same campaign and
event selection now use legal cell 16:16:1 on the same layout. Arrival protection,
real combat rewards and canonical failure on genuinely lost live resources stay
enforced; no new recurring service is added.

The exact-source gate passed 35/35 targeted checks and 807 Lua syntax checks.
Read `validation/STAGING_EVENT_SPAWN.md` for the failed-parent reproduction,
three-class native initialization, prolonged staging, deferred cleanup and
partial-creation evidence. Next: fully quit GMod, install verified main, then
start on `gm_flatgrass`, prepare in staging and deploy normally. The reported
session's full failure reason was not supplied; native acceptance remains open.
Source publication only; preserve music/low-end work and existing release gates.

---

# Prior checkpoint — fatal empty-map bootstrap recovery

The author reports an empty `gm_flatgrass` with
`event placement exhausted: skeleton_blockade: nil`. This repair extends main
`019d445b76573b3b9d5f77a4c3b7a2df8c63be0e`. With production progression safety,
Neil/Black Gate, Warden arena and arrival reservations loaded, campaign seed
31676 reproduces the failure: its first progression-safe layout has no legal
blockade site. Event rejection previously aborted the complete build before
staging could run.

RunManager now continues the existing deterministic layout stream on explicit
event-placement exhaustion, within the original shared 64-layout ceiling.
Event selection stays frozen; cleanup and all graph/native/route proofs remain
mandatory. Failed attempts cannot advance ecology or release players. Reported
callback, integrity and native creation failures do not authorize a retry.
The same failing seed reaches layout 14 with its original two selected events.

Read `validation/BOOTSTRAP_EVENT_RECOVERY.md` for finite startup/lifecycle
coverage and preserved reproduction evidence. Next: fully quit Garry's Mod,
install verified main and start the gamemode on `gm_flatgrass`; confirm staging,
portal deployment and the populated maze. Native acceptance remains open.
Preserve music/low-end work and local acceptance → Workshop → matching VPS.
This checkpoint authorizes source publication only.

---

# Prior checkpoint — Chill staging and gameplay-first music

The author requests staging's Chill/INTERLUDE arrangement and resource priority
for gameplay. This extends verified main `cdfcbb1ab8652109ba141c59b298fb03b68ae676`.
Live GDD 05/06/07 now records Chill staging, explicit opt-out, bounded on-demand
media caching, paced downloads and resource shedding. Existing block assignment,
pressure, pulse/quiet section and one-shot victory authorities remain in charge.

Fixed 16 KiB media objects, one HTTP request, a bounded verified disk cache and
local native playback replace uncontrolled URL streams. Disabled/zero-volume
clients suspend music service. Congestion postpones optional work; severe client
overload releases the score. Read `MUSIC_PERFORMANCE.md` for limits, legacy-host
migration and the finite native gate. Results are in `validation/MUSIC_PERFORMANCE.md`;
source checks do not establish native FPS, latency, memory, audio or router QoS.

Next: prepare hosted chunks offline, install the published source, start a new
campaign and run the compact native music/contention gate. No Workshop or VPS
release belongs to this checkpoint. Preserve prior low-end optimizations and
local acceptance → Workshop parity → matching VPS.

---

# Prior checkpoint — pulse-first music section direction

The author promotes section-aware music direction from main
`67cb7dbf7343d05cd52c3f429e33322a8fc30248`. Rhythmic class has primacy:
T1–T3/BOSS sustain a pulse, falling active pressure uses gentler pulsed material,
and T0/INTERLUDE sustain quiet. Offline import prepares bounded, editable cue
maps. The existing client mixer renews sections before inappropriate endings,
rotates entries, reuses a buffered pair, and preserves four channels/two transfers.
There is no gameplay-time waveform analysis. VICTORY and block-name logging retain
their existing one-shot/logical-block semantics. Server music still defaults Off.

Validation: all 287 registered suites have passing coverage on unchanged source;
the full matrix was 286/287 plus an isolated passing rerun of its one 600-second
campaign timeout. All 802 Lua files passed syntax checking. See
`validation/MUSIC_SECTIONS.md` for exact receipts, retained attempts and native limits.

Live GDD 05/07 pulse-first amendments were written and read back. See
`history/MS1_MUSIC_SECTION_DIRECTION.md` for authoring, compatibility, runtime limits and the
finite native gate. Legacy cue-less media needs a new offline-imported version;
active/offered plans stay frozen. Hosted media and native listening/performance
acceptance remain pending. The full canonical matrix now includes the new offline
classifier and section playback gates, alongside the existing music ingestion
and low-end regressions. Retain local acceptance → Workshop parity → matching VPS.

Next: provision/audition prepared tracks, install the published source, and run
the short native music gate. No Workshop publication or VPS deployment belongs
to this source checkpoint. Preserve the prior Steam Deck optimization and all
outstanding accepted-regression/native gates.

---

# Prior checkpoint — low-end PC / Steam Deck client optimization

The author's slowdown report promotes the planned low-end work. This checkpoint
extends main `3d60d6f730b56abbf3df5de68bb8d71002d44d96` with immutable container
palette/material caches, conservative rear-camera static-geometry rejection,
pass-local floor material reuse and an Options checkbox for the existing saved
Reduced Effects preference. Skeletons, events, loot, enemy population/AI,
geometry/collision, music defaults and all gameplay rules are unchanged.
The full gate also repairs a nil-target guard in the fallen-Hero damage wrapper
and missing native API doubles in an older protected-regression harness.

Read `validation/LOW_END_PC_20260928.md` for paired operation counts, cache/camera
safety cases and the exact-source native procedure. Three new low-end checks and
six retained music/options checks extend the complete canonical gate to 285
suites. Retain the initial 279/285 run (four timeouts and two repaired regressions);
the final complete run uses a 600-second per-suite headless allowance with no
reduced inputs or assertions. The immutable local/independent receipts, not old checkpoint
counts below, establish this candidate's aggregate result and published identity.
Publication requires both gates and an exact-parent non-forced main update.

Next is ordinary Steam Deck play on the installed source: the efficiency changes
are automatic; Reduced Effects is an optional saved choice in Options. Native
FPS/frame time and visual acceptance are not measured by headless tests. Preserve
all previous native gates and local acceptance → Workshop parity → matching VPS.
No Workshop/VPS deployment belongs to this source checkpoint. Historical sections
below remain evidence, not instructions to repeat completed work.

---

# Current checkpoint — live GDD reconciliation complete; native acceptance next

The author's express approval to amend the GDD closes the Big Loot, Big Event,
Music and Big Skeleton synchronization backlog against gameplay main
`2847f416b8d152a24ac4d282cc012e73ddb131d7`. Recent SPOT, audit, cleanup and
equipment/faction repairs are represented; obsolete deferrals and music
implementation-pending/default-On statements are corrected. The newer modular
boss design remains intact and is not claimed implemented by this checkpoint.

Read live GDD 00 → 01 → the relevant normalized rule. Big Loot's active catalog
is now in 05; HUMAN retains all 113 exact authored identity rows. Exact duplicate
passages were consolidated into canonical references to resolve apparent size
pressure, with every retained rule verified. All ten tab texts match the expected
edit, and native date elements and tab topology are preserved.

See `validation/GDD_SYNC_20260928.md` and its JSON receipt. Earlier failed-write
notes below are historical; do not replay their old insertion payloads. This
checkpoint changes documentation only. Gameplay/source-test evidence and all
pending native acceptance remain unchanged. Next: the finite Big Skeleton local
gate below, then existing native gates; retain local acceptance → Workshop parity
→ matching VPS. No Workshop publication or VPS deployment occurred.

---

# Prior checkpoint — Big Skeleton source; native acceptance next

Author-directed design and implementation extends verified main
`f0b7a66d0e87c18ad18b45a6449b613b7f8ee11d`. Skeleton Blockade remains registered
after Bribe removal; a separate 65% priority draw and two-dungeon drought cap
now make it frequent without changing exact 1d4 density or the rare slot.
Accepted Hero and human-Soldier deaths independently create hostile AI copies
of their current builds, using shared combat and lifecycle authorities.

See `BIG_SKELETON_UPDATE.md` for behavior, explicit AI-action scope and the
finite local gate. `validation/BIG_SKELETON_UPDATE.md` records 52/52 targeted
regressions, 798 Lua syntax checks, final lifetime hardening checks, frequency
samples and retained logs. Native appearance/combat/co-op acceptance is pending.
Google again rejected the guarded GDD write; final proposed 05/06/07 amendments
are preserved in `validation/BIG_SKELETON_GDD_AMENDMENTS.json`. Earlier GDD
synchronization debt and native gates remain independent.

Next action on exact local source, `gm_flatgrass`:
`lod_developer_mode 1; lod_event_preview_generate skeleton_blockade`.
Then follow the short fallen-player test in the implementation note. Preserve
local acceptance → Workshop parity → matching VPS; no deployment is claimed.
Evidence: `console_latest.txt` + `rpg_summary_latest.txt`.

---

# Prior checkpoint — Music System source; streaming defaults OFF

The author-promoted Music System extends verified main
`c5ece210be12077c321264ad4abb81821fe8d9a5`. `lod_music_enabled 0`
is the default; only the server may permit streams. Existing player Music Off
also wins. Live GDD 00→01→05/06/07 and the Options anchor govern six roles,
optional interlude, inheritance/universal themes, sets, frozen floor plans,
spatial/pressure mixing, accepted-victory continuity and private Die Logger starts.

See `MUSIC_SYSTEM.md` for implementation, bounded HTTPS ingestion/upload, original
separate default assets, operator commands and the finite native gate. Source
verification results are recorded in `validation/MUSIC_SYSTEM.md`. Native audio,
UI, network and performance acceptance remain pending; no public HTTPS origin,
Workshop update or VPS deployment is claimed. The required default-Off GDD edit
and provisional tuning write failed with HTTP 400 FAILED_PRECONDITION; fresh
readback is unchanged. Exact amendments: `validation/MUSIC_GDD_AMENDMENTS.json`.
Earlier Big Loot/Event synchronization debt remains independent.

Next: provision/audition the default profile on an operator-controlled HTTPS
origin, install the exact source locally, start a new campaign and run the short
native music gate. Maintain local acceptance → Workshop parity → matching VPS.

---

# Current checkpoint — Big Event System source validated; native acceptance next

The author-promoted `briefs/EVENT_SYSTEM_UPDATE.md` extends verified main
`1685774415ea8bbd82abf931999a29ae7ba25f10`. Frozen active baseline8, additions20,
production total28 (3.5×); removed Bribe stays removed. Exact1d4 density, shared
rare fourth slot, existing progression proofs and source-only publication remain.

See `EVENT_SYSTEM_EXPANSION.md` for catalog, shared settlement, family/identity
ecology, successful-build campaign memory, topology preferences and a compact
native procedure. All **274/274 suites and 784 Lua syntax files pass**, including
six new gates; the source remained unchanged throughout the full matrix. See
`validation/BIG_EVENT_UPDATE.md` and its complete receipt/evidence archive.
Native Source physics/input/presentation/network/co-op acceptance remains pending.

Live GDD00→01→05/06/07/90 read successfully. Google rejected the revision-guarded
write with `FAILED_PRECONDITION`; fresh readback confirmed no mutation. Exact
six-tab changes remain in `validation/big_event/gdd_amendments.json`. This is an
explicit synchronization blocker, not a completed GDD update. Prior Big Loot
amendments remain independently outstanding. No Workshop/VPS action.

Next after verified source publication: exact-build local `gm_flatgrass` event
acceptance, retaining earlier accepted behavior and pending gates. Capture
`console_latest.txt` + `rpg_summary_latest.txt`. Apply the pending live GDD changes
when editing is restored; unrelated deferred roadmap work is not included.

---

# Current checkpoint — Big Loot source validated; live GDD synchronization blocked

Author-promoted Big Loot extends verified baseline
`fc166870633db5f277165d9c33ae00d82feaa81a`. Final gameplay/test commit:
`4f9ec7928f4a44107066da3095937655db806941`. This closeout adds documentation/evidence only; the delivery
response supplies the fetched, verified final remote HEAD.

Frozen baseline **45**, added **113**, total **158 (3.5111×)** meaningful identities.
Stable effect packages, campaign motifs/history, contextual/topological rewards,
late optional treasure, inventory pressure and immutable source receipts extend
existing authorities. Native weapon restoration and atomic sell/fuse are repaired.
See `BIG_LOOT_CATALOG.md`, `BIG_LOOT_ECOLOGY.md` and
`validation/BIG_LOOT_UPDATE.md` for architecture, constants and exact evidence.

Complete finite matrix: **268/268**, **774 Lua syntax files**, unchanged source.
32×20 campaigns with two owners expose all 113 additions; mean 106.516 / minimum 100
per owner-campaign, 92.75% fewer immediate repeats and 35.94% less adjacent-level
overlap versus history-disabled control. All 15,422 support nodes preserved.
Sampling uses empty bags/native doubles; native gameplay and balance are unaccepted.

**Outstanding:** Google Docs rejects live GDD edits with HTTP 400
`FAILED_PRECONDITION`; fresh reads confirm no mutation. Exact seven-tab amendments
and 113 authored rows are saved in `validation/big_loot/gdd_amendments.json`.
Apply/read back after editing is restored. No live synchronization or complete
end-to-end closure is claimed. Native `gm_flatgrass` pickup/equipment/economy,
lifecycle and co-op acceptance follows verified publication, preserving all prior
acceptance constraints. No Workshop/VPS action. Earlier Big Loot deferrals are
superseded by this explicit author request; unrelated roadmap work stays deferred.

---

# Current checkpoint — stalled cleanup reconstructed; native acceptance next

September 27 author-requested recovery extends verified main
`aa102cc31951d34937ebaa106314cfcfdb855a2f` without repeating the prior systems audit.
See `validation/CLEANUP_RECOVERY_20260927.md` for repaired loot/campaign/staging,
party scaling, jump/death lifecycle, warp diagnostics and isolated Bribe fixtures.
The complete gate retains all 262 earlier suites and adds two production tests
(264 entries; 767 Lua syntax files). Final pass/tree/publication evidence belongs
to the delivery receipt, not a source-preparation assumption here.

Next after verified publication: exact-build local `gm_flatgrass` acceptance.
Preserve existing regressions and local acceptance -> Workshop parity -> matching
VPS. No deployment or deferred-roadmap work is included. Older headers below are
historical where this checkpoint supersedes them.

---

# Current checkpoint — September 27 systems audit complete

The author's audit request supersedes earlier deferrals. Source and validation
repairs are published through `864cdf36854c3671926a9473221c74b7ca727fa5` on main;
this closeout changes documentation only. Read `validation/SYSTEMS_AUDIT_20260927.md`
for findings, exact tree/source digest, coverage and the retained failed attempts.

The complete expanded matrix passes **262/262**, including **765 Lua syntax
checks**, with identical source before/after. The original matrix was 228/235.
Minimap cache/request/lifecycle ownership, Muted potion input, duplicate equipment
sync and stale validation contracts are repaired. No automated failure remains.

Next finite gate: exact-build local gm_flatgrass acceptance, including Muted potion
use and map reopening after rebuild/respawn. Retain all previous SPOT,
Soldier/Reckless, stair, stomp, arrow-input, B28/B29 and Crate acceptance constraints.
Native input/network/physics/rendering and co-op acceptance remain open; headless
results do not establish them. Preserve local acceptance -> Workshop parity ->
matching VPS. No Workshop/VPS deployment occurred during this audit. Historical
sequencing below is superseded where it conflicts with this checkpoint.

---

# Current overlay — Heavy Plumber and arrow-input equipment repairs

September 27 author-requested spot fixes preserve main baseline
`38adbce415ae6dd388c28a450bb9cd3b7a8248d2` and all Soldier/Reckless, standing-stair
and SPOT-17 work. Read `docs/validation/EQUIPMENT_STOMP_CONTACT_20260927.md` and
`docs/validation/EQUIPMENT_ARROW_INPUT_20260927.md`; fetch current main and use the
external delivery receipt for exact published commits/tree and independent gate.
First-impact stomp geometry and bounded ordered input transport extend their
existing authorities without changing attack costs, damage or recipes. Native
acceptance remains pending. No Workshop/VPS actions, full campaign-matrix pass,
SPOT-18 or deferred-roadmap work is claimed. Historical sections follow.

---

# Author-reported stair ceiling repair — native acceptance next

### Current author-requested spot repair — Soldier / Hero and Reckless damage (September 27, 2026)

The standing-stair repair remains preserved. The new unnumbered damage repair follows current combat roles rather than engine player class and respects attacker-only Reckless in native damage and real attack geometry. See `docs/validation/FACTION_RECKLESS_DAMAGE.md` and the external publication receipt for exact child/tree and headless results. Native acceptance remains pending; no Workshop/VPS action. This is not a new scheduled SPOT-18 or a restart of the deferred roadmap.


September 27: the rear crossover lip now retracts 16 units, sharing its 48-unit
width with the rail opening. Upright stair-step clearance increases from 80 to
96 units; the existing standing hull, solid floors, treads and no-jump upper
circulation remain. See validation/STAIR_HEADROOM_20260927.md for the failed
baseline, finite regression and native limits. Final aggregate results and exact
publication identity belong to the delivery receipt.

After verified publication, update the local install and walk a fresh stair up,
down and around its upper landing without crouching or jumping. This repair does
not accept SPOT-17 or any earlier native debt, start deferred roadmap work, or
authorize Workshop/VPS deployment. Earlier headers below remain historical.

---

# SPOT-17 source complete — spot queue complete; native acceptance next

Human Soldiers now use the AI Soldier's configured base speed (currently 140),
without ordinary sprint or grounded jump. Existing class/DEX/status/Haste and
directional effects remain; granted airborne movement feats remain off-commitment.
An accepted rifle attack roots voluntary movement through warning, all rounds and
actual cadence-adjusted recovery. Gravity/forced motion remain; current-life,
weapon, role and dungeon cancellation cannot carry a root into another body.
Dodge cannot reuse a pre-commitment motion sample. Heroes and AI retain their rules.

Live GDD 06/07 SPOT-17 delegated movement/tuning supplements were written and read
back before production changes. The existing source/attack/movement/control/Dodge
and client projection seams are reused. No recurring timer or movement owner added.
See validation/SPOT_17_MOVEMENT_GATE.md. The frozen contract retains all 93 earlier
selections plus two focused production tests (95 selected; 756 Lua syntax files).
Final local/independent results and publication identity belong to the external
receipt, not a pre-publication assumption. Native Source prediction/physics,
cooperative enemy readability and earlier acceptance debts remain open.

SPOT01–17 now have source implementations. After verified publication, the next
action is exact-build local gm_flatgrass acceptance, particularly Soldier movement,
rifle commitment and F3-to-Hero recovery. Use console_latest.txt and
rpg_summary_latest.txt plus a short observation; detailed session only for disputed
timing. No dedicated Razor retest. Preserve all previous approved work. No Workshop
or VPS action is authorized; retain local acceptance -> Workshop parity -> matching
VPS. Deferred roadmap work is not automatically authorized by completing this queue.
Earlier headers below are historical where superseded by this one.

---

# SPOT-16 source complete — SPOT-17 next after verified publication

Human Soldiers now receive an incarnation-bound Pulse Rifle with INFINITE ammo,
committed three-round baseline bursts and preserved burst/rate/aim authorities.
Zero clip/reserve works without cartridges, reload or a refill service. Stale
body/role/dungeon/weapon work cancels; Hero finite ammo and SPOT-15 lifecycle remain.
No Soldier movement, jumping or attack-rooting changes are included.

Live GDD 06/07 already contained the recovered SPOT-16 rules; no duplicate amendment.
Focused attempt 07 passes 988 server + 32 client assertions. The final frozen-source
contract is 93 selected suites (all prior 90 plus two focused suites and the existing
burst-cleanup regression), with 753 Lua syntax checks. Final local/independent
results and publication identity are supplied by the external delivery receipt.
See validation/SPOT_16_SOLDIER_RIFLE.md for honest attempt history and native limits.

After verified publication, implement only SPOT-17: Soldier committed-attack rooting
and movement restrictions approximating AI Soldiers. Reconcile the live GDD before
code; preserve readable, consistent enemies for human Heroes. No deferred roadmap,
Workshop publication or VPS restart is authorized. Preserve SPOT01–16, Float On at
1 Magic/s, B28/B29, approved Crate and P1–P4. Earlier sequencing below is historical
where superseded by this header.

---

# SPOT-15 source complete — SPOT-16 next

The author-directed Soldier F3 team menu is implemented. Live/waiting Soldiers can
return to the Hero queue or spectate only; the saved Hero, genuine death delay,
server authority and ordinary Hero choices are preserved. The actual revived Hero
spawn now uses the existing slot authority. Pre-closeout: 90/90 selected suites,
425 focused assertions and 751 Lua syntax checks. Final frozen-source and independent
publication facts belong to the delivery receipt. Native input/co-op/font/timing
acceptance remains open. See validation/SPOT_15_SOLDIER_MENU.md.

Next, implement only SPOT-16: human Soldier pulse rifle, three-round bursts and
infinite ammo in place of the SMG. Reconcile current main and relevant GDD before
code. Do not batch SPOT-17 movement restrictions or deferred roadmap work. Preserve
SPOT01–15, B28/B29, approved Crate, P1–P4 and local acceptance -> Workshop -> VPS.
No Workshop/VPS action authorized. Earlier sequencing below is historical where
superseded by this header.

---

# Active roadmap — author-directed spot updates

## Current checkpoint — SPOT-14 Time Management

Actual gameplay parent: `3b4df50fe001dd0dc7e2d7df9e3339a6bcceff13`.
Time Management is an ordinary, one-rank INT 17 cooperative-Hero feat. Living,
completed deployed holders add their positive effective INT modifier in minutes,
once per identity. The existing deadline gains or loses only the difference in
current party allowance. Death, disconnect and Soldier/spectator transitions remove
allowance; return restores it only before expiry. Hourglass time remains independent.
Same-dungeon internal build holds retain established non-growing allowance without
refunding elapsed time; real lifecycle losses still win. Old expiry precedes gains,
rescue and Hourglass debit. Rescue/new campaign reset to the ordinary paused clock.

[Implementation, raw attempts and limits](validation/SPOT_14_TIME_MANAGEMENT.md):
focused attempt 08 passed **258 production assertions**. The finite final contract is
**87 selected suites**, retaining all 85 SPOT13 selections and adding ordinary-clock
and SPOT14 integration tests. Exact final local/independent receipts and non-forced
child/tree/run belong in the external delivery receipt, not an unrun pre-publication
claim here. Live GDD 04/05/06/07, canonical manual and both generated readers align.
Native timing, co-op/rejoin, appearance/font and balance acceptance remain open.

**Next single bullet after verified publication: SPOT-15 — human Soldiers may open
the team menu with F3 at any time to return to the Hero queue or spectate, with a
visible hint.** Reconcile current role/queue/control/UI authority before code. Do not
implement SPOT16/17 or deferred roadmap in that checkpoint. Preserve SPOT01-14,
Float On at 1 Magic/s, B28/B29, Crate/P1-P4 and local acceptance -> Workshop parity
-> matching VPS. No Workshop/VPS operation is authorized.

## Previous checkpoint — SPOT-13 unread-update markers

Actual gameplay parent: `795dd444144e4e733dea58e56b4302bcb648f1ba`.
Character, Spellbook and Equipment now mark meaningful unseen updates with a
static exclamation above their existing navigation buttons. Inventory is the
bag inside Equipment, not a new page. First sync is quiet; only the exact updated
page's post-child paint acknowledges it. Sibling/loading/blocked/stale pages and
drag-deferred inventory cannot clear unseen content. Ordered snapshot envelopes
reject stale data; ordinary resync/floor changes preserve unread state, while
campaign/profile/life changes retire it. Routine resources remain quiet.

[Implementation, attempts and limits](validation/SPOT_13_UNREAD.md): final focused
production test **317 assertions passed**. The finite aggregate contract is **85
selected suites**, retaining all 83 SPOT-12 selections; final local/independent
results and verified non-forced child/tree/run are in the external delivery
receipt, not assumed from this pre-publication source document. Live GDD 06/07,
canonical manual and both generated readers align. Failed attempts remain raw.
Native rendering/font/network/co-op and full campaign acceptance remain open.

**Next single bullet after verified publication: SPOT-14 — Time Management,
prerequisite INT 17.** Reconcile exact time units, presence, stacking and
join/leave anti-exploit rules in the live GDD before dependent code. No SPOT14
implementation or deferred roadmap work belongs in SPOT13. Preserve SPOT01-12,
Float On at 1 Magic/s, B28/B29, Crate/P1-P4 and local acceptance -> Workshop parity
-> matching VPS. No Workshop/VPS operation is authorized.

## Previous checkpoint — SPOT-12 Spellbook availability surfaces

Actual gameplay parent: `8b2e936f83f9740f40082fd0c3d04dc3feafde01`.
Cards now tint their entire backdrop and border from the existing blue/red/gold/
muted availability state. Dark selection outlines and matching hover accents do
not mask warnings. Literal labels, costs, descriptions, Magic authority and all
configuration/casting rules remain; long descriptions use an existing small-font
fallback. Live GDD 06/07 and both canonical manual readers align.

[Evidence and limits](validation/SPOT_12_SPELLBOOK.md): **83/83 selected pre-closeout
suites, 1441 new focused assertions, 745 Lua syntax checks**, unchanged source;
minimum computed card-text contrast 5.119:1. All 79 SPOT-11 selections retained.
Final frozen local/independent hashes and non-forced main publication are in the
delivery receipt. The first focused width failure and interrupted 57-suite gate
remain honest incomplete/failed evidence. Native appearance/co-op acceptance and
the full campaign matrix are not claimed.

**Next single bullet: SPOT-13 — unread-update markers for Spellbook, Character
Sheet and Inventory, clearing only the corresponding viewed update.** Reconcile
live notification/snapshot ownership before code. Do not start SPOT14 or deferred
roadmap work here. Preserve Float On at 1 Magic/s, SPOT01-11, B28/B29, Crate/P1-P4
and local acceptance -> Workshop parity -> matching VPS. No deployment authorized.

## Previous checkpoint — SPOT-11 four-choice ordinary feat drafts

Actual gameplay parent: `85db2ed5ce287e7dbd96197676af4799922a6bf6`.
New ordinary hands target four distinct eligible offers, legal neutral fallbacks
only. Genuine smaller pools remain smaller; zero eligible choices are an explicit
resolved no-award slot, not a fabricated perk or staging soft-lock. Existing valid
stored hands, including legacy trios, retain their IDs/order/seed/result. Human
heroes choose once; AI/human Soldiers automatically consider the entire hand.
Capstone trios and Magic choices are unchanged. Four-card sheets use responsive
2x2 or single-column layouts. Live rules and both manual readers align.

[Evidence and limits](validation/SPOT_11_DRAFTS.md): pre-closeout **79/79 selected
suites, 1055 new focused assertions, 744 Lua syntax checks**, unchanged source.
All 72 D-J selections are retained. Final frozen local/independent identity and
verified non-forced publication belong in the delivery receipt. Earlier 71/72,
78/79, interrupted launches and focused fixture failures are preserved.
Native acceptance and the full campaign matrix are not claimed.

**Next single bullet: SPOT-12 — Spellbook card/backdrop availability colors.**
Reconcile live UI/accessibility law before code; do not start SPOT14 or deferred
roadmap work inside this checkpoint. Preserve Float On at 1 Magic/s and all
SPOT01-10, B28/B29, accepted Crate appearance, P1-P4 and release gates.
No Workshop or VPS operation is authorized.

## Previous checkpoint — SPOT-10 D–J approved and implemented

From actual main parent `7e2495ccfba3009f8190bd619ea229a8e65da094`.
Shael approved D–J, amending Float On to **1 Magic/second** for up to six seconds.
Arc Recovery 11; Feedback Loop 2/continuation, cap12; Recovery ceilings22/44/66%
at base rates1/1.5/2%MaxHP/s; ammo refill22/44/66%faster at unchanged floors;
Presence22/44/66%; aura fixed3seconds. Existing IDs/prerequisites, rejected A and
prior B/C/Mana Spring remain. Live GDD03/04/exact HUMAN and cards/manual align.

[Implementation and limits](validation/SPOT_10_SECOND_PASS_IMPLEMENTED.md):
**72/72 selected suites, 765 focused D–J assertions, 742 Lua syntax checks**,
unchanged source. All earlier64 selections retained. These are source gates,
not a full campaign matrix or native balance/control/co-op acceptance. Earlier
63/64 and71/72 attempts remain in the provenance record. Final frozen local/
independent identity and verified publication belong in the external receipt.

**Next independent bullet: SPOT-11 — four-choice feat drafts.** Reconcile live
draft law, eligibility/small pools, stored pending hands, authoritative one-choice
commit and UI before implementing. Do not begin SPOT12/SPOT14 or deferred work
inside this checkpoint. Preserve native/release gates; no Workshop/VPS operation.

## Previous checkpoint — SPOT-10 first approved corrections and second-pass review

From actual main parent `0b8321344737d11547f323c993b279de7c400d4f`.
A is rejected; its explosion ladder stays. B (fixed 3-second Mind Over Matter),
C (25% Frugal discount with existing map floor/Haste composition) and the author's
Mana Spring revision (flat 22% faster permitted passive regeneration) are implemented.
Live GDD 04/exact HUMAN rules, cards and both manual readers are aligned.

[Evidence](validation/SPOT_10_APPROVED.md): first local aggregate **64/64 selected
suites, 129 focused assertions, 741 Lua syntax checks**, unchanged source; retained
SPOT09 regressions, not the full campaign matrix. Final frozen local/independent
identity and verified publication belong in the delivery receipt. Native balance,
resource feel and co-op acceptance remain open.

**Next: author decisions on [second-pass proposals D–J](validation/SPOT_10_SECOND_PASS.md).**
These focus low-payoff effects, not relaxed prerequisite ladders; no comprehensive
personal pick-rate telemetry is claimed. D–J are not approved or implemented.
Do not fold SPOT11, SPOT14 or the deferred roadmap into this checkpoint.
Preserve all earlier native/release gates; no Workshop/VPS action.

## Previous checkpoint — SPOT-09 Damsel's Revenge

From actual main parent `9b89fdd2cfb1eed7d4d9cb1e172b5d02f44a2d86`.
One finite consumable arms the stationary jailed Damsel with a frozen procedural
Pistol, SMG or Pulse Rifle. Shared source-bound payment, canonical physical dice,
exact real-Gordon targeting, visible jail firing slit, encounter lifetime and
normal rescue authorize one owner-only at-feet gun pickup during existing victory.
No Hero ability/feat inheritance, Hector fire, new reward authority or free ammo.

The [finite gate](validation/SPOT_09_REVENGE_GATE.md) passes **477 focused numbered
assertions plus 512 seeded reward cases, 59/59 selected suites and 740 Lua syntax
checks**, unchanged source. See [implementation and limits](validation/SPOT_09_REVENGE.md)
and [preserved attempts](validation/SPOT_09_ATTEMPTS.txt). The first aggregate was
58/59 due to escaped-HTML test matching; that failure remains a failure. Final
frozen local/independent hashes and publication identity belong in the delivery
receipt. Native gun/port/animation/audio/pickup/co-op/performance acceptance remains
open; this is not a full campaign matrix. Manual and both renderings match.

Next single bullet: **SPOT-10 — evidence-backed feat proposals only**. Audit current
live design and implementation, identify obsolete/weak/redundant feats and present
specific changes with rationale and tests for Shael's approval. Do not implement
any rebalance without explicit approval by proposal. Do not fold SPOT-11 four-choice
drafts or SPOT-14 Time Management into this audit. Preserve SPOT-01–09, B28/B29,
accepted Crate appearance and P1–P4. No Workshop or VPS actions.

## Previous checkpoint — SPOT-08 Gordon arena turrets

From actual main parent `35c43bc8bac86e5ea108b9f96e9d5ab6a94bf542`.
Cumulative ordinary Sentry corner turrets at D5/10/15/20, capped at four with
ordinary monster progression thereafter. Separately seeded corners, one safe
admission attempt per slot, no delayed fallback/replacement/respawn. Exact-cell
native hull/support and stair/gallery checks preserve arrival and routes. Shared
96-hostile, 64-roamer, 64-projectile and 16-Gordon-hazard ceilings remain.

Production EnemyRoster owns fixed warned physical fire, bounded captured Hero
lives and guarded native damage. Exact owner/run/life retirement prevents stale
shots across wipes, rebuilds, co-op replacement and Gordon-to-Hector handoff.
Native body removal occurs outside the lethal stack, explicitly before Hector's
reveal. No SPOT-06/07, boss progression, reward or feat-balance changes.

The [predefined finite gate](validation/SPOT_08_TURRETS_GATE.md) first passed
**250 focused assertions, 52/52 selected suites and 736 Lua syntax checks** on
unchanged source. See [implementation and limits](validation/SPOT_08_TURRETS.md)
and [preserved failures](validation/SPOT_08_ATTEMPTS.txt). Final frozen local and
independent hashes, published child/parent/tree and run ID are in the delivery
receipt. Manual and renderings match. This is not full campaign-matrix or native
collision/visual/audio/co-op/performance acceptance. No Workshop/VPS actions.

Historical next action at SPOT-08 close-out: **SPOT-09 — Damsel's Revenge consumable**. Read the exact
queue request and reconcile its item grant/use, jailed Damsel gun/combat, Gordon
ownership, co-op, rescue drop and cleanup contract in the live GDD before code.
Do not fold existing-feat rebalances into it. Preserve SPOT-01–08 and B28/B29.

## Previous checkpoint — SPOT-07 Fake Gordon tells

From actual main parent `c9ddf8cb7d1952ce831d2fdb361c4092ebb85f7d`.
Only a living deployed Hero with positive canonical Wisdom receives private,
short-lived fake recognition within half the Wisdom bonus in squares. Fractional
3D distance and clear sight govern wink/tongue/tint and shared-stun-bound recoil.
Global fake-name/ordinal labels are removed; optional fart is omitted. No shared
control/damage/HP change or extension of SPOT-06's fixed follow-up is introduced.

The [predefined finite gate](validation/SPOT_07_TELLS_GATE.md) first passed
**130 focused production assertions, 50/50 selected suites and 734 Lua syntax
checks**, unchanged source. Final frozen-tree local/independent source checks,
publication SHA/parent/tree and run ID belong in the delivery receipt. Canonical
manual and both renderings are synchronized. See [validation](validation/SPOT_07_TELLS.md)
and preserved attempt provenance; this is not full campaign-matrix or native
visual/co-op/performance acceptance. No Workshop/VPS actions.

Next single development bullet: **SPOT-08 — Gordon arena turrets**. Reconcile the
author's every-five-dungeon-level scaling/corner occupancy in the live GDD before
code. Do not begin SPOT-09 or existing-feat rebalances in that checkpoint. Preserve
SPOT-01–07, B28/B29, accepted Crate appearance, P1–P4 and all native/release gates.

## Previous checkpoint — SPOT-06 Gordon phase one

Recovered from the stalled SPOT-06 thread on September 26, 2026, from exact
published parent `664762a55d096c628ed5a2faff6da6c97c16cf03`, tree
`9faba937d888b33079719aa9b20d719fc01fbbd7`. A full tracked-file source snapshot
and original Git commit were verified before editing. The stalled thread's live
GDD 05/07 candidate design was already present and is preserved.

Phase one now owns a fixed 1.2-second first-effective-visible-hit opportunity,
never refreshed and bounded by reveal+4.0 seconds. Released ordnance keeps its
fuse; unreleased shots cancel. The existing Warden service enforces deadlines
outside stunned AI wrappers. Invisible physical travel, fixed .45-second
arrival/departure cues, displacement rewarning and the .65-second ordinary attack
warning replace ambiguous disappearance. Short contextual taunts share a
6-second encounter cooldown and require ordinary attack appearances between them.
Shared controls and all later phases/progression remain authoritative.

The finite [gate](validation/SPOT_06_GORDON_GATE.md) was defined before code.
Local source validation: **116/116 focused production assertions, 47/47 selected
suites and 733 Lua-file syntax checks**; no source mutation during the gate.
The exact frozen candidate is independently gated before publication; published
parent/tree/SHA and the independent run belong in the delivery receipt, not a
self-referential source-file hash. See [validation](validation/SPOT_06_GORDON.md)
for attempts, limits and the native checklist. This is not a full campaign matrix
or native timing, rendering, audio, collision or cooperative acceptance.

Next single development bullet: **SPOT-07 — Fake Gordon tells**. Do not fold
SPOT-08 turrets, SPOT-09 Damsel's Revenge or existing-feat rebalances into it.
No Workshop/VPS operation or native force-spawn test is part of SPOT-06.

## Previous checkpoint — SPOT-05 canonical Die Logger audit

The September 25 author-directed [spot queue](briefs/SPOT_UPDATES.md) precedes the
scheduled roadmap. One bullet equals one independently validated, non-forced
push. High-level design authority is delegated; existing-feat rebalances remain
approval-gated. SPOT-05 changes presentation/event reporting, not gameplay balance.

The canonical server stream now removes routine passive Magic/full-cap noise,
restores omitted defense/status/duration/recovery/Morale/HP-growth dice and
meaningful outcomes, and uses one event serial for the union of combat
participants and eligible nearby listeners. Private progression remains private.
Life observers bind exact Hero/run ownership; human Soldiers do not display the
dormant Hero name. Both client views retain identical semantic records and order,
with bounded history and ordered long-dice parts. The GDD's explicit passive-Magic
exception and the canonical manual are reconciled.

Final local evidence: **76/76 focused assertions, 38/38 selected suites,
732 Lua-file syntax**, including manual content/transport and unchanged source
during the gate. Its frozen-tree independent result and published child SHA
belong to the delivery receipt. See [SPOT-05 validation](validation/SPOT_05_DIE_LOGGER.md), the stored
receipt and preserved initial attempts. This is not a full campaign-matrix pass
or native rendering/multiplayer acceptance. B29 uses its recorded-layout runtime
mode; the extra 20-seed exposure sweep is not claimed.

SPOT-04 audio remains implemented and native-unaccepted. Its historical gate is
227 passing suites, one unchanged-parent Color-fixture failure and two omitted
campaign suites, not a full 230-suite pass. Fresh SPOT-05 regressions pass
SPOT-04 74/74, Razor 55/55 and Climber 44/44; the separate SPOT-01 50-check result
is inherited from SPOT-04. Earlier validation records are not rewritten.

Shael's one controlled Razor proves only that instance's visibility/basic combat.
Its Occupation/60-roamer upload was developer-dense, not natural release exposure.
**No dedicated Razor retest or natural sighting is prerequisite.** Collect natural
sightings opportunistically; keep the documented native limits and provenance.

## Existing release gates — unchanged

Preserve B28 physical-query repairs, B29 safe arrival/graduated opening,
author-approved Crate visuals, and completed P1–P4 optimization/evidence.
B29's historical 42 selected headless passes remain distinct from the fresh
integration results recorded above and from native acceptance. Its safe-arrival,
controlled-departure and inhabited-exploration native checks remain open.

The established sequence remains focused fatal-crash/game-ending-bug repairs,
local playtest/acceptance of the exact candidate, Steam Workshop item 3791535712
publication with package/source parity, then matching VPS deployment with backup,
rollback and service/listing/connectivity checks. This commit does not publish
the Workshop or change/restart the VPS. Obtain local evidence before those gates.

## Scheduled work — unchanged

| Order | Deferred work | Preserved scope |
| --- | --- | --- |
| 1 | Low-End PC Optimization, September 28–October 4, 2026 | Preserve P1–P4; resume measured active-scan profiling. Native dense frame-time/texture-residency acceptance remains pending. |
| 2 | [Big Loot](briefs/BIG_LOOT_UPDATE.md) | Existing meaningful baseline/approximately 3.5× target; preserve inventory, persistence, sell/fuse and wallet transactions. |
| 3 | [Event System](briefs/EVENT_SYSTEM_UPDATE.md) | Existing meaningful baseline/approximately 3.5× target; preserve exactly non-exploding 1d4 count, deterministic ownership, placement and solvability. |
| 4 | Comprehensive systems integration and emergence audit | Generation through encounters, combat/status, equipment/loot, events/rewards, progression/lifecycle/UI; deterministic, transaction and interaction contracts. |

## Checkpoint practice and preserved history

Read AGENTS → this current section → active brief; live GDD 00 → 01 → relevant
subsystem rules only. State the finite scope, implement at the existing authority,
run targeted checks and the available applicable integration gate, and distinguish
fresh, inherited and unavailable validation. Normally the canonical gate is
`python3 tools/test_checkpoint_g_integration.py`. Never substitute a headless pass
for native acceptance. Update player guidance, live GDD, evidence and handoff;
verify pushed source hashes and preserve newer/uncommitted work without force.

The entire previous development plan, including all historical acceptance records,
Crate constraints, detailed roadmap and checkpoint policies, is retained byte for
byte as [the B29 plan archive](history/DEVELOPMENT_PLAN_B29_20f6ecc.md). Only its
old active-queue precedence is superseded by the new author request. Historical
relative paths in that verbatim archive retain their original `docs/` context.
