# Implementation cleanup — 2026-09-14

Follow-up to the systems audit, starting at
`f5dc6bdbaf839c8ac8fd1e98da4ee3d660e9c769` on `hybrid/antigravity`.
Shael requested a skeptical review of residual compatibility layers and unstable
implementation choices. Changes below follow observed code defects, irrespective
of author/model. Accepted mechanics and prior feat exclusions remain unchanged.

## Canonical Magnum burst

Removed the deferred Magnum Burster bridge and the Aim wrapper that replaced the
same named firing hook. Magnum's existing authority now commits the chamber,
Aim multiplier and Burster contribution together. There is one cylinder hook;
no next-tick installation, InitPostEntity retry or OnReloaded wrapper accumulation.
The standalone 122-line compatibility module and its bootstrap include are deleted.
Validation now checks the canonical method rather than installing code as a side
effect of inspection.

Chamber 5/6 still author 2/3 projectiles, Burster adds its existing +1/+2/+3 once,
ordinary shots remain single, and a low-health extra shot does not manufacture
Burster eligibility. Aim remains inherited by every follow-up. Ammo rules unchanged.

## Error and lifetime boundaries

- Magnum and AR2 injected shots restore lag compensation and temporary attack
  flags/context even if a bullet hook throws. Failed bursts stop; they do not
  retry damage that might already have applied. An aborted Magnum burst cannot
  award final-cartridge preservation as if every follow-up completed.
- Deferred Feedback checks both body spawn serials, progression identities,
  campaign state and graph identity. A same-seed rebuild is a new world. This
  preserves the existing same-body death behavior; it does not add an Alive gate
  or reinterpret Feedback chance/cooldown/damage law.
- Revival and reconnect observers are bound to the campaign that scheduled them.
  Revival also checks the captured player state, body serial and graph before spawn.
- Major presentation ACKs must match a recent packet sent to that recipient and
  kind. Consumed serials cannot replay. Pending evidence is weak-keyed, expires
  after 15 seconds and is capped at 64 per client, with disconnect cleanup.

## Validation and next gate

Integrated gate **56/56**, including diff check, project Lua syntax, feat-set and
zero-blank-description gates. New production burst tests cover every Burster rank
on both authored chambers, Aim inheritance, ordinary/low-health exclusion, ammo,
and injected hook failures for both weapons. Extended lifecycle/FX tests cover
replaced bodies, same-seed worlds, obsolete revival callbacks and ACK spoof/replay.

This is a further validated cleanup tranche, not proof that all hidden engine or
multiplayer defects have been eliminated. No main merge or live deployment.
Freshly restart GMod after installing. During Shael's integrated playtest, give
special attention to the Magnum's final two chambers with Aim/Burster, AR2 bursts,
Wizard reactions, and death/revival/reconnect transitions. Use the unchanged
logging procedure in `WIZARD_REACTION_REPAIR.md` and return the same evidence bundle.
