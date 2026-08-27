# Multiplayer Test Plan — 2026-08-28

## Objective

Reach a trustworthy **two-client playable multiplayer test on August 28, 2026** before implementing Neil + The Brute or Gordon the Warden.

Neil + The Brute and Gordon remain deliberately deferred. The current pre-boss dungeon progression is the temporary multiplayer test harness:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah`

The purpose of this gate is not release-candidate multiplayer. It is to prove that the server-authoritative campaign, new shared staging/deployment room, and ordinary dungeon lifecycle can support two real human clients without state corruption.

## Current multiplayer/staging checkpoint

The current build provides these intended guarantees:

- RunManager remains sole authority for four reserved cooperative slots and ten played identities.
- A newly admitted cooperative identity first appears in the native `gm_flatgrass` spawn hut before that identity's first dungeon deployment.
- StagingDeployment owns the shared hut presentation, identity-bound starter assignment/claim state, staged/deployed state, and portal transition.
- Every first-entry identity receives baseline Crowbar + Pistol (18 loaded, zero reserve) plus exactly one advanced starter from Shotgun 7, SMG 25, Magnum 6, or AR2 20, also with zero reserve.
- Starter assignment is deterministic for the campaign identity and does not reroll on reconnect.
- Among the currently reserved four cooperative slots, advanced starters are assigned without replacement wherever the four-gun pool permits.
- Starter pickups are identity-instanced and prevented from transmitting to other clients.
- A staged player reserves a cooperative slot but is not yet dungeon-active: hostiles cannot target them, they cannot advance dungeon progression, their dungeon map is unavailable, and dungeon enemy-drop rolls do not include them.
- The blue portal refuses deployment until the identity has claimed its starter.
- Portal USE/E is the sole legal exit from staging into the current valid maze start/checkpoint.
- The old level-banded JIP SMG/Shotgun/Magnum/AR2 catch-up kit is retired. Additional late-campaign catch-up beyond the universal hut starter will be tuned only after the multiplayer lifecycle gate.
- The former two guaranteed Level-1 firearm placements are retired; additional firearms remain ordinary individualized reward/drop discoveries.
- Extra-life teammate revival requests activation through RunManager instead of writing `ActiveIdentity` directly.
- Death-Tetris line clears award HP only; they cannot shorten the fixed 20-second mandatory death wait.
- Death/Tetris and intermission-Tetris eligibility survive relevant disconnect/reconnect paths.
- Friendly fire is suppressed and teammates do not body-block.
- Dungeons 1–20 derive personal minimap access from current dungeon-active player state; personal Magic drain remains unchanged.
- Future level generation snapshots the connected cooperative party before active identities are repopulated so encounter planning does not silently plan every dungeon as solo.

## Gate S0 — Native-hut single-client staging regression

This is the first gate for the new staging feature and must pass before adding another human client.

1. Fully restart Garry's Mod on `gm_flatgrass`.
2. Start a fresh normal LOD campaign.
3. Confirm the player appears inside the map's native Flatgrass spawn hut, facing the red-tinted Dungeon Hermit and one visible advanced firearm.
4. Confirm the guide reads/says: `It's dangerous to go alone. Take this.`
5. Turn around and locate the blue deployment portal.
6. Before claiming the firearm, press USE/E on the portal. Deployment must be denied.
7. Run `lod_staging_status`, `lod_multiplayer_status`, `lod_multiplayer_contract_status`, and `lod_multiplayer_roster_status`.
8. Claim the visible starter firearm.
9. Verify its loaded magazine exactly matches its family: Shotgun 7, SMG 25, Magnum 6, or AR2 20; reserve ammo is zero.
10. Press USE/E on the blue portal.
11. Confirm immediate teleport to the valid dungeon start/checkpoint and ordinary dungeon controls/map/combat become available.
12. Run the four diagnostics again.

### S0 expected before starter claim

