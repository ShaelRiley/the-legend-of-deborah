# Current Development Plan — Integrated RPG Completion

**Status:** CURRENT EXECUTION AUTHORITY for sequencing. Historical gate/batch plans are subordinate evidence only.

**Repository:** `ShaelRiley/the-legend-of-deborah`  
**Branch:** `main`  
**Reconciled starting HEAD:** `442c5e57fc532bef865b9d589a30ff409dfa6fbf`  
**Required runtime map:** `gm_flatgrass`

**Design authority:** live Google Doc **The Legend of Deborah — Garry's Mod Game Design Document**, ID `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.

## Mandatory GDD navigation

Do **not** read the full human GDD to orient development. Use the document's normalized AI interface:

`00 — AI ENTRYPOINT` → `01 — AI RULE INDEX` → only the relevant subsystem tab → one exact `HUMAN — Complete GDD` anchor/featId only when the normalized tab marks something `HUMAN-DETAIL`.

The normalized AI tabs are authoritative where they explicitly cover a rule. The human tab remains the complete author-facing design and exact-detail fallback. Never substitute an old GDD export, this plan, `RPG_GDD_RULES_BASELINE.md`, the feat matrix, or remembered chat text for the live GDD.

## Program decision

The former strategy of implementing and runtime-testing one ordinary feat family at a time is **superseded for the current tranche**.

The remaining work shares too many authorities—actor Levels, automatic AI progression, statuses, elements, Magic, feat eligibility/effects, Soldier progression, and UI state—to complete efficiently as dozens of isolated runtime cycles. The current objective is therefore one **integrated RPG-completion update**, divided into internally coherent checkpoint commits.

Each checkpoint must be statically validated and pushed as soon as it is coherent. Do not spend scarce autonomous compute holding finished work uncommitted. Runtime acceptance of the integrated tranche occurs after the system is complete enough for one substantial play pass, except when a local automated engine test is required to diagnose a blocker.

Previously runtime-accepted mechanics remain regression constraints unless the live GDD explicitly supersedes them.

## Reconciled implementation baseline

Current `main` already contains substantial RPG scaffolding and many accepted feat bridges. Do not rewrite it from scratch. Extend existing authorities.

Confirmed gaps/mismatches at the reconciled starting HEAD include:

- `sh_rpg_schema.lua` still uses one global `MaxLevel = 20`; the live GDD requires Hero hard cap 20, monster hard cap 999, and the universal dungeon-relative ceiling `DungeonLevel + 3`.
- the schema still gives Wizard Hero progression `d6`; canonical Wizard progression is **d4**.
- `sv_character_progression.lua` is fundamentally Hero/Level-20 oriented. Existing Hero `4d6-drop-lowest` generation is correctly supplied by `sv_hero_ability_rolls.lua`; preserve that working behavior while consolidating only when safe.
- `sv_rpg_gate_d.lua` already provides shared derived-stat and combat-attribution consumers and reads non-player `actor.LODProgressionState`, but production enemy RPG-state generation is not complete and enemy XP valuation still clamps enemy Level to 20.
- modular six-Form/six-Content Magic is incomplete.
- there is no complete shared current-status/element implementation for all authored proc families.
- the feat inventory is materially incomplete; the 2026-09-08 matrix measured 62/143 ordinary definitions at its checkpoint. Use the matrix as an implementation inventory, **not** as design authority.
- human-controlled Soldier RPG/lifecycle implementation is incomplete.
- the current-required durable server-local `HEROES OF LEGEND` staging leaderboard is not complete.

Do not implement the old doubled-Hero-XP plan. The current canonical Hero cumulative XP table ends at **48,000 XP for Level 20**. Do not reopen the former five-versus-six Form question: the canonical catalog contains **six Forms**.

## Protected high-frequency rules

These are navigation aids, not substitutes for the live normalized tabs:

