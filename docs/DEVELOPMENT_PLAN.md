# Current development plan

`main` is the canonical development baseline. Shael explicitly approved candidate
`87920e5ba3b27d46ff096f5a85cd41030a77f964` for promotion on 2026-09-14;
that exact commit was fast-forwarded to remote `main` without code changes.

Astra / Work is the primary implementation and senior-engineering environment.
Sol complements it with architecture, review, planning, and bounded implementation
where useful. Antigravity and `hybrid/antigravity` are retired as active development
workers/workflows. See [Development workflow](DEVELOPMENT_WORKFLOW.md).

## Next scope

Shael's Equipment handoff explicitly promotes Equipment implementation ahead of
public deployment. Work is isolated on `astra/equipment-update`; main remains the
accepted RPG baseline. Workshop and public VPS are held until Equipment and Enemy
are both complete, followed by separately authorized deployment.

The first checkpoint implements Healing Potion/Throwable behavior and removes
ordinary grenade acquisition. See [checkpoint](EQUIPMENT_CHECKPOINT.md) for scope,
validation and the finite human test. The Equipment milestone is not complete:
procedural wearables/economy, Block, Special Moves and Stink Bomb need the missing
authored rules listed in [design proposal](EQUIPMENT_DESIGN_PROPOSAL.md). This
proposal is unapproved and must not be treated as canonical game law.

Preserve accepted RPG behavior and the current workflow. Do not restart the old
hybrid/Antigravity process. The broader Instruction Booklet reconciliation and
outstanding RPG multiplayer release validation remain required before deployment.

## History

The [pre-promotion plan](DEVELOPMENT_PLAN_HISTORICAL_2026_09_14.md) preserves earlier
checkpoint sequencing and candidate handoffs. It is historical evidence, not the
current task queue. [Development status](DEVELOPMENT_STATUS.md) records promotion
and validation. The live GDD remains design authority.

