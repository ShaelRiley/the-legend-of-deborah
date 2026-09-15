# Equipment body map and icon inventory

Development candidate: `astra/equipment-update`. Authority: live GDD
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, tab 06, LOD-UI-008;
existing procedural ownership and slot rules remain unchanged.

The Equipment page now has a left body map and a right scrollable inventory of
owned weapon, wearable and consumable tiles. Lightweight code-drawn silhouettes
identify item families without new models, textures or network messages. Tiles
show stack counts and worn/active markers; selection exposes the full procedural
name, properties, value, compatible positions and replacement information.

Drag onto a compatible position, or select an item and click its destination.
Rings choose either hand, gloves occupy both, and shields use the left-arm slot.
Drag worn clothing back into inventory or right-click its slot to unequip.
The weapon position selects an owned native weapon. All consumables use Throwable;
Hold Throwable readies an equipped potion. Discard remains explicit and confirmed.
Block, Special Moves and key bindings remain below the body map in the scroll area.

All changes use existing server equipment validation. The client waits for owner
snapshots; it preserves the outer window and scroll panels and defers tile rebuilds
while dragging. Magic-stat snapshots also retain the open Equipment page. Unequip
and activation requests check the expected item identity to reject stale actions.

## Evidence and finite Source gate

All 74 integrated automated suites pass, including production slot/transaction
logic, client drag/drop, paired gloves, invalid/stale actions, retained window and
scroll positions, small-screen geometry, transport deltas and Lua syntax. Family
icons were rendered from the production drawing routine for visual inspection.
There is no Source renderer or real-network performance measurement in this check.

Open Player Menu → Equipment during the combined playtest. Confirm the body slots and
item grid are readable; drag a wearable to its slot and back, then equip a potion
in Throwable. A screenshot suffices for a layout defect. Existing equipment,
portrait, wallet and enemy runtime gates remain in their checkpoint documents;
this checkpoint does not imply their in-game acceptance or authorize deployment.
