# Equipment, Debbie exchanges and Magic — 2026-09-18

Implemented on `main` from remote `cace700324ceda5372de81468928c7a4ab91ef1b`, preserving the previously committed local equipment repair `402ecb2`. The explicit six-part author request governs this pass. Live GDD navigation: 00 → 01 → 03, 06, 07; current author instructions supersede the older single selected Form, Wisdom-sized Wall and first-impact Watermelon rules. No deployment or Workshop publication is included.

## Implementation

- **O and shared screens:** preserves the recovered Equipment repair's common page router, focused-frame key forwarding, debounced toggle, rebound key, embedded manual bridge, and chat/text-entry safeguards. Character, Spellbook, Equipment, Die Log, Wallet and Manual remain mutually exclusive; delayed snapshots cannot reopen dismissed pages.
- **Capacity:** `Equipment:StorageCapacity` is the sole equipment admission/count authority. The server includes its resolved capacity in owner snapshots; pickup, fusion admission and inventory vacancies share it. Current authored gear/perks have no slot modifiers: baseline is 32 records, including equipped items. Character-owned capacity deltas have expansion/shrink coverage. A shrink preserves and labels overflow, exposes no phantom vacancy, and refuses new admission until space exists. Consumables retain separate bounded stacks. Existing transition/reconnect ownership is preserved.
- **Debbie:** four explicit actions—Fuse Equipment, Sell Equipment, Fuse DFTs, Sell DFTs—use one drag/click pile and conspicuous confirmation workflow. DFT recreation remains accessible in the collection. Staging holds references only; closing or switching action never removes items. Equipped items are unequipped only after successful settlement. Prices and ownership are recalculated server-side. Requests have response correlation, duplicate/ownership checks, rate bounds and an immutable SQLite ledger; failed writes preserve originals.
- **DFT safeguards:** recreated gear retains server-owned `recreatedFrom`, recreated identity and economy exclusion through character persistence. Both exchanges reject it, including mixed piles and legacy recreated IDs. DFT fusion consumes owned tokens transactionally and creates one persistent upgraded DFT. If any input has used its current-run recreation, the output inherits that restriction; fusion cannot refresh free equipment. Selling that token never removes provenance from its already-created gear.
- **Wall:** the supplied 17-second video shows repeated ground rejections while aiming at nearby floors. The codebase's generated-floor support audit already uses a small feet hull because thin line probes are unreliable for scripted SOLID_BBOX slabs. Wall now follows that support approach. Ground miss, embedded anchor, steep slope, excessive reach, cover, narrow gap and insufficient ceiling/space have distinct reasons. Server preview and cast use the same solver, including auxiliary-button Wall bindings. Collision checks still reject enemy occupancy and solid overlap; Heroes pass through; no navigation/grid occupancy requirement was introduced.
- **Watermelon:** the existing swept projectile owns movement and lifetime. A non-exploding server 1d6, recorded in the shared event stream, sets its bounce limit. Incoming impacts consume bounces; outgoing repeated contacts cannot. Contact and final area damage use the shared combat pipeline and sealed cast context. Per-target cooldown and once-per-cast Content riders prevent collision multiplication. The final shatter is idempotent. Bounces have a soft impact sound and green pulse; final impact keeps rind/flesh/seed effects. No physics gibs or external assets.
- **Bindings:** character progression owns a persisted map for RMB/M3/M4/M5. LMB/RMB selection binds RMB; auxiliary selection binds its actual button. Moving an already-bound Form to an occupied button swaps them, preserving unique bindings. Restricted/lost Forms are removed from the map. One-Form characters retain RMB. Every button enters the same server cast validation, Magic cost, cooldown and throwable-priority path. Menus/text entry block casts; held clicks must release before casting after a menu closes. Assigned auxiliary keys suppress native bind actions.

## Tuning decisions