- Monster/Soldier ordinary spawn tier: 60% Typical=`D`, 30% Elite=`D+1`, 10% Champion=`D+2`, where `D=max(1,DungeonLevel)`.
- Universal entity ceiling: `D+3`; Hero hard cap 20; monster hard cap 999.
- Neil=`D`, Brute=`D+1`, Gordon=`D+2` as fixed authored tiers.
- Monsters continue numeric growth above 20 but gain no new feats, Forms, Contents, class milestones, or capstones above 20.
- Wizard Hero progression hit die=`d4`; Soldier progression hit die=`d8` regardless of automatically assigned class.
- Human Soldiers are generated exactly like AI Soldiers; human control uniquely adds incarnation-local XP. Thresholds: 100/250/450 SoldierXP for +1/+2/+3 earned levels, always clamped to `D+3`.
- Human Soldier level-up choices are automatic through the same deterministic AI selection authority. No new choice UI.
- Magic catalog: six Forms and six class-neutral Contents.
- ordinary feat cadence: Levels 1/3/6/9/12/15/18; Level 20 adds one separate class capstone. Former Rogue bonus drafts are retired.
- `HeroOfLegendHPThreshold=min(100,MaxHP)`.
- server-local staging `HEROES OF LEGEND` leaderboard is CURRENT REQUIRED; global Steam mirror is deferred.

If any of these conflict with a newer explicit user direction or a newer live normalized GDD rule, the newer authority wins.

# Integrated RPG Completion Checkpoints

## Checkpoint A — Canonical actor Level/progression core

**Goal:** one actor-aware Level authority for Heroes, AI monsters, and human Soldiers.

Implement together, not as isolated constant edits:

1. Split Hero and monster hard caps and enforce the universal `D+3` ceiling.
2. Preserve Hero 0–48,000 XP progression and add banked-XP behavior behind the dungeon-relative Hero ceiling.
3. Change Wizard Hero progression hit die to d4.
4. Extend monster numeric growth beyond Level 20 through the canonical recurring growth schedule; no new feats/Forms/Contents/milestones/capstones above 20.
5. Create one production monster RPG-state producer that assigns level/tier, class, growth profile, abilities, stored HP dice, feats and other legal state deterministically. Attach it through `LODProgressionState` rather than adding parallel per-enemy RPG logic.
6. Apply the 60/30/10 tier rule to ordinary monsters and Soldiers, with fixed Neil/Brute/Gordon tiers.
7. Remove Level-20 clamping from monster XP valuation and other monster-only Level consumers while preserving Hero hard-cap behavior.
8. Add/extend finite static validators for Hero caps/banking, D/D+1/D+2 tier assignment, D+3 clamp, deterministic replay, and Level-21+ monster growth with no post-20 feat grants.

**Checkpoint gate:** existing Hero progression regressions pass; deterministic actor validator passes; production consumers can retrieve correct Hero and AI progression state. Commit and push immediately.

## Checkpoint B — Shared status, element and Morale authority

**Goal:** make every current authored status/element interaction run through shared event-driven authorities.

1. Implement one status registry/resolver rather than one Think hook per feat.
2. Implement current named conditions and all status families required by exact current feat definitions, including at minimum Immolated, Poisoned, Held, Muted and Morale/Intimidated plus the exact authored bleed/clumsy/reckless/arcane families where the live feat rows require them.
3. Preserve each status's exact save, duration, immunity, cooldown, reapplication and non-stacking law from the live GDD.
4. Implement elemental resolution for Earth/Fire/Dark/Ice/Light/Electric at the existing shared combat pipeline. A typed hit resolves at most one applicable weakness/resistance table under current rules.
5. Preserve canonical order: damage first → final effective HP damage and survival check → at most one legitimate rider attempt → save/duration/cooldown. Do not create recursive proc chains from status tick damage unless explicitly authored.
6. Wire event-driven Morale through existing hostile movement/target authorities; do not create a second AI controller.
7. Add a finite matrix validator proving every current element and status family can resolve and that invalid/immune/duplicate cases do not proc.

**Checkpoint gate:** shared status/element matrix passes plus existing combat/push/dice regressions. Commit and push immediately.

## Checkpoint C — Six-Form / six-Content Magic

