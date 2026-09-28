# Big Event System Events Update

The supplied `briefs/EVENT_SYSTEM_UPDATE.md` promotes this bounded update from
verified main `1685774415ea8bbd82abf931999a29ae7ba25f10`. The frozen baseline is
**8 meaningful production archetypes**, not the brief's historical six. This
update adds **20**, yielding **28 (3.5×)**. Bribe remains removed.

## Catalog and player decisions

Every event uses existing Source models and the existing event entity. No new
required image, material, sound, workshop dependency or hostile roster is added.
All additions are optional and topology-neutral; the existing Skeleton remains
the sole required-route blockade. The table describes gameplay identities, not
cosmetic variants. All are available from Dungeon1 except Warp Hole (Dungeon5).

| ID | Name / decision | Contract | Ownership | Rarity |
|---|---|---|---|---|
| slot_machine | Debbie Slots: stake5 $DEB on its fixed d4 odds | UTILITY | Personal account/dungeon | Common |
| locked_chest | Locked Loot Chest: key or Rogue pick for wearable | REWARD | Personal account/dungeon | Common |
| treasure_chest | DFT Treasure: key or pick,1–2 independently claimed members | REWARD | Personal account/member/dungeon | Rare |
| vending_machine | Debbie Vending:10 $DEB for one Healing Potion | UTILITY | Personal account/dungeon | Common |
| false_floor | Avoid or trigger a physical one-floor drop | HAZARD | Repeatable shared geometry | Common |
| warp_hole | Free permanent paired shortcut; safe arrival required | UTILITY | Repeatable shared utility | Common |
| skeleton_blockade | Defeat the approachable Skeleton to open the route | BLOCKADE | Party defeat and opening | Common |
| equipment_quiz | Identify worn equipment; DFT success or item theft | REWARD | Personal account/dungeon | Common |
| triage_station | Prison Triage:12 $DEB restores missing HP, not ailments | UTILITY | Personal account/dungeon | Common |
| blood_dynamo | Give10 nonlethal HP for up to25 Magic | UTILITY | Personal account/dungeon | Common |
| salvage_press | Destroy a reviewed spare wearable for its canonical $DEB value | UTILITY | Personal account/dungeon | Common |
| reforging_bench | Scavenger Reforge: two reviewed spare wearables for one canonical fusion | UTILITY | Personal account/dungeon | Common |
| key_cutter | One Healing Potion +20 Magic becomes one Chest Key | UTILITY | Personal account/dungeon | Common |
| ammo_transmuter | Spend15 Magic on a large ration for the held eligible firearm | UTILITY | Personal account/dungeon | Common |
| prisoner_barter | Wounded Scavenger: one Healing Potion for the displayed wearable | UTILITY | Personal account/dungeon | Common |
| overclock_console | Redline Capacitor: full Magic in exchange for30s Reckless | UTILITY | Personal account/dungeon | Common |
| contraband_lot | Contraband Countdown: wait for a lower price or buy before another Hero | UTILITY | First buyer; one party lot | Rare |
| life_underwriter | Surrender a reserve life for40 $DEB; final life protected | UTILITY | Personal account/dungeon | Rare |
| steam_vent | Avoid timed steam or seal it; WIS DC12 vs2s Muted | HAZARD | Party disable; personal saves | Common |
| stasis_beacon | Crouch past or disable; DEX DC12 vs2s Clumsy | HAZARD | Party disable; personal saves | Common |
| watchful_eye | Avert gaze and circle behind to unplug; WIS DC12 vs3s Reckless | HAZARD | Party disable; personal saves | Common |
| prison_surveyor | Ask an imprisoned surveyor for the current legal objective route | UTILITY | Personal repeatable information | Common |
| counterweight_cache | Two Heroes hold plates3s, or solo lever10s; each collects15 $DEB | REWARD | Shared unlock; personal claim | Common |
| relay_race | Touch markers1→2→3 within12s; collect15 $DEB | REWARD | Personal account/dungeon | Common |
| memory_terminal | Observe three lights and repeat their sequence for15 $DEB | REWARD | Personal account/dungeon | Common |
| nerve_clock | Stop on green for20 $DEB; red spends attempt and risks3s Reckless | REWARD | Personal account/dungeon | Common |
| strength_press | One1d20 + canonical STR modifier vs12;20 $DEB on success | REWARD | Personal account/dungeon | Common |
| silent_archive | Stand grounded, still and quiet4s to restore up to25 Magic | UTILITY | Personal account/dungeon | Common |

Totals: **8 REWARD,1 BLOCKADE,4 HAZARD,15 UTILITY;25 common and3 rare**.
Persistent $DEB/DFTs use the existing server-local wallet and immutable ledger.
Equipment, HP, Magic, ammunition, lives and statuses retain their ordinary Hero
or dungeon lifetimes. A spent opportunity is never replenished by reconnecting,
changing Heroes, selling a reward or regenerating the same dungeon.

## Selection, memory and placement

The existing non-exploding `dungeon-events:count:v1` stream still rolls exactly
1–4 distinct archetypes. Counts1–3 contain common events. Count4 contains three
common events and exactly one of DFT Treasure, Contraband Countdown or Life
Underwriter. Thus the rare *slot* retains its25% marginal count probability;
DFT Treasure is no longer guaranteed on every4. Rarity never adds a fifth event.
Treasure's independently seeded1–2 members and Warp's paired endpoints still
count once. No count reduction, duplicate substitute or placement reroll exists.

Selection layers eligible identities, weighted families and weighted identities,
with complementary source/sink/risk/recovery/information roles. Family weights
are averages, so registering many siblings does not automatically increase that
family's share. Actual EncounterDirector motifs (Corruption, Crossfire, Hunting,
Occupation, Quarantine, Retinue) bias authored affinities; there is no competing
event-theme generator. Selection can deliberately omit any common family.

