# Milestone 1 runtime incident — first gm_flatgrass launch

Date: 2026-08-16

The first live attempt to start The Legend of Deborah on `gm_flatgrass` crashed Garry's Mod before the Milestone 1 audit could be run.

No crash log has yet been used to prove a single root cause. The strongest implementation-level suspect is the original wall builder's creation of roughly 1,500 independent frozen `prop_physics` cargo-container entities in addition to procedural collision entities. Garry's Mod documents that physics initialization can fail when no more PhysCollides can be created.

Mitigation applied immediately:

- preserve the real cargo-container model as the visible maze wall;
- replace each container's independent VPhysics object with a non-solid visual scripted entity;
- merge contiguous logical wall edges into substantially fewer server-authoritative static collision boxes;
- keep the procedural graph unchanged as navigation/progression authority;
- keep generation fail-closed if required merged collision cannot initialize.

This incident remains open until a subsequent `gm_flatgrass` launch succeeds and `lod_m1_audit` can run. If the hardened build still crashes, collect `garrysmod/console.txt` / crash output before further architectural changes.
