# Current checkpoint — pulse-first music section direction

Fetch current main; this update's parent is
`67cb7dbf7343d05cd52c3f429e33322a8fc30248`, not a later release HEAD.
Read `MUSIC_SECTION_DIRECTION.md` and live GDD 05 `LOD-MUSIC-CUES-001` /
07 `LOD-MUSIC-CUES-IMPL`. The author clarified that rhythmic pulse/quiet state
outranks loudness: easing active danger retains a gentler pulse; true calm
enters and sustains quiet. Offline cue analysis/import and bounded client
section renewal implement this distinction. Buffered pairs are reused;
four channels/two transfers, master Off, frozen plans and one-shot victory remain.

`validation/MUSIC_SECTIONS.md` records all 287 registered checks passing on the
same source across the full matrix and one isolated campaign-timeout rerun;
802 Lua files passed syntax. The evidence retains the original timeout.

The complete gate includes new offline classification and prolonged section
playback tests. Source checks do not certify native musical judgment or seek
latency. New imports acquire cues; legacy cue-less catalogs remain compatible
but need offline reimport at a new version. No actual hosted dance-track catalog
was available to prepare here. Native audition on the exact build is next,
including rising/falling pressure, long pulse/quiet, two floors, full slots,
slow buffering and Off with a pending renewal. Capture `console_latest.txt` and
`rpg_summary_latest.txt`; source publication is distinct from Workshop/VPS release.

---

# Prior checkpoint — low-end PC / Steam Deck source optimization

Fetch current main and preserve intervening work. This checkpoint's exact parent
is `3d60d6f730b56abbf3df5de68bb8d71002d44d96`; do not reuse it as a later HEAD.
The independent delivery receipt supplies the actual child/tree and both frozen
gate results. Read `docs/validation/LOW_END_PC_20260928.md` and the newest
DEVELOPMENT_PLAN overlay before the historical handoffs below.

The three client optimization files provide immutable container floor/palette and
candidate-material reuse, conservative rear-camera static-box culling with
per-pass floor material resolution, and the existing Reduced Effects checkbox.
A fourth production edit adds the missing IsValid guard before the fallen-Hero
damage wrapper reads its target. The old protected harness also gains native
flag/cvar doubles needed by music. The complete gate has 285 suites plus
independent Lua 5.1 production parsing;
source publication is allowed only after matching local/independent green gates.
Keep the initial 279/285 evidence; the final full rerun uses 600 seconds per suite
without shrinking inputs or assertions.
Probe operation counts are not Steam Deck FPS. No population,
skeleton/event/loot behavior, collision geometry or default preference changes.

Next: full restart and ordinary exact-source gm_flatgrass play on Steam Deck,
including turns, stairs, rebuilds and combat. Reduced Effects is optional, not a
prerequisite for the automatic efficiency fixes. Retain previous acceptance debts
and local acceptance → Workshop parity → matching VPS. Do not deploy or publish
Workshop merely because source tests pass. No further implementation is implied
by the old deferred queue or earlier current-checkpoint headers below.

---

# Current checkpoint — September 27 systems audit complete

The author's audit request supersedes earlier deferrals. Source and validation
repairs are published through `864cdf36854c3671926a9473221c74b7ca727fa5` on main;
this closeout changes documentation only. Read `validation/SYSTEMS_AUDIT_20260927.md`
for findings, exact tree/source digest, coverage and the retained failed attempts.

The complete expanded matrix passes **262/262**, including **765 Lua syntax
checks**, with identical source before/after. The original matrix was 228/235.
Minimap cache/request/lifecycle ownership, Muted potion input, duplicate equipment
sync and stale validation contracts are repaired. No automated failure remains.

Next finite gate: exact-build local gm_flatgrass acceptance, including Muted potion
use and map reopening after rebuild/respawn. Retain all previous SPOT,
Soldier/Reckless, stair, stomp, arrow-input, B28/B29 and Crate acceptance constraints.
Native input/network/physics/rendering and co-op acceptance remain open; headless
results do not establish them. Preserve local acceptance -> Workshop parity ->
matching VPS. No Workshop/VPS deployment occurred during this audit. Historical
sequencing below is superseded where it conflicts with this checkpoint.

---

# Current overlay — Heavy Plumber and arrow-input equipment repairs

September 27 author-requested spot fixes preserve main baseline
`38adbce415ae6dd388c28a450bb9cd3b7a8248d2` and all Soldier/Reckless, standing-stair
and SPOT-17 work. Read `docs/validation/EQUIPMENT_STOMP_CONTACT_20260927.md` and
`docs/validation/EQUIPMENT_ARROW_INPUT_20260927.md`; fetch current main and use the
external delivery receipt for exact published commits/tree and independent gate.
First-impact stomp geometry and bounded ordered input transport extend their
existing authorities without changing attack costs, damage or recipes. Native
acceptance remains pending. No Workshop/VPS actions, full campaign-matrix pass,
SPOT-18 or deferred-roadmap work is claimed. Historical sections follow.

