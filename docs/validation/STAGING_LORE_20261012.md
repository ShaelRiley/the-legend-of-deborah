# Staging story — 12 October 2026

Published-parent source: `f7353f2fd4fdb85794a39845c518446e1473c5e3`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 05 LOD-LORE-001 → 06 LOD-LORE-UI-001 → 07 LOD-LORE-GATE-001.
The author expressly requested GDD changes before game changes and subsequently
approved dialogue changes for every damsel.

The eight fictional personas from *Come and Knock on Our Door* are retained by
name and role. Three paired specialist passes, Quinn's assembly and Ned's final
restraint produced the exact script. The specialist proposals remain in
`docs/lore/room/`; the accepted packet, diagram and exact script are in
`docs/lore/`. Proposals are evidence of the mixer, not competing game law.

## Implemented

The existing staging guide's native Use calls one optional talk method. Current
Dungeon Level selects one of twenty chapters; repeated talks do not advance it.
The server's existing HectorRevealed flag alone selects the exposed-Director
speaker. Deborah's existing legitimate succession retires the old guide.
Existing DamselDialogue transport carries all dialogue: indices31/30 represent
the Hermit/revealed Hector; no artificial damsel or progression target is added.

All twenty women have updated conversations: nineteen sets of three variants,
and two Deborah epilogues explaining the stolen-cash continuation. Ordinary
variant selection and services retain their existing authority and cadences.
All original reward types and parameters are preserved; conversation does not
duplicate pedestal gifts, currency or daily Abundance.

The existing portrait window has a responsive scroll canvas for complete text
and a distinct actual service result. It retires on death, deployment, campaign
epoch/dungeon change or guide retirement/revelation. DamselState adds an optional
32-bit campaign-epoch tail; clients accept old packets with epoch0. The canonical
manual and generated content agree. No recurring server hook, RNG stream,
enemy AI, spawn budget, timer, faction or progression system is changed.

## Evidence

`STAGING_LORE_20261012/checks.json` records eighteen passing selected checks and
SHA256 hashes of their raw output. Sixteen changed/new Lua files parse. Checks
exercise all chapters, independent players, native entity Use, admission and
stale lifecycle rejection, revealed speaker, claimed-gift dialogue, unavailable
Abundance, exact authored text, unchanged service parameters, responsive panel
construction, epoch packet compatibility, twenty-rescue/endless progression,
guide succession, Hector encounter, finale presentation, timeout, staging events
and manual delivery. Installer syntax and whitespace pass. Existing relevant
regressions remain intact.

These are production Lua/Derma authorities under explicit engine boundary
doubles, plus real SQLite for the staging-event integration. They do not establish
Garry's Mod pixel rendering, native +use delivery, multiplayer network timing,
playtester acceptance or Steam Deck FPS.

Preserved intermediate findings: peer review caught a draft conversion that
dropped service tuple fields; it was repaired from the unchanged parent before
the finite gate, and the new test freezes every service parameter and cadence.
The native-Use test initially omitted entity constant inheritance in its double;
that fixture was corrected. The existing portrait test gained the actual native
scroll methods and panel hierarchy without removing its content assertions.
The first staging-event invocation used the plain Lua runner rather than its
required SQLite bridge. Its failed output and initial check receipt remain;
the documented bridge invocation passes. No failed native playtest was rewritten.

## Remaining native acceptance

On an updated gm_flatgrass campaign, approach the Hermit and press E. Confirm
Level1 controls scroll completely, the proper portrait/name and dismissal, then
the next staging visit supplies Level2's different chapter. Confirm rescued
women's voices and unchanged services; long Deborah dialogue must remain readable
after an already-claimed Abundance attempt. Two players should be able to talk
independently. The existing developer staging command can expose later rescues
only in an explicitly unranked test campaign; it is not evidence of full natural
progression. Revelation and succession still require the exact native finale.

The previous stationary Steam Deck comparison and sustained ≥40FPS target remain
open. This source checkpoint is not Workshop publication or VPS deployment.