| Rule | Implemented value |
| --- | --- |
| Wall maximum dimensions | 288 wide × 112 high × 12 thick; fitted to obstacles, minimum width/height 48 |
| Wall duration | 10 + 2 × max(WIS modifier, 0) seconds, capped at 30; width independent of Wisdom |
| Wall range / concurrent count | Existing 240 reach, one per caster, 16 global; existing 35 Magic cost retained |
| Wall ground support | 4×4×2 hull, player-movement collision group, existing 512 downward probe and exposed-ground range check |
| Watermelon launch / gravity | Existing 580 speed + 240 upward lift; 600 gravity |
| Watermelon bounces | Server 1d6; 78% reflected velocity; minimum 220 upward rebound on floors |
| Watermelon damage | 1d6 contact, 0.35-second per-target interval; 2d6 final area, one Content rider per damaged target per cast |
| Watermelon limits | 8 seconds, 4,000 traveled units, four swept collision steps per tick; existing 24 Magic cost |
| Watermelon area | 72 base radius plus existing Wisdom/Astral spatial contribution; Bomb retains 96 base radius and 3d6 immediate area damage |
| Fusion | 2–8 inputs, canonical generated output worth 85–100% combined value **and greater than every individual input**; otherwise reject intact |
| Sales | 1–8 inputs, canonical value in $DEB; no lifetime-score increase |

An expiry/range limit shatters; sky exit, invalid caster/run, or an embedded origin retires without unsafe damage through cover. Generation still uses the existing LuaJIT crash safeguard. Binding lifetime follows the character: menu, ordinary death, dungeon transition and reconnect preserve it; a fresh campaign/character gets its own defaults.

## Automated evidence

`python3 -u tools/test_checkpoint_g_integration.py`: **116/116 suites pass**. Includes full Lua syntax, release wiring, manual consistency, existing gameplay/native-crash regressions and `git diff --check`.

New/expanded production-path coverage:

- actual VGUI drag/drop and all four action requests; cancel/action switch; disabled DFT gear; duplicate confirmation and mismatched response; 640px and normal layout;
- real SQLite sale/fusion rollback, two-owner isolation, missing/duplicate IDs, repeated settlement, DFT fusion value/used-recreation inheritance and database reopen;
- exact vacancies at full/partial capacity, equipment swaps, dynamic expansion/shrink, retained overflow, pickup/fusion admission and state roundtrip;
- 84 deterministic Wall aim angles, grazing crates, high eye, low ceiling, ledges, vertical aim, generated-floor line-miss regression, cover/occupancy and identical preview/cast bounds;
- actual projectile stepping through floor geometry for every bounce result 1–6, incoming-only contacts, repeated-hit cooldown, rider suppression, one final area hit, timeout/death/level/embed/sky retirement;
- four independent bound Form resolutions, rebind swaps, restriction migration, snapshot roundtrip, one-Form behavior, actual selector mouse events and casting suppression across menus/text/throwables.

The new Watermelon and mouse-binding suites are registered in the integrated gate. Existing tests with superseded single-impact/width assumptions were updated to the new explicit rules; existing rollback, input, cover, lifecycle and combat gates remain.

## Native acceptance still required

No Garry's Mod client or multiplayer server was run in this environment. Headless Source/VGUI boundary doubles and SQLite tests establish automated behavior, not native sound/rendering, real input delivery, network latency or final combat feel. The supplied video is evidence of the prior failure, not evidence that this candidate fixes native play.

One combined `gm_flatgrass` session with two players: switch P/I/O/L/Wallet/Manual while testing text entry; use Debbie's four actions and cancel a staged pile; recreate a DFT and verify its gear is ineligible; select Wall and Watermelon, bind Forms across RMB/M3/M4/M5, place a wall on ordinary corridor floor and against invalid cover, then throw Watermelons and observe the logged bounce budget/shatter. Reconnect one player and verify their own bindings, inventory and wallet. Existing admin setup: `lod_developer_mode 1; lod_magic_test_all`; wallet settlement requires a ranked staging session, so perform economy checks before enabling developer mode. Collect `console_latest.txt` and `rpg_summary_latest.txt`.

## Follow-up — hold to aim, release to place

The author's subsequent direction changes Wall input on every supported binding:
press/hold RMB, M3, M4 or M5 to show the existing authoritative preview; release
that button to send one cast request. Merely equipping Wall displays no plane or
hint. Release hides the guide immediately, even when its last server packet is
still fresh. The ready hint explicitly names the button to release. Other Forms
retain press-to-cast behavior; server placement/cost/cooldown validation is unchanged.

Menus, text entry, throwable priority, death, losing/rebinding Wall, or map cleanup
cancel the armed gesture without a release cast. Holding through a cancelled
state cannot re-arm it; a fresh press is required. The shared input and preview
regressions exercise all four buttons, single release/no repeat, every cancellation,
and idle/held/released rendering. The canonical manual and Spellbook hint agree.
Fresh full integrated gate after this follow-up: **116/116 suites pass**.
Native GMod input/visual acceptance remains pending.