- `lod_staging_status`: `slotActive=1 staged=1 deployed=0 claimed=0 pickups=1 hut=true ... result=PASS`.
- `lod_multiplayer_roster_status`: `slot=true dungeonActive=false state=staged` and `staticLoot=0`.
- `lod_multiplayer_contract_status`: `mapAllowed=0`, `mapMismatch=0`, `result=PASS`.
- `lod_multiplayer_status`: the raw campaign slot is reserved, but living dungeon-active count may be zero; no failures.
- Player cannot physically walk out of the staging lease into Flatgrass.

### S0 expected after deployment

- `lod_staging_status`: `staged=0 deployed=1 claimed=1 pickups=0 deployments=1 result=PASS`.
- `lod_multiplayer_roster_status`: `slot=true dungeonActive=true state=deployed`.
- `lod_multiplayer_contract_status`: on Dungeon 1, `mapAllowed=1`, `mapMismatch=0`, `result=PASS`.
- Ordinary individualized static dungeon loot materializes only after deployment.

## Gate MP1 — Second client joins and stages independently

With player 1 already deployed in a running Level-1 dungeon, connect a second real human client.

Verify before player 2 deploys:

- player 2 receives a different persistent character identity;
- player 2 reserves the second cooperative slot but appears in the shared native hut, not in the maze;
- player 1 remains in the maze and is not moved/restarted;
- player 2 sees exactly one personalized advanced starter;
- player 1 cannot see or collect player 2's starter and vice versa;
- player 2's starter differs from player 1's starter while unused peer options remain;
- player 2 has Pistol 18 + Crowbar plus the unclaimed starter, zero reserve, no Grenades, no AR2 secondary;
- player 2 cannot use the dungeon map and is not targeted by hostiles or included in enemy-drop rolls while staged;
- portal use before starter claim is denied.

Run:

- `lod_staging_status`
- `lod_multiplayer_status`
- `lod_multiplayer_contract_status`
- `lod_multiplayer_roster_status`

### MP1 staged acceptance

- `connected=2`, `slotActive=2/4`, `deployed=1`, failures=0.
- Player 1 reports `state=deployed`, `dungeonActive=true`.
- Player 2 reports `state=staged`, `dungeonActive=false`, `map=NO`, `staticLoot=0`, `targetedBy=0`.
- `lod_staging_status` reports no starter conflicts.

Then have player 2 claim the starter and USE/E the portal.

### MP1 deployed acceptance

- both clients are now dungeon-active simultaneously;
- player 2 teleports to the current valid team start/checkpoint;
- `lod_staging_status` reports `deployed=2`;
- `lod_multiplayer_status` reports `connected=2`, `active=2/4`, `living=2`, failures=0, result=PASS;
- `lod_multiplayer_contract_status` reports `mapAllowed=2`, `mapMismatch=0`, result=PASS;
- player 2's ordinary individualized dungeon loot becomes available only after deployment.

## Gate MP2 — Personal resources, friendly fire, and target distribution

After both clients deploy:

- shoot each other deliberately: teammate HP must not change;
- walk through each other: there must be no teammate body blocking;
- note both Magic values, have one player open the map for several seconds, and verify only that player's Magic drains;
- fight together and then split into different maze regions/floors;
- verify hostiles may target either living deployed player but never a staged/dead/disconnected/non-active player;
- test Watcher, Seeker, Soldier, generated cover, and cross-floor movement if encountered.

Run `lod_multiplayer_roster_status` during combat; `targetedBy=` should provide direct target-distribution evidence.

## Gate MP3 — Disconnect/reconnect before first deployment

Exercise this with a fresh admitted identity if practical:

1. Join and reach the staging hut.
2. Note character and advanced starter assignment.
3. Optionally claim the starter, but do not deploy.
4. Disconnect.
5. Reconnect to the same campaign.

Verify:

- same identity and character return;
- same advanced starter assignment returns without reroll;
- if unclaimed, the owner's pickup is reconstructed;
- if already claimed, the weapon remains owned and is not duplicated;
- player remains staged until portal deployment;
- no second PlayerState/character reservation is created.

