# Equipment decisions needed to complete the milestone

**Approved for implementation by Shael Riley on 2026-09-14.**

Approval: “You may implement your proposal.” The live GDD records these decisions
in LOD-EQUIP-015. The table below preserves the proposal as approved; provisional
balance language does not constitute runtime acceptance.

The live GDD defines the architecture but leaves Block semantics, the property
catalog/value economy, initial Special Moves and Stink Bomb behavior unset.
AGENTS.md §4 and live GDD LOD-TUNE-001 / LOD-IMPL-006 prohibit inventing these
rules during implementation. The Throwable handoff separately authorizes choosing
small coherent potion impact details; that discretion was used for direct ally
healing, documented in LOD-EQUIP-012..014 and the tuning registry.

Approval of the proposal below authorizes authoring and implementing this
bounded first catalog, followed by ordinary human balance testing. It would not
authorize public deployment or declare Equipment complete.

| Decision | Proposed first implementation |
| --- | --- |
| Block | Shared defender roll after failed Dodge, once per attack event. Physical bullets and melee only; no status ticks, falls or environmental damage. Sum equipped contributions, cap at 33%. Success cancels that attack's HP damage and hit-applied control. Roll and outcome use the existing Die Log; one metallic cue and brief shield flash. |
| Initial passive properties | Six ability-score deltas through the existing `equipmentAbilityDelta` authority, plus shield Block contribution. No Max Magic, duplicated feats or independent evasion rolls. Expand to additional properties only after this catalog is stable. |
| Ability value | Reuse the GDD's suggested 10 value points per ability point. Propose 5 value points per percentage point of Block. |
| Budget | Provisional single-position budget `10 + 2 × floor((clamp(DungeonLevel,1,100)-1)/5)`. Paired gloves receive twice this budget. This continues past Hero Level 20; the safety cap remains provisional until playtested. |
| Property bounds | At most three positive records and one drawback per item; absolute ability change at most 6 per property. A drawback refunds at most 25% of the item's original budget. No opposite-sign records for the same ability. |
| Acquisition | A 25% independently seeded conversion of an existing optional weapon/cache reward into a wearable, preserving individualized ownership and the outer useful-drop roll. Keep mandatory starters unchanged. |
| Naming | Slot-valid nouns with thematic provenance/qualifier; mechanically suggestive epithets must be generated from actual properties. No NPC ownership claim. |
| Replacement | Automatic acquisition/equip into a free compatible slot; occupied positions require one E acceptance and show actual modifiers plus the shared value comparison. Destroy the replaced record on accepted world-pickup swap; never create a duplicate ground item. Gloves compare against both displaced hand items. |
| Initial Special Move: Quickstep | Feet property; UP, UP, UP; 10 Magic; 2-second cooldown. Forward voluntary dash through the shared movement/collision authority, proposed 90-unit travel over 0.2 seconds. Normal speed-qualified Dodge applies. |
| Initial Special Move: Rebuff | Ring property; LEFT, DOWN, RIGHT; 20 Magic; 4-second cooldown. Existing one-cell area authority, one 1d6 nonelemental Magic attack and a proposed 96-unit shared Push per eligible target. Canonical dice, WIS, resistance and control rules apply. |
| Special Move values | Quickstep 20 item-value points; Rebuff 30. Duplicate grants expose one move. Exact signatures are unique. 0.8-second inter-token timeout; physical arrow keys plus the GDD's rebindable punctuation mirror. No controller tokens, menu/chat input, or simultaneous Throwable activation. |
| Stink Bomb | Throw-only. Proposed 96-unit impact cloud, five-second duration, no direct explosion damage. Living enemy entrants receive the existing canonical Poisoned status through its shared authority, once per cloud/target. No drinking, ally poisoning, mystery identification or independent poison implementation. Exact potency must reference the current status catalog before implementation. |

The finite next gate is a real wearable drop → comparison → swap → derived-stat
change; shared Block; both simultaneously granted Special Moves; and Stink Bomb,
with lifecycle/ownership and existing RPG tests passing. Human playtest then
checks balance, input recognition and audiovisual readability. Enemy work follows
Equipment completion, while Workshop and VPS remain held.