**Goal:** complete modular current Magic on the existing personal 100-Magic authority.

1. Implement all six Forms: Blast, Beam, Bomb, Missile, Bolt, Summon.
2. Implement RAW + all six Contents: Earth, Fire, Dark, Ice, Light, Electric.
3. Content ownership/use is class-neutral. Wizard specialization is quantity/passives, not exclusive permission.
4. Preserve Magic capacity=100, INT regeneration authority, WIS power/utility scaling, map-open regen suppression, Arcane Shield/Feedback and existing Wizard rules.
5. Compose existing Quantum/offensive-cost and other accepted Magic feat helpers at the canonical cost seam rather than duplicating cost logic.
6. Use the existing Seeker authority for Summon wherever the authored behavior permits; do not fork a parallel allied-monster implementation.
7. Complete I Spellbook state/UI for six Forms and RAW+owned Contents; preserve P/I mutual exclusion.
8. Add deterministic Form/Content progression ownership without replacement at the exact live milestones.

**Checkpoint gate:** each Form casts through the shared pipeline, each Content resolves through the shared element/status authority, ownership/progression is deterministic, and existing Wizard/Quantum regressions pass. Commit and push immediately.

## Checkpoint D — Complete current feat/capstone mechanics by shared handler families

**Goal:** close the canonical feat inventory without returning to dozens of player-facing micro-gates.

1. Re-enumerate the exact current live feat catalog by `featId` only as needed; use the 2026-09-08 matrix as a missing/present starting inventory, not current design text.
2. Preserve already accepted mechanics unless superseded.
3. Add missing definitions and effects grouped by shared handlers: status-proc families, movement, size/body, Magic, summon/control, identity/utility, weapon/combat and other actual seams.
4. Hero ordinary drafts remain stored three-card choices. AI and human Soldiers use the same eligibility/offer construction but deterministic automatic synergy selection.
5. Enforce current prerequisites, capability tags, allowed actor types, exclusions, replacement ranks, no-Rogue-bonus-drafts rule, and Level-20 capstone behavior.
6. Ensure monster Levels above 20 never create additional feat slots.
7. Extend one registry/mechanics validator to prove every canonical feat ID is present exactly once and every non-passive effect has a registered reachable handler or explicit data-driven consumer.

**Checkpoint gate:** canonical feat-set equality, prerequisite/capability validation, automatic AI selection validation and existing accepted feat regressions all pass. Commit and push immediately.

## Checkpoint E — Human Soldier RPG and lifecycle integration

**Goal:** human-controlled Soldiers differ from AI Soldiers only by player control and incarnation-local XP progression, plus the already authored player-role lifecycle.

1. Complete human Soldier role admission/slot handling without mutating the underlying eliminated Hero identity.
2. Generate each human Soldier through exactly the AI Soldier generation path, including tier/class/growth/stats/HP/feats/Content/capstone state.
3. Implement SoldierXP: +1 per effective post-mitigation/post-diversion Hero HP damage authoritatively credited; +50 when the credited event consumes a Hero personal life; no other XP sources.
4. Thresholds 100/250/450 produce +1/+2/+3 earned levels, processed sequentially and clamped to `D+3`/monster hard cap.
5. Level gains automatically run normal AI progression selection. No Soldier progression-choice UI.
6. P Character Sheet displays the current Soldier build and SoldierXP/next legal threshold read-only.
7. Soldier death waits 20 seconds, then creates a fresh eligible AI-equivalent incarnation with 0 SoldierXP. RETURN TO HERO QUEUE, dungeon clear and other retirement also discard Soldier incarnation progression.
8. While Soldier control is active, the underlying Hero is not revival-eligible; missed revivals are not banked. Returning to Hero queue preserves the original Hero elimination timestamp.
9. Active Soldiers never prevent a cooperative party wipe. Preserve max active contract 4 Heroes + 6 Soldiers = 10.

**Checkpoint gate:** two-player/state-isolation validator proves no Hero/Soldier progression leakage, XP thresholds/caps, death reset, queue/revival state and fresh deterministic generation. Commit and push immediately.

