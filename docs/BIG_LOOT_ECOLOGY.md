# Big Loot: implemented item ecology

Baseline: `fc166870633db5f277165d9c33ae00d82feaa81a`. The author-promoted
`docs/briefs/BIG_LOOT_UPDATE.md` supersedes its former roadmap deferral for this
checkpoint. No Workshop publication or VPS deployment is authorized.

## Vocabulary and composition

The frozen baseline is **45** identities: seven wearable bases, seven weapons,
seven innate special wearables, and 24 consumables/utilities. The update adds
**113** individually authored archetypes, reaching **158 (3.5111×)**. Recolors,
random affix permutations, rarity labels and ordinary magnitudes are excluded.
See [the full catalog](BIG_LOOT_CATALOG.md) for each signature and tradeoff.

There are 72 new wearable archetypes and 41 weapons: ten each for head, body,
legs, feet, paired gloves and shields; twelve rings; six each for pistol, crowbar,
shotgun, SMG, revolver and pulse rifle; five wands. The twelve thematic families
are scavenger, soldier, medic, occultist, dockworker, courier, warden, veteran,
anomaly, survivor, hunter and pilgrim. No set completion is required.

An archetype guarantees two or three existing effects, one elemental affinity
and a specific drawback. Its positive signature is unique even when slot, name,
element and drawback are ignored. Random remaining properties and bounded power
allocation use the existing version-2 generator. Canonical `definitionId` still
owns slots and native weapon class; `archetypeId` adds a stable identity. Existing
version-1/version-2 records retain their exact prior generator and value behavior.
The generator's local LuaJIT exclusion remains installed.

The existing 60-property authority owns effects. Only equipped wearables and the
held weapon contribute; paired gloves count once. Shared combat snapshots, saves,
status applications, movement, elemental ladders, Dodge/Block and aggregate caps
remain authoritative. There are no new combat hooks, recurring item timers,
native models, textures or network channels. Existing asset/tint grammar and
full property inspection communicate identity; the manual now explains build
examples, motifs and tradeoffs.

## Selection and reward placement

`LootDirector.Ecology` extends the existing director. It does not own entities,
pickup admission, currency, progression or equipment state. The ordinary drop
authority still selects the resource/equipment category. Eligible equipment then
uses the contextual archetype selector, with an 8% unconstrained legacy option.
The preceding 1/8 innate-family roll remains intact, keeping existing named
specials in circulation. Mandatory family grants and supplies retain their role.
The final weapon pool includes upgraded pistols and crowbars at every depth,
with revolvers introduced at Dungeon 2 and pulse rifles at Dungeon 3. The existing
half-variant, half-missing-family preference uses that same pool. Late random
enemy rewards also use it; older firearm-only wrappers cannot exclude starters.

Each four-sector level receives motifs from independently seeded ten-sector
bags: scavenged, military, medical, occult, elemental, industrial, mobility,
defensive, unstable and expedition. Bags contain each motif once; the first three
positions of a new bag exclude the preceding three motifs. Unmodified final
three entries make this rule reconstructible from two bags, without replaying
all earlier levels. Rebuilds and out-of-order inspection reproduce the same plan.

Existing optional rewards are placed among the canonical legal reward candidates.
One graph traversal computes distance; candidate weights prefer dead ends,
vertical branches, deeper detours and higher sector encounter pressure. Already
occupied static cells are excluded. Exhausted reward pockets fall back to the
canonical same-sector supply candidates; an optional reward is omitted and counted
only if no legal unoccupied cell remains. No new graph edge,
objective, required item, locked gate, enemy or loot entity is introduced.
Optional reward nodes remain available after Dungeon 10; resource assistance
and its supplements still fade under their existing schedule.

Sector phrases are 20% lean, 60% ordinary scavenging and 20% cache. Lean sectors
retain 55% of newly selected equipment opportunities. Cache phrases increase
Rare-or-higher archetype weight by 1.6. At four or fewer free gear spaces, retention
halves again. A full bag redirects equipment opportunities to usable health,
then ammunition, otherwise no pickup. Existing world rewards stay frozen and
wait for space; they never turn into a different item after inspection.
Phrase seeds include a suffix after their serial to decorrelate the first shared
RNG draw for adjacent sectors.

## Memory, determinism and tuning

The existing player state carries campaign exposure, a 24-result recent history,
and up to 512 compact source receipts per dungeon. Receipts freeze the selected
archetype or original base-generation argument. Reconnects, retries, ownership
changes and same-seed rebuilds cannot select again. Level succession retains
exposure/history but retires receipts. A new campaign resets memory. After 512
receipts, new results use source-only selection without mutable player/history
inputs; old receipts are never evicted. Full item snapshots remain owned by the
existing equipment, chest and DFT ledgers.

| Influence | Implemented weight |
| --- | --- |
| Authored scarcity | 80 / 35 / 9 for minimum Unusual / Rare / Exalted |
| Unseen archetype | ×2 |
| Already exposed | ÷sqrt(1 + 0.25 × appearances) |
| Matching motif | ×2.8 |
| Vertical mobility context | ×1.7 |
| Optional reward, minimum Rare+ | ×1.5 |
| Risk ≥2, minimum Rare+ | ×1.35 |
| Pre-boss medical/defensive role | ×1.5 |
| Owned archetype | ×0.25 |
| Empty slot | ×1.3 |
| Relevant class | ×1.2 |
| Low HP medical / low Magic recovery | ×1.35 / ×1.25 |
| Family absent for ≥3 levels | ×1.5 |
| Same identity within last eight | ×0.06 per occurrence |
| Same family / slot within last four | ×0.60 / ×0.72 per occurrence |
| Overlapping signature effects within last four | ×0.82 per shared effect |

Weights stay positive; essentials are not filtered by novelty. Minimum dungeon
levels gate natural selection, including the advanced weapon bands. Generation
at any legal valuation depth remains valid for fusion. Rarity still controls
4–7 positives, with archetype minimums; all items retain exactly one drawback.
The existing saturation curves, quality range, depth-999 budget clamp and exact
value/budget identity remain unchanged.

DFT minting, nonstarter direct grants and Damsel slot gifts use source-only
archetype selection and freeze their result through existing authorities.
Locked chests use contextual selection and their existing frozen reward/claim.
Fusion chooses a stable archetype independently of the depth binary search;
its result must still be worth 85–100% of combined inputs and exceed each input.
No new currency faucet or inventory capacity is introduced.

## Lifecycle repairs and diagnostics

New native inventory snapshots mark weapon families backed by equipment records.
Restore cannot recreate one after its last owned copy was destroyed or sold.
Another owned copy retains the family's saved magazine; old unmarked snapshots
retain their one-time legacy migration. Carried-item sale/fusion now participates
in the existing SQLite transaction: exact bag, Hero, life and campaign guards
remain valid through COMMIT, and failed commits restore the original bag.

Developer-admin `lod_loot_ecology_status` prints motifs, phrases, static/reward
counts, aggregate enemy/pity/support data and per-player slot/family/rarity/value,
novelty/suppression/replay receipts. `lod_big_loot_testkit [archetypeId]` defaults
to `measured_retreat`, uses normal bag admission, marks the campaign unranked and
marks supplied gear ineligible for sale/fusion.

Headless production tests establish source behavior, deterministic distribution
and transaction invariants. They do not establish native Source physics,
network behavior, visual clarity or subjective balance. Those remain the local
`gm_flatgrass` acceptance gate before any separately authorized release.
