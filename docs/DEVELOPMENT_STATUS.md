# Development status — approved main baseline

## Promotion — 2026-09-14

Shael: “Let's promote this build to main. I think that it's ready.”

- Approved and tested candidate: `87920e5ba3b27d46ff096f5a85cd41030a77f964`.
- Previous main: `f7da934b33d250e4d7e032f6d66f404d0f80f4ac`.
- Main was an ancestor of the candidate; no untested commits appeared above it.
- Remote main was fast-forwarded to the exact approved candidate and verified.
- Subsequent retirement changes affect Markdown documentation only; game, asset,
  installer and validator contents remain identical to the approved candidate.
- Antigravity and hybrid development are retired; the published branch/history
  are retained. Main is the baseline; Astra / Work leads implementation, and Sol
  complements architecture/review/planning and selected bounded work.
- No server or Workshop deployment was performed or authorized by this promotion.

## Evidence and validation

The approved tree passed all 56 integrated suites before and after promotion,
including diff check, project Lua syntax and the approved 150-entry feat inventory
with zero blank descriptions. Static success is distinct from Source acceptance.

Shael's Fighter and Wizard recordings/logs show first-dungeon completion, core
runtime validator PASS, correct three-round AR2 bursts and no recorded LoD Lua
exception or reliable-channel overflow. The Wizard run contains 28 successful
Diversion transactions totaling 52 HP and one Feedback retaliation for 4 damage.
Both reaction labels/particles are visible together at about 7:06. All 34 major
FX packets were acknowledged. Twenty Dodges now correctly appear in telemetry.
The sounds' subjective clarity was not independently established by log receipt.

Main approval is explicit. It does not imply unobserved multiplayer lifecycle or
all-Form runtime coverage, or completion of the final manual/deployment gate.
See [current plan](DEVELOPMENT_PLAN.md) for the remaining release scope and
[workflow](DEVELOPMENT_WORKFLOW.md) for current procedure.

## Historical evidence

- [Pre-promotion status ledger](DEVELOPMENT_STATUS_HISTORICAL_2026_09_14.md)
- [Fighter playtest review and repairs](PLAYTEST_2026_09_14_2007.md)
- [Wizard reaction implementation](WIZARD_REACTION_REPAIR.md)
- [Final implementation cleanup](IMPLEMENTATION_CLEANUP.md)

Older documents' “awaiting acceptance” and “current candidate” statements describe
those checkpoints; they do not override the promotion recorded above.
