# B22 finite gate — route-based macro-pacing

Base: verified main35351d7ee24fda7ba65be65f865c3c1e8bcd3555.
Scope fixed before gameplay edits: EncounterDirector production placement and
composition, diagnostics/manual, deterministic campaign proof. No roster additions.

## Authored production contract

Each progression sector measures traversable distance from its entrance to its
keycard (sectors1–3) or CoreCell (sector4), through Navigator and same-sector tags.
For entry distance a, objective distance b and entry→objective length L, projected
progress is clamp((a-b+L)/2,0,L)/L; detour depth is max(0,(a+b-L)/2).
Choose one of three phrases uniformly with an independent per-sector pacing RNG:
Surge quiet/probe/pressure/recovery boundaries10/35/80%; Ambush20/45/85%;
Gauntlet10/25/85%. Quiet/recovery cells admit no discretionary encounter homes.
No fallback may fill these reservations. Objectives retain exact authored squads
and positions. This is spatial phrasing, not a guarantee of combat-free traversal:
wandering/pursuing enemies, player route reversal and multiplayer convergence remain.

Probe squads use the existing composition resolver at scale1 (base squad, all
companions retained); pressure squads use the unchanged party/depth scale. A legal
branch at detour depth>=4 in a probe/pressure band is a spike, using full scale.
No extra multiplier, density, budget or stat change. Existing singleton and
composition authorities apply. Prefer one probe then one pressure/spike where
legal/affordable; preserve seeded order within each pool, then remaining candidates.
If no positive route span exists, fail closed for that sector and report it
(disconnected path or coincident entrance/goal);
legacy/developer graphs missing entrance/goal metadata retain ordinary planning
with an explicit unavailable diagnostic. No graph/native caches survive planning.

Preserve B20 motif/history receipt ownership and RNG, B21 template physical
admission/current4-cell spacing, all objective/progression/escape constraints,
sector budgets/maxima, first-encounter exception,0.5 allowance,target80/ceiling96.
No new hooks or runtime owner. No wanderer, Big Loot, Event or audit implementation.

## Finite observable gate

- Production graph fixtures prove each ordered band, branches, gated/disconnected
  routes and same-sector isolation; named RNG and repeated plans reproduce.
- Real BuildPlan admits no quiet/recovery home, actually changes locations versus
  pacing-disabled control, and makes probes smaller than full-scale equivalents
  without losing specialist/companion identity. Objectives stay byte-equivalent.
- Keep unchanged32x20 sequential campaigns/parties1–4, all54 exposure floors
  25planned/20legal/5early, minimum36/54 per campaign, memory coverage above control,
  topology/admission/spacing and budget checks. Add pacing assertions to every plan.
- In that sample all three phrases and all four bands occur; at least90% of
  dungeons contain both probe and pressure/spike encounters; mean probe threat
  is below mean pressure/spike threat; every campaign has branch spikes. Record
  reservation cell counts and encounter/threat distribution, not native sightings.
- Preserve512 independent geometry/companion checks. Targeted tests while editing,
  then one stable canonical integration run; retain failed evidence without
  weakening geometry or exposure/pacing thresholds to hide failures.
- Update/readback live GDD00/01/05/06/07; manual, ledger, plan, handoff and registry;
  commit, non-forced push, remote SHA/parent/tree verification.

Native Source acceptance follows ordered phases/audits. B23 remains wandering
population ecology; complete campaign/whole-phase exit proof also remains before
Bestiary may end. No VPS deployment or Workshop publication.
