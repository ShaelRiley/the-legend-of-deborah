# SPOT-17 finite production gate

Predefined before focused execution. Preserve every one of SPOT-16's 93 selected
suites, adding `test_spot17_movement_server.lua` and
`test_spot17_movement_client.lua`: **95 selected suites**, not the full campaign
matrix. Per-suite timeout 120 seconds; two workers. Syntax-check every Lua source
and retain the existing manual/document/asset/diff gates.

The server test executes the actual shared load graph, RunManager/Soldier loadout,
final rifle/aim/rate wrappers, existing SetupMove, voluntary-action admission and
Dodge FinishMove callbacks. Test base 140 from live config, no ordinary sprint or
grounded jump, class/DEX/status/Haste/directional composition, crouch/diagonals,
warning/all shots/actual recovery, extra rounds/rate feats, release/hold/denial,
service lateness, current/forced/vertical motion, airborne feat admission, all
existing body/weapon/role/dungeon invalidation, and saved Hero isolation. Inherited
assertions may execute for setup but are not counted again as SPOT-17 assertions.

The client test runs the actual predicted movement and input handlers. Verify
server-deadline/root-weapon/context matching, packet absence/expiry/replacement,
crouch and input filtering, movement and forced/vertical projection, and Hero
noninterference. Engine entity/command/move/network providers are test boundaries;
no native Source physics, latency, co-op, audio or appearance pass is inferred.

Formal gate launches retain raw logs and the exact pre-launch tracked/untracked
source patch outside the repository. Earlier focused setup limitations are recorded below. A final unchanged-source local gate precedes an
independent gate of the identical candidate. Verify ordered suite lists, every
raw-log hash, complete source snapshot, commit/tree/modes and sole real gameplay
parent. Non-forced publication must stop if main advances. No Workshop/VPS action.

## Source implementation and delegation

Verified baseline main 9e2601953e8f91469fc3d8ece7c13110fd1e8941, tree
e9b88e4abc327954742828a2993277d21b03fff5. Restored the original commit bytes and
complete 2,199-file tree from independently published SPOT-16 artifact 10923544129;
this is the actual gameplay commit, not a synthetic anchor. No source changes
preceded that exact verification. No uncommitted baseline work existed.

Live GDD 06/07 SPOT-17 supplements were written and their targeted paragraphs read
back before code, revision
ANLCKQkRkFqxLOwgWBsoB5Yxi9Vh5Sci7yPCJQnc0u4rp9816p5wapMHCpua7mCzCpHxOBP0e6Ji5jc_0BDcDhjDFUtnPDNC0_Sb6ndNew.
The delegated detail is AI config base speed, no ordinary sprint/ground jump,
warning/burst/actual-recovery voluntary rooting, retained off-commitment movement
feats, gravity/forced motion and exact source/lifecycle cancellation. No existing
feat formula, AI rule, Hero speed or SPOT-16 firing rule was rebalanced.

`sh_soldier_movement.lua` is a stateless projection/helper inside the existing
server SetupMove and client prediction seams. PlayerWeaponSpecials' exact current
burst owns the lock. Existing reset/cancellation and service own cleanup. Shared
voluntary-action admission blocks airborne movement feats while committed; the
existing movement hook skips voluntary dash. Caps apply before existing modifiers,
not after them. Both Dodge thresholds and cached motion admission use the current
Soldier contract. The client projection expires by deadline and rejects mismatched
role, life-context and native rifle; native prediction is not established by this
headless projection check. No native walk/run/jump values are stored or overwritten.

The canonical booklet now explains the movement contract alongside the infinite
rifle. Generated HTML/chunks are rebuilt from book.json and the existing catalog;
166 chapters / 32 chunks remain. Historical SPOT-16 records remain historical.

## Attempt history and limitations

Focused setup attempt 01 failed because the old rifle command adapter omitted
native movement button constants now consumed by the real shared input. Attempt
02 restored those constants and passed all 988 inherited SPOT-16 assertions.
These first two launches have raw output and only partial source-overlay evidence;
they are not represented as complete contemporaneous source replays.

Attempt 03 executed the new movement gate but its inherited shared-only fixture
had not loaded init.lua's actual Magic resource authority. Loading production
sv_magic.lua, rather than inventing its pool/debit logic, resolved that setup gap.
Attempt 04 passed the client gate but called the actual ReviveIdentity debit-callback
argument with a number. The test now uses the existing ordinary revival signature;
production revival was unchanged. Attempt 05 passed 2,526 new server assertions.
Attempt 06 additionally checks immediate pre-FinishMove cached-Dodge invalidation
and the actual Haste rank: 2,551 new server plus 321 client assertions passed.
Attempts 03 onward retain complete pre-launch source patches against the authentic
SPOT-16 parent. Inherited SPOT-15/SPOT-16 checks are executed, not counted again.

Aggregate gate 01 was 93/95 on unchanged source snapshot
0275c76a988d0415bcd8ffe24ad6ddad87bf0366386e2746dbf8d375e9e927d0.
Snapshot delivery and its inherited SPOT-11 draft check failed because read-only
snapshot actors do not provide native Alive(). The movement role predicate now
explicitly requires native body methods, with a focused read-only-actor regression;
no snapshot/draft assertion was removed. Earlier failures remain failures.

Final focused counts, complete local/independent gate results, raw-log hashes,
source snapshot, exact child/tree/sole parent and non-forced live main readback
belong to the delivery receipt. This document does not assume publication success.
No full campaign-matrix pass or native GMod result is claimed. Existing full Gate-B
perkDisplayName and native acceptance debts remain open. Neither Workshop nor VPS
was changed or authorized by this checkpoint.

## Next native observation

On the exact installed build, use ordinary gm_flatgrass play to compare Soldier
walking/crouching/stairs, unavailable ordinary sprint/ground jump, and commitment
root through warning/burst/recovery. Check a cancellation/F3 return and ordinary
Hero movement after genuine revival; co-op observation should judge enemy
readability. Existing airborne feats should work outside commitment, not escape it.
Return console_latest.txt, rpg_summary_latest.txt and a short observation naming
the exact build. Use detailed session evidence only for disputed timing. Do not
require another dedicated Razor test. Local acceptance precedes any separately
authorized Workshop parity or matching VPS deployment.
