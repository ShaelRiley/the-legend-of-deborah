# Milestone 1 runtime incident — unsupported Level 0 floor

Date: 2026-08-16

A live `gm_flatgrass` run reached gameplay and the original Milestone-1 audit reported a logical/clearance PASS, but the player immediately fell beneath the labyrinth. The screenshot showed the generated maze suspended above the actual Flatgrass world surface.

Root defect:

- the builder treated configured world `Z=0` as the walkable Flatgrass plane;
- Level 0 received no explicit generated floor collision because the first builder assumed the base map would provide it;
- the audit tested whether player hulls were embedded in geometry, but did not test whether solid support existed beneath those hulls.

Mitigation:

- server-side world trace resolves the actual Flatgrass brush floor at maze build time;
- the logical maze origin is anchored just above that world plane;
- explicit merged floor collision is now generated for Level 0 as well as elevated layers;
- a support audit checks the spawn and ordinary cell centers for solid floor within 48 units;
- `lod_m1_audit` now appends an authoritative `M1 AUDIT FINAL PASS/FAIL` floor-support result.

The graph topology and seed derivation are unchanged by this repair. This incident is closed only after a subsequent live run shows the player standing on Level 0 and the support audit reports zero unsupported ordinary cell centers.
