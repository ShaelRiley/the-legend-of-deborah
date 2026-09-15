# Soldier lethal-hit investigation and wallet repair

Candidate branch: `astra/equipment-update`, based on remote
`de8aca6ac3390e88aa6ed5430d873acc01cd2cc0`. Remote `main` remains
`8978796e886cdb5505d24ed0de085265fa99bac8`.
This is a repair/diagnostic candidate, **not a confirmed native-crash fix**.

## Runtime evidence

The author reported an immediate Garry's Mod forced close when a Raw magic
projectile contacted a Soldier. The full uploaded session contains later events
than the periodic summary and upload copies:

| Sequence | Session time | Observed event |
| --- | --- | --- |
| 136 | 90.585 | Fighter casts Raw **Bolt**, spending 15 Magic. |
| 139 | 90.810 | Bolt resolves 13.2 damage against Soldier #1167 at 18 HP. |
| 144–147 | 90.825 | Client receives and draws morale/damage feedback. |
| 148 | 92.160 | Player rolls an AR2 hit. |
| 149–152 | 92.160 | AR2 resolves 19.665 damage against the same Soldier at 5 HP; last event is `DAMAGE_APPLIED`, damage type 4098. |

The source `rpg_test_session(20260915-114131).txt` and rolling
`rpg_test_log(20260915-114134).txt` end at sequence 152. The summary, session
upload copy and archive upload copy stop at sequence 147. No XP settlement,
native crash stack, Lua traceback or orderly shutdown follows the lethal hit.
The session identifies gm_flatgrass, singleplayer, engine build
`2026.05.08 (10029)`; it does not identify an exact game-code commit.

Despite its historical name, `DAMAGE_APPLIED` is emitted from the Lua
`GM.EntityTakeDamage` wrapper, **before native damage/death processing**. It does
not establish that Source completed the hit. The last recorded lethal hit is
therefore a stronger lead than the successful Bolt's visual effect. Bolt does
not use the new filled-area renderer. The files cannot establish which native
function crashed, nor exclude a delayed client fault. No effect rollback or
unrelated addon blame is justified by this evidence.

Evidence fingerprints (SHA-256, uploaded originals retained by the author):

- Full session: `565b04423c89f300987bc38e180c43950d4b491c18359ef3c5eb6ed74afe5262`
- Console: `4cf1a06d40ef4f2c9b860f2c12232c1e2222717c3ebd3856a49f942ecd671fe9`
- Summary: `114548848a86363d2a1ee02af888898e2aacd80a871f6dc85dcdf4187faadd52`

## Changes

1. **Confirmed wallet defect:** the console repeatedly reports SQLite
   `unrecognized token: "{"`. `encode` returned `assert(json, message)`, whose
   second return accidentally supplied the optional `bNoQuotes` argument to
   [`sql.SQLStr`](https://wiki.facepunch.com/gmod/sql.SQLStr). Return only the JSON
   string. Accounts, ledger and history retain their existing schema and data.
   The SQLite test double now honors that second argument: the unchanged
   production store failed with `storage`, and the repaired store passes the
   real-SQLite transaction, rollback, reconnect and DFT tests. This is a proven
   persistence fix, not evidence that SQLite caused the forced close.
2. **Death-path hardening:** claim the logical death before extension callbacks,
   making repeated/reentrant death calls no-ops. Keep encounter and XP hooks
   synchronous. Queue native corpse collision, movement, weapon-visual removal
   and animation changes for the existing shared scheduler after the damage
   callback unwinds. Do not retain `DamageInfo` beyond that callback. Preserve
   the one-second blink, loot conversion and original level seed; discard removed
   entities safely. This addresses a risky lifecycle boundary, but its connection
   to this crash remains unproven.
3. **Bounded diagnostics:** `HOSTILE_DEATH_STAGE` records callback entry,
   encounter completion, kill-hook completion, presentation entry/readiness and
   loot entry/completion through the existing developer logger. Add the explicit
   `pre_engine_apply` phase to the historical damage event. No per-frame logging
   or new per-enemy recurring timer is introduced.

The live GDD navigation was 00 → 01 → normalized 03 and 06. No design changes
were required. Preserve current Equipment, HUD face placement, Magic areas,
rear Deborah statue, Wizard balance and wallet/DFT rules.

## Validation and next gate

All **76 integrated automated suites pass**, including Lua syntax and the new
production-hostile lifecycle harness. That harness checks deferred native
mutations, synchronous single kill credit under reentry, one corpse/drop,
removed-entity cleanup, simultaneous deaths using one scheduler, and old-level
loot isolation. Source and the user's native crash were not reproduced here.

Fresh-start Garry's Mod on gm_flatgrass. Repeat the short sequence: hit a Soldier
with Raw Bolt, then finish it with the AR2. The finite gate is survival through
the lethal hit, exactly one kill/XP settlement, normal corpse/loot completion,
and no wallet SQL errors. This is the next runtime action; broader feature
acceptance remains pending.

On success, finish logging normally and send `console_latest.txt` plus
`rpg_summary_latest.txt`. On another hard close, preserve the files **before
relaunching** and send `console_latest.txt` plus the source
`rpg_test_session.txt` from `garrysmod/data/legend_of_deborah/`; periodic
`*_latest` copies can miss the final events. Include a native crash dump if one
was produced. Do not reset wallet data or broaden manual testing first.
