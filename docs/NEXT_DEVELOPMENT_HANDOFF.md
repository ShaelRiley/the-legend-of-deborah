# Handoff — Bestiary B26 population repair → local acceptance

Repository `ShaelRiley/the-legend-of-deborah`, branch `main`.
Audited baseline `3f86f99630178df667a8ac3c3410a618931a5962`; fetch current main and
preserve intervening/uncommitted work. The publication response supplies the
exact repair revision. Live GDD05/07 B26 amendment was read back.

Implemented: correct sector4 pacing target to Black.beforeCell (Core is inside
Gordon's reservation); stable tactical-home priority; release threat8/16/18/20
and discretionary maxima2/4/4/4; original-plan versus current/live population
diagnostic. Preserve spacing4, target80/ceiling96, native admission, singleton/
companion rules, roaming motifs/caps/cadence, combat, tiers and rewards.

Paired16 solo Dungeon1 production graphs: sector4 ready0→16; optional encounters
mean3.6875→11.8125; distinct non-core types mean2.25→8.125, minimum1→5. These are
headless plans, not native sightings or concurrent counts. B26 covers20 actual
four-gate plans plus replay and real-code roaming admission. Full validation
outcome, raw measurements and native limits: `validation/BESTIARY_B26.md` and
`validation/BESTIARY_B26_INTEGRATION.log`. Manual source/chunks were regenerated.

Next: install the exact repair locally. On a disposable test run, set
`lod_developer_mode 0`, then `lod_regenerate` (replaces dungeon; marks unranked).
After BuildReady, run `lod_population_status` and `lod_encounter_distribution`;
confirm revision b26/developerDense=false/sector4 ready, then normal play through
all gates and Neil/Brute. Inspect actual variety, spatial density, physical
substitution/deferral, progression, co-op and frame time. Capture console/RPG
logs. No B26 native acceptance, Workshop update or VPS deployment has occurred.

The local→Workshop→VPS release sequence and deferred September28–October4
optimization→Big Loot→Events→comprehensive audit remain. Keep player data,
configuration, rollback and accepted Crate/P1–P4 improvements. Earlier tooling
and native receipts below are historical and do not certify this changed build.

## Previous checkpoint record (preserved)

# Handoff — Steam Deck publishing-tool repair; Workshop → VPS

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
Baseline fetched clean: `c615e0c5c3a00ab7377dae6c2af2542710fcfa29`.
Publication response supplies the exact new revision; fetch current main and
preserve intervening/uncommitted work.

Current tooling checkpoint: Shael pulled c615e0c5 successfully, but native-only
Workshop tool discovery failed before packaging. Shared native/Proton discovery
and launch now support the established Deck win64 executables/Proton Experimental
workflow. Isolated shell regression and syntax checks pass. No game/addon metadata
bytes changed; prior local acceptance and 221-suite evidence remain inherited.
Details: `docs/validation/WORKSHOP_STEAM_DECK.md`. Next: retry the normal publisher
on Shael's logged-in Steam machine, record output/GMA digest and verify downloaded
package parity before VPS deployment. No upload has been observed yet.

Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
00 → 01 → relevant 05/06/07 rules were read for the release sweep; corrected
sweep → LOCAL acceptance → Workshop → VPS sequencing was read back in
00/01/05/07/90. This diagnostic repair changes no game-design rule.

Shael accepted the observed solo experience: good appearance, Gordon defeated,
no crashes or noticeable bugs. Uploaded console/summary verify clean client/server
revision 0ce9a499, Neil's card, Warden defeat, two player deaths followed by continued
play, rescue, +100 $DEB, Level-2 build and recurring Hermit staging. Native geometry
and vertical audits passed. Server Lua-error counts remained zero.

The console exposed a nonfatal automatic Crate-summary nil-material exception once
per dungeon. The reporting-only guard now reports missing/error material truthfully.
Its expanded production-callback regression first failed, then passed. Fresh full
integration: **221 suites passed, zero failures**; log:
`docs/validation/RELEASE_LOCAL_DIAGNOSTIC_INTEGRATION.log`. No gameplay/rendering/assets changed; accepted observed solo
behavior is retained. Native diagnostic readback remains unobserved.

Evidence and exact coverage: `docs/validation/RELEASE_LOCAL_ACCEPTANCE.md`.
Grates (zero in both seeds), detailed offset/mips, reset/rejoin/co-op and Level-20/21
native checks remain unexercised; no blanket acceptance is claimed.

Next: publish the exact clean validated revision to Steam Workshop **3791535712**,
verify package/revision parity, then deploy that matching revision to the VPS with
persistent data/configuration, backups and rollback preserved. Verify service
health, startup logs, listing and connectivity. The local Workshop builder stopped
because gmad is absent; an authenticated owning-account Steam machine is required.
No Workshop publication or VPS deployment/restart occurred. Previous remote SSH/A2S
attempts failed Network is unreachable; server health/installed revision remain unknown.

Deferred September 28–October 4, 2026: Low-End PC Optimization → Big Loot → Event
System → comprehensive systems audit. Preserve P1–P4, Bribe removal, approved
concrete/restored hull, stock blast-door gates and source-front-face-20260924.
Active-scan profiling and dense frame-time/texture-residency certification remain
in the deferred optimization phase. Earlier RELEASE_SAFETY.md local procedure
is retained for unexercised native checks and failure follow-up.