## Checkpoint F — Current-required staging/UI completion

**Goal:** make new RPG state visible and persist the required local leaderboard.

1. Ensure P Character Sheet reports current Hero/Soldier state accurately without becoming an authority.
2. Ensure I Spellbook reports all six Forms and current Content ownership.
3. Implement durable server-local `HEROES OF LEGEND` wall board in the shared staging hut beside the character mirror.
4. Ranking unit is a completed party run. At canonical run end create one immutable ranked-eligible candidate with the full `PlayerCharacterText` of each participating cooperative Hero and the run's Deborah rescue count.
5. Keep top 10 highest-to-lowest by rescues for that single run and display the canonical party/rescue wording. Preserve ranked-integrity exclusions.
6. Do not implement the deferred global Steam-backed mirror.

**Checkpoint gate:** restart/persistence validator retains board records; duplicate/invalid submissions do not corrupt ordering; P/I snapshots match server state. Commit and push immediately.

## Checkpoint G — Integrated validation and test handoff

**Goal:** prove the update is coherent enough for one substantial human play pass.

Extend existing `lod_rpg_validate`, test logging, and evidence exporter rather than building redundant harnesses. Automated/static coverage must include:

- Hero cap + banked XP behavior;
- 60/30/10 tier assignment and fixed named tiers;
- monster D+3/999 cap and Level-21+ growth without post-20 feats;
- Wizard d4 and Soldier d8;
- all six Forms and Contents;
- every current element/status family positive and negative resolution;
- current feat registry/effect-handler completeness;
- AI/human-Soldier automatic feat/capstone progression;
- SoldierXP 100/250/450 and reincarnation reset;
- multiplayer identity/state isolation;
- leaderboard persistence/ranked eligibility;
- no regressions in already accepted dice, reload, ROF, burst, SMG heat, navigation, Tetris, Push, Crowbar, Deadeye, Quantum and other protected families.

**Integrated human runtime gate:** after all checkpoint gates pass, install the resulting `main` build and play normally on `gm_flatgrass` for approximately **15–20 minutes**. Exercise multiple fights, level gains, Magic/Contents/statuses and staging transitions naturally rather than running dozens of isolated manual feat scripts. Return `console_latest.txt` + `rpg_summary_latest.txt`; add `rpg_session_latest.txt` only when detailed event ordering is needed. Diagnose from logs and perform one focused stabilization pass.

# Compute-budget discipline for Astra/Work

1. Begin from current `main`; verify clean working tree and remote HEAD.
2. Read only GDD `00`, `01`, and the subsystem tab required by the active checkpoint.
3. Inspect only existing modules/consumers relevant to that checkpoint before editing.
4. Prefer one shared authority over many feat/enemy special cases.
5. Run targeted static checks after each meaningful internal slice, but do not spend human runtime cycles on every feat family.
6. The moment a checkpoint is coherent and static gates pass: update only necessary coordination notes, **commit and push**.
7. If compute is running short, finish/validate/commit the current checkpoint. Do not start the next checkpoint and leave both half-finished.
8. Never spend remaining compute on prose that could instead preserve a working commit.
9. Do not modify the live GDD unless a genuine design contradiction is discovered. It was formally reconciled before this plan.
10. Do not implement deferred equipment/economy, expanded Hut Events, global leaderboard service, future Audio Director, crypto/DFT systems, or unrelated polish during this tranche.

# After integrated RPG completion

After the 15–20 minute RPG playtest is accepted or stabilized, resume missing authored major-gameplay content in this order unless newer design direction changes it:

1. Neil + Brute complete encounter behavior;
2. Gordon the Warden / final arena / Jail Key and rescue flow;
3. release audit, Steam Deck soak and focused multiplayer regression;
4. public/VPS/Workshop deployment only when explicitly authorized.

Major enemies must already consume the canonical RPG actor/Level system wherever they exist; this later phase concerns their missing authored encounter/state-machine gameplay, not a separate RPG implementation.
