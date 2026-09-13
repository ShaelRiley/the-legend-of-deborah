# Pre-playtest feedback language

Presentation observes existing outcomes. It never rolls dice, modifies resources,
selects progression, or authorizes transitions. This pass is governed by Shael's
explicit presentation mandate; no gameplay rules or GDD tuning were changed.

| Event | Presentation rule |
| --- | --- |
| Ordinary damage / dice | Existing semantic damage sentence, local hit sound and explosion motif. No extra sound per feed row. |
| Status applied / ended | `[STATUS +]` / `[STATUS -]`, target + named condition + outcome, distinct stock switch/confirmation cues; existing HUD status labels remain authoritative. |
| Save / immunity | `[RESIST]`, distinguish RESISTED from IMMUNE; include save/DC where returned. Short metallic cue. |
| Element weakness / resistance | Named element, target, multiplier and before/after resolution. Distinct weakness chirp versus metallic resistance cue. |
| Feat / capstone procs | Existing Wizard Feedback and Arcane Surge retained. Recovery procs name the feat and actual restoration. Evasion names its capstone; Not Yet gets a life-priority notice. Status-producing feats use the shared status outcome. |
| Magic | Form + Content, committed spend and remaining Magic; failures explain reason and no net spend. Preserve positional cast effects/sound. Full-resource crossing is quiet. New Forms/Contents get a progression notice. |
| XP / SoldierXP / loot | Quiet actual gains; Soldier level gains get a stronger progression cue. Hero level-up remains the existing major celebration. |
| Life / Soldier state | Explicit life count, elimination/revival or incarnation transition; compact outlined notice and distinct danger/life/Soldier cue. |
| Keys / gates / rescue / run failure | Copy the exact existing announcement into the dialogger. Preserve existing banners, physical gate sounds, pickups and rescue celebration. Denials also enter the feed. Successful dungeon build gets a ready notice. |

Shared policy: `sh_feedback_language.lua`. Server delivery extends
`LOD.RPGPresentation` and `CombatRolls:_Send`; outcome adapters live in
`sv_feedback_observers.lua`. Direct Magic/loot/denial seams supply details only
available inside their committed transactions. Observer errors are contained and
all wrapped authority returns, including nil holes, are preserved.

Frequent updates remain in the lower-right feed. Repeated status/element/denial
notices have a per-recipient 1.5-second limit; their suppressed outcomes still enter
developer evidence. New semantic sounds have a shared 0.35-second minimum interval
(0.8 seconds after major cues); higher-priority cues can interrupt. Existing weapon
and world sounds keep their own policies. Major notices use a bounded eight-entry
priority queue and 2.8-second display. Danger/life preempts progression. A Wizard
Feedback burst cannot erase an active level-up celebration.

The feed holds for nine seconds and fades for 1.4. Its visible ten-entry limit and
screen-space clipping do not discard history. **P → Dialogger** opens the newest
1,000 messages with timestamps and a Refresh button. History persists on the client
in `data/legend_of_deborah/dialogger_history.json`, written in two-second batches
and on shutdown. A crash can lose the final batch. This requested persistence was
absent at the starting SHA; it now belongs to the existing CombatRollFeed object.

## Evidence and interpretation

Use the existing developer logger/exporter. No additional courier file is needed.

- `FEEDBACK_DISPATCH`: serial, recipient, family, exact transmitted text, plus
  source outcome fields where available (e.g. status save/DC, element multiplier,
  Magic cast serial/cost, XP delta, lifecycle snapshot).
- `FEEDBACK_CLIENT_ACK`: same serial/recipient; `received` means inserted into
  history, `drawn` means the client completed its first feed or notice draw.
  `sound_requested` means playback was called, not that a person heard it.
- `FEEDBACK_SUPPRESSED`: outcome retained in telemetry but repeated notice restrained.
- `RPG_MAJOR_FX_DISPATCH` matches the existing `RPG_MAJOR_FX_CLIENT_ACK` by serial;
  `triggered=false` records a Feedback overlay suppressed by level-up priority.
- `[FEEDBACK_DELIVERY]` in the existing summary totals delivery stages and restraint.

Only developer mode requests feedback ACKs. They are recipient-bound, deduplicated,
expire after 15 seconds, and are bounded to 512 outstanding entries per client.
No gameplay decisions depend on them. A missing draw may mean feed congestion;
it does not establish failed delivery. A draw can be covered by another UI panel.
Legacy damage/roll telemetry joins by recipient, event order and text/formula;
it does not gain a universal transaction ID from this presentation pass.

## Validation and playtest

`python3 tools/test_checkpoint_g_integration.py` includes the existing 25 suites
plus `test_feedback_language.lua`. The focused harness executes real typed
server/client feed packets, ACK ownership/deduplication, history reload/limits,
first-draw boundaries, observer failure isolation/return preservation, lifecycle
notices, Magic commit/refund behavior, summary counters and priority protection.

Headless checks cannot establish Source asset audibility, HUD occlusion, or overall
mix quality. Freshly install/restart both realms because feed/major-ACK wire formats
changed. During the planned 15–20 minute `gm_flatgrass` session, watch status versus
resistance cues, readable Magic failures, life/Soldier notices, level-up protection,
and P → Dialogger after busy combat. Finish with the standard exporter and return
`console_latest.txt`, `rpg_summary_latest.txt`, and `rpg_session_latest.txt` for this
correlation pass.

Remaining scope: passive feat modifiers and every weapon-specific animation are
not given unique new stingers. Existing sounds/FX remain for these families; this
pass adds systemic outcomes rather than an exhaustive cosmetic audio director.
