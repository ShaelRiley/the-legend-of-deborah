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

Shael's 2026-09-15 direction expands the approved first equipment catalog into a
unified procedural weapon/wearable economy and explicitly authorizes its missing
formulas. Live GDD LOD-EQUIP-016 owns the new 60-property catalog, budget/rarity
curves, active-weapon contributions, statuses and acquisition behavior. Earlier
LOD-EQUIP-015 Block, Throwable and Special Move semantics remain in force.
See [economy rules and handoff](PROCEDURAL_ITEM_ECONOMY.md) and
[checkpoint](EQUIPMENT_CHECKPOINT.md). Equipment runtime acceptance remains pending;
do not proceed into Enemy work or promote main on static evidence alone.

The subsequent 2026-09-15 completion assessment found and repaired a real
Equipment blocker: full procedural pickup records exceeded the engine's
NW2String limit, breaking comparison data. Owner-checked inspection messages now
carry the complete record, with production server/client transport tests; all
66 integrated suites pass. See [completion assessment](EQUIPMENT_ASSESSMENT.md).
The user's conditional Enemy instruction remains next after Equipment completion;
this repair does not establish the still-missing in-game acceptance evidence.

Preserve accepted RPG behavior and the current workflow. Do not restart the old
hybrid/Antigravity process. The broader Instruction Booklet reconciliation and
outstanding RPG multiplayer release validation remain required before deployment.

## History

The subsequent user-requested [identity perk correction](PERK_UPDATE.md) is a
bounded detour on the same Equipment development branch. Independent category
rolls and duplicate stacking are retained and explicitly tested; new ability
perks support +2 or +1/+1, and every visible title/flavor follows the resolved
mechanics. Existing Heroes keep their permanent rolls. All 66 integrated suites
pass; Equipment runtime acceptance and Enemy sequencing otherwise remain as above.

The [pre-promotion plan](DEVELOPMENT_PLAN_HISTORICAL_2026_09_14.md) preserves earlier
checkpoint sequencing and candidate handoffs. It is historical evidence, not the
current task queue. [Development status](DEVELOPMENT_STATUS.md) records promotion
and validation. The live GDD remains design authority.