---

# Resume The Legend of Deborah — SPOT-17 native acceptance

## Latest overlay — faction / Reckless damage repair

The unnumbered September 27 author-requested repair follows the standing-stair child `0f1e7092644c9c3e5eede39263206b2b5850c707`. Fetch current `main`; use the external delivery receipt for the actual new child/tree and independent gate. Read `docs/validation/FACTION_RECKLESS_DAMAGE.md` before the historical SPOT-17 handoff below. Soldier/ Hero opposition and attacker-only Reckless use the existing faction/status authorities; geometry, owned sources and committed projectile permissions are covered. Native acceptance is still pending. Do not treat source publication as Workshop or VPS deployment; preserve all intervening work.


Repository: ShaelRiley/the-legend-of-deborah, main. The external SPOT-17 delivery
receipt supplies the verified published child/tree and independent Actions run.
Its actual gameplay parent is 9e2601953e8f91469fc3d8ece7c13110fd1e8941 (SPOT-16).
That parent is historical once published, not the next HEAD. Fetch current main,
preserve intervening/uncommitted work, and never use the isolated workflow trigger
or a local source reconstruction as gameplay ancestry.

Read AGENTS.md -> docs/DEVELOPMENT_PLAN.md -> this handoff ->
docs/briefs/SPOT_UPDATES.md -> docs/validation/SPOT_17_MOVEMENT_GATE.md ->
docs/TEST_LOGGING.md. Live GDD: 1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY;
00 -> 01 -> relevant normalized rules. SPOT-17 06/07 movement/tuning supplements
were written and read back before code; do not duplicate them.

SPOT-17 source contract: human Soldier configured AI base speed (140), no ordinary
sprint or grounded jump, preserved crouch/steps/stairs and class/DEX/status/Haste/
directional modifiers. Explicit airborne Wall Jump/Cloud Step/Float On remain
available outside rifle commitment. Warning, every committed round and actual
rate-adjusted recovery root voluntary locomotion through the existing burst's
exact binding and readyAt. Preserve gravity, falls, base-world and marked forced
motion. No new timer, actor-state owner, freeze, teleport or native speed mutation.
Airborne voluntary actions/dash cannot escape a commitment. Shared Dodge uses the
actual Soldier targets and rejects both rooted FinishMove samples and cached
pre-commitment motion. Client root requires current life-context, exact native
weapon and a nonexpired server deadline. Read-only snapshot actors are not live
movement bodies. Hero/AI movement and all SPOT-16 rifle rules remain unchanged.

Current body/role/weapon/run/graph, control denial and existing >0.20-second service
lateness retire root and unfinished shots. F3 exits, death, disconnect, replacement
and dungeon teardown cannot leak to the saved Hero or a later Soldier. SPOT-15
queues, actual revival and dormant Hero state remain authoritative. Holding or
releasing primary neither starts another burst nor evades a current commitment.

Finite contract: all 93 SPOT-16 selections plus actual-production server/client
movement tests, 95 total and 756 Lua syntax checks, timeout120/workers2. Final
frozen-source local and independent results come from the receipt. First aggregate
attempt was 93/95: read-only snapshot test actors lacked native Alive(), affecting
snapshot delivery and its inherited draft check. That boundary is now explicit;
earlier failure is preserved, not converted into a pass. See validation for the
other fixture-setup attempts and full evidence limitations.

NEXT ACTION: exact-build local gm_flatgrass acceptance of the completed spot queue,
with a short Soldier movement/rifle/F3-to-Hero observation. The code/CI gates do not
establish native collision, latency, animation, audio, co-op balance or acceptance.
Preserve open full Gate-B perkDisplayName and prior native debts. No full campaign
matrix pass is claimed. No dedicated Razor retest or natural sighting prerequisite.

Preserve SPOT01–17, Float On six seconds at 1 Magic/s, reversible Time Management
minutes/expiry precedence, unread/drag epochs, four-choice drafts/card colors,
B28/B29, accepted Crate and P1–P4. Default evidence: console_latest.txt plus
rpg_summary_latest.txt and a short exact-build observation; detailed session only
for timing. Local acceptance -> Workshop 3791535712 parity -> matching VPS.
No Workshop or VPS action occurred or is authorized. Do not start deferred Low-End
PC Optimization, Big Loot, Event System or audit work without further direction.
Supply a fresh handoff and ask the author to start a new conversation when long.
