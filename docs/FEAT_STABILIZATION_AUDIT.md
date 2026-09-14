# Active stabilization checkpoint — 2026-09-14

This tranche continues `889d6e4e4e67a590d9d018d100a2a4c9055f2c1a` on
`hybrid/antigravity`. It is a preserved engineering checkpoint, not yet the
human-acceptance handoff. Main promotion remains blocked on Shael's exact-SHA approval.

Shael approved the scope reductions and confirmed all ordinary ability gates are
13/15/17. Deferred: Calculated Luck, Lucky Break, Point It Out, Rally the Hunt,
Command the Hunt, Polymorph, Aftershock, and previously held Snap Targeting.
The retained live-GDD set is 135 ordinary feats + 6 fallbacks + 9 capstones.

Current results:
- All 150 loaded descriptions are nonblank; exact ordinary-set equality, names,
  requirements and named prerequisites pass against the targeted live-GDD fixture.
- All 135 ordinary feats can enter a legal draft through production capability
  checks. Replaced lower ranks satisfy prerequisite ladders. Missing Form, Summon,
  Morale, grant, and damage-source capability consumers are repaired.
- Implemented the six retained CROSS feats and shared movement-qualified Dodge.
  Now You See Me contributes to that shared roll; the independent evasion path is gone.
- Repaired Terrifying's first-encounter lower-of-two save, Panic graph radius and
  recursion/cooldown guards, actor-life cleanup, and per-actor Magic pools.
- Blast-Proof resolves defender-specific views of immutable shared rolls, including
  pre-rolled weapon attacks. Its old global-target wrappers and delayed test callbacks
  are removed. Shotgun pellets settle once per target before defenses and flat bonuses.
- Damage reporting observes final damage after Dodge/diversion. Seeker damage now
  reaches shared rules and final reporting. Push, aura faction targeting, Glow Up,
  AI weapon capabilities and Aggressive Personality's positive-damage trigger repaired.
- Sparse live HUD/menu distinction preserved.

Validation: `git diff --check`, project Lua syntax, and the complete integrated
`python3 tools/test_checkpoint_g_integration.py` gate pass: **49/49 suites**.
New production-seam checks cover CROSS mechanics, Dodge aggregation, Morale,
Blast-Proof target isolation, offerability and lifecycle reset. Static checks do not
certify Source behavior or complete semantic parity.

Remaining before candidate handoff: targeted regressions for final shotgun/CHA
settlement and graph fear behavior; legacy ownership/draft reconciliation; final
consumer/actor audit and integrated review. Continue development without asking
Shael to accept this intermediate checkpoint.

---

The previous checkpoint report below is preserved as historical evidence. Its
missing-feat counts and independent-Dodge blocker are superseded by the active
status above.

# Hybrid feat stabilization checkpoint — 2026-09-14

**Release blocked. This checkpoint is not an acceptance candidate.**

Continues published `hybrid/antigravity` at `7f05740825a54af5ec620c0d20196cad0f4e109e`.
`main`, public server, Workshop, and workflow retirement are untouched. Shael's
explicit approval of an exact tested candidate remains required before promotion.

## Repairs in this checkpoint

- Filled 37 blank ordinary-feat descriptions at their defining authorities.
  The loaded 129 ordinary feats, 6 fallbacks, and 9 capstones now have zero blanks.
- Replaced misleading generic descriptions for the three Menace, Summon-management,
  and Haste ranks with their exact individual rules, including their actual numbers.
- Removed 320/360-character truncation from offered/owned feat and capstone snapshots.
  Existing wrapped, scrolling inspection cards receive complete descriptions.
- Restored additive Fighter regeneration: innate 33% plus the highest CON family
  contribution (11/22/33%), preserving the five-second delay, CON-scaled rate and
  overfill exclusion. Other classes have no innate contribution.
- Corrected Mana Barrier acquisition requirements from INT 12/16/18 to 13/15/17.
- Consolidated diversion arithmetic into Gate D. Wizard class Shield rounds desired
  diverted HP upward before affordability, capped by incoming damage; the exact
  non-Wizard Mana Barrier rows retain continuous diversion. Fractional Magic remains
  legal. `ignoreManaBarrier` bypasses diversion. Living Aegis improves funding
  efficiency to 1.50 HP/Magic without an invented extra diversion fraction.