`Run.State.EventEcology` records four recent successful full dungeons plus bounded
appearance counts/last-seen levels. A receipt binds the exact state, graph, run,
epoch, campaign, level, level seed and previous history. Only successful completed
BuildReady generation commits exposure. Rebuilding the same level reuses its
before-history; failed construction, previews and disabled population do not
advance history. New campaigns do not inherit it.

Tuning: unseen identity×2; identity frequency÷(1+.15 appearances); neglected
identity grows+.075 per absent level after3, capped at8 increments; immediately
previous identity×.04 and older recent identity×.65. Repeated current-floor
contract×.65, previous-floor contract×.9, complementary role×1.3. Family repetition
within a floor×.18, frequency÷(1+.08 appearances), previous-floor family×.6.
Counters saturate at1,000,000. Family/identity streams have separate purpose and
slot labels and bounded warmups to prevent correlated first-draw quantiles in
the existing affine seed derivation. Maze, encounter, loot and combat RNG are
never consumed by these draws.

Placement prefers real dead ends, optional branches, corridor/junction shape,
vertical context and structural distance from objectives/encounters. These are
preferences, not claims of line of sight or unlocked traversal. All candidates
still pass the existing graph-copy mutation guard, protected-cell and combined
route proofs within64 source attempts. Paired/drop events retain their bounded
destination search and equivalent ordered-stage reachability plus ordinary
return proofs. The Skeleton's earliest-approach combat proof never assumes
currency, gear, class or resources behind the blockade. Rejected complete builds
retain their selected identities and count.

## Interactions and settlement

Services first review the exact offer, then confirm with Use within12s. Review
binds the Hero/account/body, exact inventory reference/content and displayed
inputs/result/price. Changes refresh the offer. Protected/starting/DFT gear is
excluded from salvage and reforge. Full bags or stacks consume nothing.
Contraband's bounded monotonic current-level market clock survives regeneration;
its price declines to a floor without Hourglass or Time Management resetting it.

The small shared `EventTransactions` adapter composes existing CryptoStore and
detached Equipment settlement; it creates no new wallet or inventory. Immutable
account/campaign/dungeon/archetype receipts survive layout and body replacement.
Inventory and Lua resource swaps occur in the existing transaction participant,
after validation and before COMMIT. Immediate native HP/ammo/status effects use
exact-owner compensation on failure. Feedback runs after settlement; failed
sound, packet or report callbacks cannot refund or duplicate a committed result.
Claim/read/storage failures fail closed. One account pays and receives a shared
lot; concurrent Heroes cannot both claim it.

Incidents use the existing shared director tick, at most once every.25s per
active instance. All footprints fit inside their reserved flat cells. Exact
actor/body/role, event parts, graph, clock, range and sight are checked around
native calls. Hazards use canonical saves/statuses, do not extend existing
conditions, and remove only their own still-identical entries. They are avoidable
and cannot close progression routes. Steam cycles4s safe/1s warning/1s active;
hazard range64, with vent/beacon/eye contact cooldowns6/3/6s.

Memory shows only the present clue in recipient snapshots, never the sequence or
future answer. Answer window30s; wrong inputs reset freely. Nerve uses a4s cycle
(3 red/1 green),12s interaction window and a frozen result on settlement retry.
Strength uses a stable account/dungeon die and freezes the admitted result during
retry. No challenge pauses combat, grants invulnerability or requires two humans.
Teardown invalidates sessions before removing every tracked native part.

## Diagnostics and acceptance

`lod_event_ecology` reports exact count, eligible/excluded catalog and reasons,
rarity, selected family/identity, history/novelty/theme/composition factors,
contract/scope, structural placement reason, attempts/rejections and proof class.
`lod_event_population_preview [seed]` and
`lod_event_preview_generate <id>` keep the existing explicit unranked, real-cost
preview policy. Saved operator opt-outs remain intact.

Selection sample:96 campaigns×20 dungeons paired with history-disabled control,
using the actual encounter motif scheduler and actual28 registered definitions.
History exposes all28 globally, mean24.6875 distinct per campaign (minimum21),
versus20.8021 (minimum14). Immediate repeated identities17 versus701 (97.5749%
reduction); maximum identity streak2 versus10, family streak4 versus10.
All478 rare slots and the exact count sequence match the control. See
`validation/BIG_EVENT_ECOLOGY_SAMPLE.json`; this sample does not measure physical
placement, native frame time or player balance.

The complete headless gate passes **274/274 suites and 784 Lua syntax files**;
see [the validation record](validation/BIG_EVENT_UPDATE.md) for exact evidence.

Native Source acceptance remains pending. On `gm_flatgrass`, start a fresh
campaign with two Heroes. As developer/admin, run
`lod_developer_mode 1; lod_event_population_preview; lod_event_ecology`
and exercise the generated mix. Use successive single-event
previews for `triage_station`, `counterweight_cache`, `skeleton_blockade`,
`steam_vent`, `warp_hole` and `memory_terminal` to fill missing categories. Inspect
actual offers before spending; use existing funds/gear. One Hero reconnects after
a claim; verify spent state and an independent second-Hero claim. Regenerate and
verify old parts/sessions disappear without renewed entitlements. Capture
`console_latest.txt` and `rpg_summary_latest.txt`, plus a short visual/control
observation. These previews do not establish native acceptance by themselves.

The live GDD was read through00→01→05/06/07/90. A revision-guarded edit failed with
Google `FAILED_PRECONDITION`; fresh readback confirmed no mutation. Exact scoped
amendments are retained with validation evidence for application when editing is
restored. The implementation and native/static evidence must not be described as
fully synchronized live design. No Workshop publication or VPS deployment.
