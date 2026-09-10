# RPG GDD Rules Baseline — Navigation Redirect

**Status: SUPERSEDED AS A DESIGN TRANSCRIPTION.**

This file formerly duplicated a small subset of RPG rules from the live Game Design Document. That duplication became a source of drift and unnecessary AI navigation cost. Do not use this file as design authority and do not expand it into another copied ruleset.

## Canonical design source

**The Legend of Deborah — Garry's Mod Game Design Document**  
Google Doc ID: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`

For AI development, read the live document in this order:

1. `00 — AI ENTRYPOINT`
2. `01 — AI RULE INDEX`
3. only the relevant normalized subsystem tab
4. an exact `HUMAN — Complete GDD` anchor/featId only when the normalized rule marks the needed detail `HUMAN-DETAIL`

Do not read `HUMAN — Complete GDD` wholesale merely to orient an implementation task.

## Current normalized subsystem tabs

- `02 — RPG & LEVELING`
- `03 — COMBAT, MAGIC & STATUS`
- `04 — FEATS & IDENTITY`
- `05 — CORE LOOP & WORLD`
- `06 — MULTIPLAYER, LIFECYCLE & UI`
- `07 — IMPLEMENTATION & TUNING`
- `90 — DEFERRED / FUTURE`

The normalized tabs supersede this historical transcription wherever they explicitly cover a rule. New design changes must be made in the live GDD, not here.

## Implementation navigation

Current execution sequencing is in `docs/DEVELOPMENT_PLAN.md`.

`docs/RPG_GATE_E_FEAT_MATRIX.md` is useful as a measured **implementation inventory** from its stated checkpoint, especially for locating feat IDs that were present/missing at that time. It is not current design authority and its old unresolved-design notes may be stale.

`docs/RPG_IMPLEMENTATION_GATES.md` and the long history in `docs/DEVELOPMENT_STATUS.md` preserve implementation/runtime evidence. They do not override the current live GDD or the current development plan.

## High-risk stale assumptions to reject

Do not resurrect any of the following from old plans, chats, exports, or historical status text:

- one universal Level-20 cap for Heroes and monsters;
- Wizard progression hit die d6;
- 94/5/1 monster tiers or a 25% Elite Bernoulli;
- `2 × DungeonLevel` monster baseline;
- 1.25× stochastic enemy target progression;
- five-Form Magic catalog;
- Wizard-exclusive Content use;
- Rogue extra feat drafts at Levels 2/5/10/15;
- doubled Hero XP thresholds;
- human Soldier player-chosen class/progression choices;
- human Soldiers being unable to earn XP;
- active Soldier control remaining eligible for Hero revival;
- server event order allowing a wiped party to survive because Gordon died first;
- treating core status/element/Magic systems or the server-local `HEROES OF LEGEND` staging board as deferred.

When implementation differs from the live normalized GDD, that is an implementation gap to reconcile—not permission to rewrite the design here.
