# Systems robustness audit — 2026-09-14

User-directed audit on `hybrid/antigravity`, starting at
`2db9be19f7328c03e52cb6d1de24ac0158f6d34c`. Main promotion remains subject to
Shael's exact-candidate runtime approval. No server or Workshop deployment.

Design navigation: live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 02/03/05/06/07, revision
`ANLCKQmY4d8FQ0np0TDKJqTewiNXqFyyuDPrSLM3OOwGX_6GUHcVCfqIgeYjwWCL2nEYtL6iSlfP2bBsY0GRVWemgkqABv831NqVtF7MkA`.
This is implementation repair, not a new balance or roadmap mandate.

## Checkpoint 1 — actor identity, progression and validation authority

- Soldier StateFor/Retire/Award wrongly required Lua `table` objects. Real GMod
  players have type `Player`. One StateFor boundary now resolves both controllers
  and active generated profiles. Repeated attachment preserves an occupied profile;
  retirement revokes captured profile references as well as clearing the controller.
- Soldier damage XP is bounded by the victim's remaining HP, excludes overkill,
  and uses post-defense damage. RunManager's actual personal-life consumption now
  supplies the missing canonical +50 credit to the attacking Soldier.
- Automatic Soldier level-up applies the shared MaxHP authority and queues the
  current sheet. It does not heal the player's existing HP or alter the stored Hero.
- AI and human Soldier eligibility previously diverged on reload/magic capability,
  changing deterministic feat drafts. Both now use the automatic Soldier capability
  set; controller input affordances do not change generated RPG build semantics.
- Automatic progression's post-20 bulk path was unreachable. Stop the milestone
  loop at 20, generate remaining seeded HP dice once, and recompute numeric stats
  once. Level-999 generation matches sequential advancement without quadratic scans.
- Checkpoint E and Soldier lifecycle validators printed FAIL without failing the
  process. They now fail the gate. The Soldier fixtures model GMod entity types;
  retired-reference, overkill, life-credit and live MaxHP assertions use production
  seams. Corrected an incomplete snapshot fixture to represent an active incarnation.

Checkpoint validation: integrated gate **53/53**, including Lua syntax, diff check,
150-entry feat inventory and zero blank descriptions. This is static evidence;
Source-runtime acceptance remains pending. Continue with cross-system lifecycle,
targeting, status scheduling and bounded-work inspection before final handoff.