- Removed the Wisdom-defense gamemode wrapper. Gate D invokes that authority after
  upstream cancellation and before diversion. The damage wrapper preserves its
  upstream return value and stops on cancellation.
- Not Yet immunity cancels damage before Shield spending or Wisdom-defense cooldowns;
  the lethal intercept still runs after diversion. Its immunity query checks both
  the current progression identity and dungeon, preventing an old entity field from
  granting immunity to a replacement identity or next dungeon.
- Corrected obsolete Wizard validation expectations instead of filtering their
  failures out of the validator.
- Preserved the existing sparse live HUD and paper inspection/menu surfaces.

## Evidence and remaining release blockers

Targeted live-GDD snapshot: `tools/fixtures/live_gdd_feats.json`, from document
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`; revision recorded in that fixture.
Navigation followed AI 00 → 01 → relevant normalized rules → exact feat rows.
Enumeration includes all six ability prefixes **and CROSS and FALLBACK**; counting
only the ability-prefixed rows silently omits seven cross-ability feats.

The current GDD enumerates 143 ordinary/cross feats. Snap Targeting remains explicitly
held over its previously reported timing contradiction, leaving **142 expected
active ordinary/cross feats versus 129 loaded**. The 13 missing definitions are:

- Aftershock; Polymorph; Calculated Luck.
- Point It Out; Rally the Hunt; Command the Hunt.
- Meteor Strike; Tiny Terror; Big Scary; Crash the Party; Boom Battery;
  Force of Will; Lucky Break.

Now You See Me also still implements an independent 20% evasion roll instead of
contributing to the shared movement-gated Dodge authority. Its description/runtime
must be reconciled together, including event aggregation, AI/Soldier parity,
voluntary movement qualification, control suppression and truthful feedback.

The missing Luck-related and spotting feats have missing underlying consumers too;
adding catalog entries would not repair them. Aftershock requires committed-cast
snapshots, delayed geometry and resource/feedback parity. Polymorph requires an
actor-state transition spanning actions, targeting, movement, resource recovery and
lifecycle. These are implementation blockers, not requests to invent new rules.

Additional audit work remains: complete per-feat consumer/actor/lifecycle tracing,
full description-to-behavior reconciliation, capstone parity for non-player actors,
legacy ownership/draft migration, and broader lifecycle/efficiency review. The new
static inventory checks do **not** establish those properties and do not constitute
a completed canonical feat audit.

Source reconciliation items are retained explicitly:

- Hero of Legend preserves Shael's WIS 15/non-elemental Magic/global-projectile
  decision rather than reverting to the obsolete STR row. See the prior feat matrix.
- Universal Deadeye preserves the accepted 2026-09-10 runtime behavior documented
  in `SOL_STABILIZATION.md`; the older exact GDD row still describes Magnum-only timing.
- Sixth Sense's row header says WIS 13 while its embedded older sentence says WIS 12.
  Qualification remains 13; the new description avoids repeating the contradictory
  embedded requirement. This discrepancy needs author reconciliation.
- AI 00 explicitly gives Fighter innate regeneration as 33%; older HUMAN feat prose
  still says 22%. The normalized rule takes precedence.
- AI 03's Wizard rounding rule and the explicit continuous non-Wizard Mana Barrier
  rows are implemented separately within the same arithmetic authority.

## Validation

`python3 tools/test_checkpoint_g_integration.py`: **47 of 48 suites pass**;
`git diff --check`, Lua syntax, all prior integrated suites, all 19 additional existing
focused feat-family suites, and the new stabilization regressions pass.
The final live-GDD feat release gate deliberately fails on the 13 omissions and
independent Rogue evasion. It must stay blocking until the actual defects are fixed.

`python3 tools/audit_live_gdd_feats.py` checks canonical inventory equality including
cross feats, names, score requirements, named prerequisites, duplicate IDs,
blank/placeholder descriptions, orphan prerequisites, handler labels, and the known
Dodge discrepancy against the final loaded production include graph. A handler label
is not proof of a reachable implementation; semantic/runtime audit remains necessary.

No Source-runtime playtest was performed here. Do not request acceptance of this
checkpoint or promote it to `main`.
