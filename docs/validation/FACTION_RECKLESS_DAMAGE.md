# Soldier / Hero and Reckless damage spot repair

Author request: September 27, 2026. Gameplay parent at development start:
`0f1e7092644c9c3e5eede39263206b2b5850c707` (standing stair headroom).
The delivery receipt supplies the actual published child, tree and independent
run. A local reconstructed source commit or workflow trigger is not gameplay
ancestry. This is an unnumbered author-requested repair, not SPOT-18.

## Contract

Live GDD navigation was completed through 00 -> 01 -> 03 Combat/Magic/Status,
then the exact HUMAN Reckless paragraph (tab `t.0`, 350441-353573 at the revision
read on September 27). The implementation follows the existing rule; no design
change, duration tuning, save tuning, faction reassignment or new AI director.

- Heroes and Soldiers are opposing combat factions, including human-controlled
  Soldiers. Source's `IsPlayer()` alone does not establish a friendly pair.
- Ordinary same-faction attack damage is blocked. A Reckless **attacker** may
  damage its own faction through the attack's actual geometry. A Reckless victim
  does not grant the other actor permission to damage it.
- Current-status permission ends on expiry/cure. A sealed, already accepted
  projectile/burst may finish, but its receipt is bound to the source's status
  life, role and world. Death, incarnation/role change or world replacement
  cannot transfer that permission to another life. No global friendly-fire cvar.
- Existing self-damage policy, fixed natural-6 exploding duration dice, WIS save,
  normal hostile target selection, 1-in-3 AI betrayal decisions, and the narrow
  B15 packet-authorized crossfire exception retain their existing owners.
- Permission is not a forced native allow: sanctuary, geometry, defenses and
  other damage rejection hooks retain their opportunity to reject a hit.

## Root causes and repair

`GM:PlayerShouldTakeDamage` rejected every other player, including enemy human
Soldiers. The multiplayer hook independently rejected active Hero pairs without
consulting Reckless, overriding the GM's attempted exception. The enemy hook
consulted the raw attacker only, missing owned-proxy attribution. Several attack
filters selected only natural opponents before native damage could even run;
Soldier bolts explicitly ignored hostiles and resolved only player victims.

The existing `FactionManager` now owns shared source resolution, same-faction
blocking and damage eligibility. The GM and both existing native damage gates
consult it. Natural `IsOpponent`/`Opponents` queries remain separate from
Reckless-aware damage geometry; no faction membership is rewritten.

Magic area/cone/beam/bolt/bomb paths, Wall and ricochet contacts, Magnum piercing,
equipment damage riders/contacts, damaging auras and the roster damage entry use
the damage permission seam. Soldier bolts use the real swept trace for eligible
combatants rather than a player-only victim decoder. No extra damage event,
attack roll, frame polling or effect emitter was added.

Accepted Magic, firearm and Soldier-burst event objects can carry a server-only
weak-key permission receipt. Delayed Magic, shotgun settlement and Soldier-bolt
delivery scope that receipt around the **same native damage call**, preserving
attacker, inflictor and durable attribution. The scope restores after success or
error; a later unrelated hit cannot inherit it.

## Reproducible validation

```bash
python3 tools/run_lua54.py tools/test_faction_damage.lua
python3 tools/run_lua54.py tools/test_faction_geometry.lua
python3 tools/run_lua54.py tools/test_faction_roles.lua
python3 tools/test_faction_damage_gate.py --output /tmp/lod-faction-evidence --workers 2 --suite-timeout 120
```

Use an empty output directory. The aggregate retains all 99 standing-stair
selections and adds 9 focused/adjacent selections (108 total), including the
three new tests, actual B15 crossfire, existing Magic wall/ricochet/geometry
regressions, and all-source Lua syntax. This is a selected regression gate, not
a full campaign matrix or native Garry's Mod acceptance.

The first pre-fix core matrix recorded **21 failures across 79 checks**. The
completed core matrix covers 96 checks; geometry adds 19 assertions and the
actual RunManager/staging/Soldier lifecycle test adds 14. Source traces and HP
transport are explicit engine boundaries; real faction, GM, multiplayer,
status, role and geometry-selector code is executed. Adjacent retained suites
exercise the actual damage dice, mitigation, equipment and Soldier rifle paths.

The first complete 108-suite gate passed 107 selections; AG-011 stopped because
its synthetic summon lacked the engine Entity IsPlayer/Health methods. Only
that fixture was repaired; no production rule or assertion was relaxed.
Earlier incomplete gates or fixture errors remain in the external working
record and must not be described as passes. Published evidence must identify
its exact tree and include the independent final receipt.

## Native acceptance (pending; do not report as completed)

Fully quit Garry's Mod before installing the new main. On `gm_flatgrass`, outside
staging/entry protection, verify Hero -> human Soldier and human Soldier -> Hero
both reduce HP. Ordinary Hero -> Hero and Soldier -> allied monster should not.
Apply Reckless to the attacker through an authored effect: the same actual
shot/contact should now damage the ally. Victim-only Reckless must not suffice.
After expiry/cure, a fresh attack should again be harmless to allies; an already
committed projectile may finish. Check that solid cover still blocks damage.

The human-Soldier case requires another controlled client; an AI Soldier alone
cannot demonstrate that the former player-versus-player rejection is gone.
Use the existing `console_latest.txt` and `rpg_summary_latest.txt` evidence flow.
No Workshop publication or VPS deployment is part of this source repair.
