# Damsel progression and audio — September 19, 2026

Implementation follows the current author request, which supersedes the earlier
repeat-Deborah loop. Campaign/process persistence remains unchanged: each new
campaign starts at Level 1. Wallet SQLite persists across reconnects/process
restarts; no second campaign save format was introduced.

## Campaign and services

`sh_damsels.lua` owns the ordered roster, family, model, palette policy, idle,
dialogue, reward frequency and authored staging placement. RunManager owns the
explicit damsel/cash target, rescued set, highest level and recovered cash count.
Level, minimap and topology identity transport use doubles so the old 20-bit
level field cannot wrap during endless play. The old numeric objective stages
and entity classname remain compatible with
existing maze/debug consumers; level clear validates the exact current entity.

| Levels | Family / names | Services in order |
|---|---|---|
| 1–4 | Nessa, Bessa, Tessa, Odessa | Pistol, SMG, Shotgun, .357 refill |
| 5–8 | Nell, Belle, Estelle, Mirabelle | AR2 refill, +25 HP, cure, +25 Magic |
| 9–12 | May, Faye, Kay, Desiree | Generated gloves, ring, boots, headwear |
| 13–16 | Jean, Colleen, Maureen, Josephine | Generated vest, trousers, shield, Healing Potion |
| 17–19 | Dora, Cora, Eleonora | Full heal, 25–75 Debs, restore one reserve life |
| 20 | Deborah (no family) | Abundance |
| 21+ | Stolen cash case with floating dollar marker | Ordinary dungeon completion and economy settlement |

Restoratives/ammunition/potion refresh once per dungeon visit. Gear, Debs and
reserve life are once per player identity per campaign. Unusable gifts do not
consume the claim. Gear uses the existing procedural generator and carries
`economyExcluded`; it may be discarded, but cannot circulate through resale or
fusion. Ammo services use a strict family option on the existing capped grant.

Abundance is one DFT per eligible ranked Hero account per rolling 86,400 seconds.
It uses the existing SQLite account/ledger transaction, an optional validated
`abundanceClaimAt`, existing eight-token capacity and unchanged DFT recreation
provenance. Full wallets and failed storage commits do not consume the claim.
There is no client-controlled timestamp or grant request. Unranked debug
campaigns cannot mint persistent currency or DFTs.

Palette seeds derive from campaign seed and family. Clothing gets a constrained
HSV palette; a complementary enamel accent avoids tinting combined face/hair
textures. Levels 17–20 retain default appearances, including Deborah’s configured
canonical model. Staging actors are separately owned, invulnerable, nonblocking,
and retained through ordinary level builds. Deterministic perimeter placement
avoids decor and other actors, including a tested compact 400 × 260 room. Names appear only near the actor being viewed.
E uses a server distance/aim/occlusion check, with native Use as a second entry.
The short Source-styled panel contains a live face portrait, name and receipt.

After the Level 20 rescue, Gordon’s brief letter appears upon entering Level 21,
once per campaign player state. Levels never reset at that transition. Existing
actor caps and entity ceilings remain; post-20 reinforcement cadence, specialist
weight and attack recovery increase asymptotically. Highest level ranks new
Heroes of Legend records; old records retain readable legacy completion counts.

## Audio

`sh_audio.lua` defines 56 semantic cues, generated reproducibly by
`tools/generate_feedback_audio.py`. These original 22.05 kHz mono PCM files total
under 500 KB, with consistent RMS and no clipping. Hit confirmation is one 45 ms
note. Spatial Awareness has a separate octave gesture. Loot appearance and
pickup have distinct intervals; UI, statuses, casting, portal phases and other
feedback have separate identities. Existing discovery/progression stingers stay.

Generation/cleanup barriers suppress `EntityEmitSound` on server and client, and
suppress the semantic dispatcher. The client starts muted until the authoritative
finished-state flag arrives. A serial protects the deferred release from stale
build callbacks. Completed staging releases without a startup confirmation cue.
Admin cleanup releases after removal callbacks settle. Death’s old administrative
pulse/jingle is removed; real creature death voices remain. Loot feedback is
recipient-local and coalesced, never emitted once per replicated loot copy.

The call-site audit covered gamemode entities/modules and `lua/autorun`, including
the portal’s delayed button-beep sequence. Weapons, footsteps, physical impacts,
creature voices, machinery/portal world sounds and magical world attacks remain.
All native loops use the existing strong-owner lease manager; generation changes
stop leases, near-equal owners cannot churn the same loop, and group gain is
bounded even when several nearby sources qualify. Delayed status replication
establishes a silent baseline instead of replaying all status onsets.

## Other repairs

- Inventory management has a separate staging eligibility rule. Combat activation
  stays gated; owned equipment/weapon changes work after statue recreation.
- Poison context and native `DMG_POISON` bypass Arcane Diversion without spending
  Magic. Ordinary non-Poison diversion is unchanged.
- Climber lanes account for the full 128-unit container thickness plus hull
  clearance. Lane candidates are traced, connectors use open-cell centers, and
  native velocity is stopped before scripted wall movement.
- Arc Casters travel during recovery when outside their close stand-off radius.
  Beam Sweepers remain stationary lane-control enemies, as specified in the GDD.
- Nodule hit bounds derive from the same inverted Barnacle body and visible size;
  changes in size update the native box and shared firearm combat volume.
- Player-allied summon actors use a solid gold material/color.

## Validation and finite native playtest

September 19 automated result: `python3 tools/test_checkpoint_g_integration.py`
passes all 120 suites with zero failures. `git diff --check` is clean. The focused
checks caught and repaired cross-family ammo fallback and insufficient compact
staging capacity before the final gate.

Automated checks execute real completion/advance/build through Levels 1–26,
large-level pressure bounds, reset, all 20 staging placements, E interaction,
late-join state, single letter, portrait panel construction, actual reward
handlers and SQLite rollback/reopen/24-hour/capacity behavior. Enemy and Poison
regressions exercise the repaired authorities. Audio tests cover both realms,
initial silence, failed/stale builds, cleanup release, recipient coalescing,
diegetic pass-through and every packaged WAV. The 120-suite integrated gate includes these
checks; native Source rendering/audio/physics remain a separate runtime gate.

For a short **unranked developer** playtest, use `lod_damsel_test_stage 1`, then
`20`, `21`, and `25`. This builds the chosen dungeon and the preceding rescued
roster using the ordinary builder. `lod_damsel_status` prints target, roster,
highest level and cash count. The existing chamber teleport accepts `rescue` and
`cash` as well as its legacy `deborah` alias. Use normal objective gates to clear.

Check initial loading and each rebuild are silent; walk, fire and use menus after
release. Inspect the full staging room and stock final-four models, talk with E,
check multiple clients/late join, then finish Level 20 and observe the letter and
cash objective. Inspect Climber corners, Arc Caster recovery, Nodule shot edges,
gold summons and overlapping gas/Watcher/fuse loops. Daily DFT grant requires an
actual eligible ranked campaign; debug staging deliberately cannot mint it.
Record the candidate commit/install identity and use the existing test logging
workflow. These changes are a playtest candidate, not a claim of native runtime
acceptance.
