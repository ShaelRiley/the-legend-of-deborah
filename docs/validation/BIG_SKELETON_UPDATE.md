# Big Skeleton source validation

Base: `f0b7a66d0e87c18ad18b45a6449b613b7f8ee11d`, canonical `main`.
User explicitly authorized skeleton design and implementation. Live GDD
00 → 01 → 05/06/07 was read; its guarded write returned HTTP 400
`FAILED_PRECONDITION` and fresh readback retained the same revision. Final
proposed text is `BIG_SKELETON_GDD_AMENDMENTS.json`; no successful GDD write is
claimed.

## Finite automated gate

`python3 tools/test_big_skeleton_update.py --workers 4 --output <new external evidence directory>`

**52/52 targeted suites passed; 798 Lua files passed syntax.** Source remained
unchanged during the matrix. This is the bounded skeleton/shared-authority
regression gate, not a new run of the entire repository matrix.

Matrix source digest before/after:
`72a85c5066397c209b7f60ab44d6421637736e822e01888573361671c5131c9b`.
Exact commands, return codes and individual log digests:
`big_skeleton/matrix_receipt.json`. Full logs and the pre-gate source manifest:
`big_skeleton/automated_evidence.tar.gz`.

Coverage includes all existing Skeleton generation/barrier/death/reward gates;
full current event-catalog creation, ecology and progression proofs; copied
Hero/Soldier snapshot, independent lifetime and shared Pistol/Crowbar/Shotgun/
AR2/Beam combat; finite Hero resources, Soldier unlimited rifle and hostile
summon allegiance; canonical accepted-death capture before role retirement;
duplicate/stale graph/pause/disconnect handling; shared faction, equipment,
Magic, Wall, Super Ball, Watermelon, Wand, death scheduler and player manual.

The final review added source rechecks after damage-roll observers and death
notices, attack-status checks at actual firearm release and shared form-class
eligibility. The final copied-combat test exercises world replacement during a
real roll. It and the full syntax audit pass again after those changes; see
`big_skeleton/final_checks.json`. Only the fallen-player module and its test
changed executable behavior after the 52-suite matrix.

## Observed samples

- 64 campaigns × 20 populated dungeons: 228/1280 Skeleton selections before,
  833/1280 after (17.8% → 65.1%); longest absence two.
- Twenty full-catalog natural builds succeed; sixteen create both a Skeleton
  and its required barrier. Independent all-closed approach and ordered
  key/boss/rescue proofs pass. Bribe is absent.
- Exact d4 count, distinct identities, the rare fourth slot and deterministic
  selection are preserved. All 28 current events remain exposed by the larger
  existing ecology sample.
- The ecology repeat check explicitly excludes the now intentionally frequent
  Skeleton from its former >50% repeat-reduction requirement. Raw aggregate
  repeat counts remain reported; other identities still satisfy the original
  >50% reduction bound. This is the requested frequency change, not a silent
  weakening of unrelated novelty constraints.

## Failed preparation evidence

`frequency_test_02.log` records a harness failure: an independently predicted
selection used a different ecology context from the actual full builder. The
corrected test inspects the actual successful plan and native resource ownership
on all twenty builds. It does not relax the resource/progression assertions.
Earlier fixture-only bring-up exposed entity deep-copy/RNG-double boundaries;
those were corrected before the retained passing combat tests. The final
matrix has no failing suites. Retained available preparation logs are included
in the evidence archive.

## Native acceptance remains open

These are production-Lua tests with native entities, traces and transport
doubled. They do not prove Source model/animation/collision, multiplayer spell
presentation, balance, large-party performance or complete AI use of every
player-input-only action. The copied build is exact; the AI policy is described
explicitly in `../BIG_SKELETON_UPDATE.md`.

First local action on the exact published source and `gm_flatgrass`:
`lod_developer_mode 1; lod_event_preview_generate skeleton_blockade`.
Follow the finite native gate in that implementation note, retaining prior
accepted behavior. Evidence: `console_latest.txt` + `rpg_summary_latest.txt`.
Workshop and VPS deployment remain separate, after local acceptance.