## Gate MP4 — Personal death while teammate remains alive

Player A dies while Player B remains alive and deployed.

Verify:

- simulation continues for B;
- A enters restricted allied spectating/death state;
- A's life decrements independently;
- A may play Death Tetris;
- Tetris line clears increase only A's next-life HP bonus;
- respawn remains unavailable until the fixed 20-second gate expires;
- A respawns at the team checkpoint without disturbing B;
- an already-deployed identity does not return to the staging hut on ordinary death/respawn.

## Gate MP5 — Disconnect/reconnect after deployment and during death

With both players deployed:

- disconnect/reconnect one living player and verify identity, character, inventory, lives, starter weapon, Magic, and individualized loot restore without restaging;
- then die with lives remaining, disconnect before respawn, reconnect before the hard cap, and verify death eligibility/time survives appropriately;
- `lod_multiplayer_lifecycle_status` should demonstrate the exercised reconnect/suspend paths.

## Gate MP6 — Shared progression

Advance through:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah`

Have both clients alternate collecting/opening progression objects. Every transition must be team-global and idempotent. Neil + The Brute are not part of this gate.

## Gate MP7 — Rescue/intermission/next level

Have either deployed player rescue Deborah.

Verify:

- one rescue clears the level globally exactly once;
- both played identities receive the appropriate independent intermission-Tetris opportunity;
- HP bonuses remain personal;
- next-level generation occurs once;
- already-deployed identities proceed into the next dungeon through the ordinary checkpoint path and are NOT restaged;
- `lod_multiplayer_contract_status` on Level 2 reports `plannedParty=2` when both cooperative identities remained connected through generation.

## Gate MP8 — Wipe / promotion sanity

If practical:

- eliminate one player completely and verify the other continues;
- exercise an extra-life teammate revival if available;
- verify revival never increases reserved cooperative slots above four;
- fifth+ identities remain waiting spectators until a slot becomes available;
- campaign failure occurs only on a true party wipe under current campaign rules.

## Diagnostic commands

- `lod_staging_status` — native-hut, starter-assignment, claim, and deployment summary.
- `lod_multiplayer_status` — live slot, identity, hostile-target, loot-owner, and Tetris integrity summary.
- `lod_multiplayer_contract_status` — friendly-fire, map, progression-actor, and party-scaling contract summary.
- `lod_multiplayer_roster_status` — per-player slot/deployment/starter/resource/cell/target details.
- `lod_multiplayer_lifecycle_status` — revival/reconnect/freeze-path counters.

## Test-stop conditions

Stop and fix before proceeding if any of the following occurs:

- Lua error;
- player does not appear in the native Flatgrass hut on first admission;
- staging containment allows ordinary walking out into Flatgrass;
- portal deploys an identity before starter claim;
- starter assignment rerolls on reconnect;
- two currently reserved players receive the same starter while unused peer options remain;
- a client sees/collects another identity's starter or ordinary loot;
- a staged player is targeted by hostiles, uses the dungeon map, advances progression, or receives enemy-drop rolls;
- reserved identities exceed four;
- duplicate/polluted persistent identity state;
- one player's death freezes or respawns the other;
- teammate bullets/explosives damage another player;
- progression diverges between clients;
- level transition runs twice or clients enter different level instances;
- serious Steam Deck/server performance regression.

## Post-test order

After the first real multiplayer gate is accepted:

1. fix defects revealed by the run;
2. perform the larger authority-consolidation work from the Second Full-System Audit;
3. expand validation toward 3–4 clients / slot churn / dedicated-server soak;
4. separately retune any deeper-level JIP assistance beyond the universal hut starter if playtesting demonstrates a need;
5. implement Neil + The Brute and validate the midboss in multiplayer;
6. implement Gordon the Warden and validate the boss/rescue loop in multiplayer;
7. finish release-candidate multiplayer/soak/polish.
