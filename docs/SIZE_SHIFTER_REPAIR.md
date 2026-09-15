# Size Shifter wall-entrapment repair

Branch: `astra/equipment-update`; starting remote HEAD
`80810a7416321abd357aa0db4f9d14086de35bc0`.

The user reports Size Shifter can trap a player in a wall. No recording or exact
movement sequence was supplied, so native reproduction remains pending.

The live GDD 04 LOD-FEAT-004 directs exact lookup of HUMAN `INT_SIZE_SHIFTER`:
0.33 target, continuous three-second transformation, ordinary legal movement
hulls, and Little Guy/Big Guy baseline returns. This repair implements that
existing contract without changing the feat's cost, prerequisites or endpoints.

Two implementation defects were found:

- Only model scale was assigned; ordinary standing/crouched movement hulls were
  never explicitly preserved, including in client prediction.
- Core derived-stat sync set the ordinary baseline scale, then a second wrapper
  reapplied the shrunken scale, creating a transient expansion.

A shared module now installs the ordinary base-player hulls (32×32×72 standing,
32×32×36 crouched) before client and server movement. Server transformation writes
preserve them before/after native scaling. Growth traces the occupied volume
conservatively against player-solid geometry and rejects Hit/StartSolid/AllSolid.
Blocked transitions retain their last scale/progress; elapsed blocked time does
not accumulate into a later jump. No teleport, noclip, gate bypass or geometric
search was added. Routine sync applies the current transformation once; unchanged
model scale avoids another native scale write. Initially blocked baseline changes
are retried after clearance.

Engine references: [SetHull](https://wiki.facepunch.com/gmod/Player:SetHull)
requires both realms because hull settings are not replicated;
[SetModelScale](https://wiki.facepunch.com/gmod/Entity:SetModelScale) also affects
player hitboxes. Native Garry's Mod behavior still requires runtime validation.

`python3 tools/test_checkpoint_g_integration.py`: all 78 suites pass. New tests
exercise the production transformation tick, derived-stat sync, shared hull code,
blocked walls/ceilings, continuous reversal, .70/1.30 baseline returns, initial
blocked growth, feat removal and no teleport. The snapshot fixture now supplies
the newly exercised engine hull setters.

Next test: restart on gm_flatgrass, crouch against a container wall/corner, move
along it, then release crouch; repeat under a low ceiling. Check that moving clear
permits growth and that ordinary crouch-only gaps remain legal. Main/public
server unchanged. Earlier native-crash diagnostics remain intact.
