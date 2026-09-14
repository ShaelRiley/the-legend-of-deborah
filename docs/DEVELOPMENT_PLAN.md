# Current development plan

`main` is the canonical development baseline. Shael explicitly approved candidate
`87920e5ba3b27d46ff096f5a85cd41030a77f964` for promotion on 2026-09-14;
that exact commit was fast-forwarded to remote `main` without code changes.

Astra / Work is the primary implementation and senior-engineering environment.
Sol complements it with architecture, review, planning, and bounded implementation
where useful. Antigravity and `hybrid/antigravity` are retired as active development
workers/workflows. See [Development workflow](DEVELOPMENT_WORKFLOW.md).

## Next scope

The RPG Update remains the current release milestone. This main promotion is not
public-server or Workshop deployment. Before a separately authorized deployment,
reconcile the Instruction Booklet with the finished implementation and live GDD,
and close outstanding release validation. The reviewed Fighter/Wizard sessions
exercise solo combat and first-dungeon completion; they do not establish the full
multiplayer death/revival/Soldier/reconnect/late-join matrix or every Magic Form.
These evidence limits were disclosed before Shael approved main promotion.

Use targeted live-GDD AI-tab navigation for new work. Preserve accepted mechanics,
sparse Source-style HUD, shared authorities, deterministic server decisions, and
the integrated gate. Material runtime changes after approval require fresh
validation and appropriate human acceptance; prior approval is not blanket
approval of future builds. Do not implement deferred Equipment/Enemy milestones
without a new scope instruction.

## History

The [pre-promotion plan](DEVELOPMENT_PLAN_HISTORICAL_2026_09_14.md) preserves earlier
checkpoint sequencing and candidate handoffs. It is historical evidence, not the
current task queue. [Development status](DEVELOPMENT_STATUS.md) records promotion
and validation. The live GDD remains design authority.
