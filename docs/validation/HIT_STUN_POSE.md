# Hit-stun floor-sinking repair — 2026-10-02

Parent: `c703a8ec6ac26fbc57d08a32d6231ccc7db6aa84` (MS3 song-first main).
Scope: the author's report that enemies sometimes sink visually during hit-stun.

## Cause and correction

The preliminary M3 flinch selector and the final frozen-pose selector accepted
NPC pain sequences without checking their Source sequence flags. An additive
`STUDIO_DELTA` sequence is an offset layer, not a complete body pose; installing
it as the base can lose the model's normal root placement. The existing skeleton
exception did not protect ordinary NPC rigs. The old fallback also jumped the
current animation to 44% rather than freezing the actual visible frame.

The shared hurt-pose selector now rejects delta, empty-data and gesture poses
before introducing a flinch. Full-body flinches retain their existing sampled
cycles. Otherwise it holds the current valid base at its exact cycle, or uses
the existing model-aware idle resolver when the current sequence is invalid.
No unchecked preliminary flinch can contaminate that snapshot. The immediate
corpse-pose hook uses the same selector, protecting the lethal transition before
the existing deferred hook runs. Cached pose IDs are revalidated on model changes.
Metadata is inspected at selection/model change, not every hold frame.

Motion V2, entity origins, hulls, rendering/bone offsets, damage, stun durations,
ability/form multipliers, shotgun aggregation, crowbar anti-stunlock, Gordon's
deadline and callback order, attack interruption, rewards and corpse lifetime
are not retuned. Ordinary player attack gestures remain overlays. The existing
`lod_m3_hurtpose_status` diagnostic adds `fallback=true/false`.

## Executed source gate

Run from the repository root:

```sh
python3 tools/run_lua54.py tools/test_hostile_hurt_pose.lua
```

The committed test loads the actual shared animation resolver, M3 hit feedback,
hurt-pose handler and death-pose handler with synthetic native entity/sequence
metadata. All 23 test groups pass. Running the same test against SHA-verified
parent file copies produced 6 passing and 17 failing groups, including direct
observation of an unsafe delta sequence being installed by the real stun path.
This reproduces the code defect, not an in-engine screenshot or visual test.

Coverage includes named/weighted complete flinches, delta/empty/gesture rejection,
missing metadata, reference/invalid recovery, exact fallback cycles at 0/1 and
near the endpoints, skeleton bases and unchanged attack overlays, frame holds,
no repeated metadata work, recovery, retrigger/crowbar windows, shotgun and
ability/form timing, Gordon deadlines/callback order, exact interruption
arguments, dead/latched rejection, immediate/deferred death, removed bodies,
and model-local sequence invalidation. Position/hull/scale/bone writes fail
the test immediately.

Lua 5.4 syntax loading passed for the three changed production modules, the
unchanged shared animation resolver and the new regression test. A byte-level
comparison confirms that M3 combat logic following `ApplyHitStun` is unchanged
except for replacing preliminary pose selection with the existing wrapper's
single final selection. The complete repository integration matrix was not run
in this focused session; this standalone test does not claim its coverage.

## Remaining native acceptance

Fully quit GMod, update/install the published main and relaunch LoD on
`gm_flatgrass`. Shoot and crowbar several NPC-shaped enemies and a Skeleton,
including on an upper floor or stairs. Their bases should stay seated during
stun, resume normally afterward and remain stable on a lethal follow-up.
Check Gordon's recovery and shotgun stagger without changing existing timing.
The environment here did not provide a native GMod session, so visual fidelity,
actual stock-model coverage and Steam Deck performance remain unaccepted.
No Workshop publication or VPS deployment is included.

## API references

- Facepunch: `Entity:GetSequenceInfo` and `Structures/SequenceInfo` expose sequence
  flags: https://wiki.facepunch.com/gmod/Structures/SequenceInfo
- Valve Source SDK `src/public/studio.h`, sequence/autolayer flags:
  `STUDIO_DELTA=0x0004`, `STUDIO_ALLZEROS=0x0020`.
  https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/public/studio.h
