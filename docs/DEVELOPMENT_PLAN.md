# Current checkpoint — native VProf has reached its attribution limit

The resumed checkpoint keeps the 45-minute cap from the resume first recorded at 23:57:20 UTC, with a conservative 00:40 UTC cutoff. Steering did not reset the clock. One additional series of two later-phase native VProf captures is complete. [Decision, metrics, raw reports and restoration](validation/STEAM_DECK_VPROF_PHASE_20261026.json).

The largest full-capture frames, 311.530/339.969 ms, occurred near +1 second. The native windows from approximately 15.07–59.54 seconds did not reproduce the historical 149–150 ms direct filesystem-open peak beneath server gamemode protected calls: one reported 3.84 ms and the other no such node. This does not identify the resource or establish when the historical peak occurred. Later matched rendered maxima remain 204.815/140.516 ms, with prolonged below-target episodes of 11.721/10.475 seconds. Protected NextBot averages remain opaque at 11.947/11.280 ms per native reported frame, inclusive; no conversion to rendered cost or additive budget is justified.

No removable operation or source candidate was identified. Stop this aggregate VProf approach at its current limit. BeforeAI wrappers, alignment and children stay closed; no calibration or rejected-family implementation was reopened. Gameplay/tools remain byte-identical to retained 26ccc4d/fdd75bfc/4b682. No experimental SHA or uninstrumented gain. Native integrity/restoration and all 120 installed-hash checks pass; automatic acceptance failures are preserved. Retained CI is 327/336 with the same nine baseline failures; new documentation CI is recorded in PR #7.

PR #7 stays draft, `main` unchanged, SP40 UNMET. Full five-scenario warmed repeated 180-second, ordinary-play, boss-progression and capped acceptance remain UNVERIFIED. Do not automatically start another checkpoint. Require a concrete algorithmic mechanism or an identified new attribution capability before funding more equivalent captures.

# Current checkpoint — BeforeAI observer gate unresolved; retained source unchanged

The October 25 BeforeAI-only checkpoint started at 22:36:58 UTC and has a hard 23:36:58 UTC deadline. Eight fresh 60-second captures (off/on/on/off, then reversed confirmation) are complete; substantive measurement stopped at 23:13:54 UTC. [Decision, all metrics, failed evidence and raw captures](validation/STEAM_DECK_BEFOREAI_20261025.json).

Outcome **C**: stop this measurement approach after one refinement. Small mean throughput penalties do not resolve the 5% bound under variation; confirmation also has a 20.944-second below-target episode. Qualified BeforeAI inclusive wall estimates are 2.538–2.730 ms per corresponding rendered frame, not validated production CPU time or recoverable cost. Endpoint-local clock brackets replace a rejected whole-window constant-offset assumption; nonlinear drift remains unresolved. No child probe, implementation or new experimental source SHA is justified.

All eight runs loaded retained a4ccd068 source, with gameplay/tools byte-identical to fdd75bfc / 4b68237f. Source/HUD/renderer/resources/input/display checks are separate from failed automatic acceptance checks, which include budget, prolonged-drop and unrendered-terminal-interval flags. No uninstrumented source gain. Restore helpers, verify installation, commit/push this diagnostic checkpoint and stop before the deadline. PR #7 stays draft; main unchanged; SP40 **UNMET**, full five-scenario warmed repeated 180-second, ordinary-play and capped acceptance **UNVERIFIED**. Multiplayer/future features/Workshop/VPS deferred.

One future decision only if separately commissioned: use the already-working native VProf path to localize the largest recurring stalls within existing engine scopes, without more per-call Lua wrappers or a new symbols project. These findings do not establish that 40 FPS is impossible or that no economical remedy exists. No automatic new tranche.

# Current checkpoint — bounded low-overhead diagnostic; retained source unchanged

The new diagnostic tranche began October25 at20:54:04UTC with a hard22:24:04UTC deadline. Two instrumentation approaches were selected within18minutes; no implementation candidate was justified. [Decision, conditions, overhead screens, raw captures and restoration](validation/STEAM_DECK_LOW_OVERHEAD_20261025.json).

Native99HzIP/context-switch sampling observed a busy main thread and about44%ofuserCPU samples inlua_shared.dll. Actualframe-window alignment excludes setup/warmup/teardown. The cleanfinaloff/on/off bracket has observedoverhead below5%, butwidecontrolvariationpreventsastrictbound; useonlyqualifiedcoarsefindings. Oneearliersampleoverlappedhostpostprocessing andisexplicitlyexcludedfromcalibration/preserved. NativeengineVProf receivedeightmatched/reversed60sruns: matchingwindowmeanFPSpenalty0.94%, p95+1.57%,p99+0.37%,1%low−4.07%; taildirectionsmixedandallrawretained. Coarseenginehierarchyusablewithlimits, notunbiasedexclusiveLuaCPU.

NextBotprotectedbehavioris10.7–11.1ms/nativeframeinclusive; identifiednativegroundlocomotion~1.25msinclusive. Theseoverlaptheirchildren andmustnotbesummedwithothertimingbudgets. No substantialredundantalgorithmisidentifiedinsidetheLuabehaviorboundary. Thisdoesnotshowthat40FPSisimpossible ornoeconomicalremedyexists. No newsourcegain/experimentalimplementation; retainedgameplay/toolstreesmatchfdd75bfc/4b682, includingretainedHUDwork. All15capturesloadedtheexpectedsource withzeroLuaerrors; helperprovidersrestoredandownedgamesretired. Privatecaptureextensionsarchivedandrestored.

Nextrecommendedactiononlyifanothertrancheisexplicitlycommissioned: onecoarsebracketedmeasurementofEntrySafety:BeforeAIalone, withtheexisting5%/pacingobserver screen. No sourcecandidateuntilasubstantialrecoverablecostandnewmechanismareproved. Do notreopenfailedcontext/lookup/dispatch/movement/preloadfamiliesfromaggregatecosts alone. PR7remainsdraft/mainunchanged/SP40UNMET; fullfivewarmed180s/40capacceptanceUNVERIFIED. Publishthischeckpointandstopwithinoriginal90minutes; noautomaticextension.

# Current checkpoint — remaining-budget attribution recorded; source unchanged

The original October25 deadline remains20:34:30UTC; no new tranche or source hypothesis. After the earlier decision checkpoint, the remaining budget captured four fresh30s C/P/P/C diagnostic runs on07cc818d. Two selected-service selfwall profiles balance all38providers/allcompletedcalls/zeroopenframes/exactroot-selfsum, with zero Lua errors and completeownedrestoration. Movement self44.78/44.49ms/s, entry admission41.36/40.79, close defense27.22/27.63 repeat closely. However the observer reducesFPS22.54→17.89 (20.6%); these are perturbed wall times exclusive only of nestedselectedcalls, notexclusiveCPU/productioncost/predictedsavings. [Raw captures, method, qualifications and ranking](validation/STEAM_DECK_SELECTED_SELF_20261025.json).

No further runtime change is justified by these values alone. Retainedruntime/tools remain byte-exact07cc818d/4b682; earlierHUDgain preserved, movement/preload experiments remainexcluded. FullfiveSP/40capUNVERIFIED/SP40UNMET/bothdisplaysONalways. Finish publication and stop bytheoriginaldeadline. Futureboundedworkmustlowerattributionoverhead andfinda substantial algorithmic/native-movement orentry/close-defensecost beforeanotherimplementationcycle. Do not invent an additiveCPUbudget from these scopes orrevisitfailedmicrofamiliesbasedonlyonstableinstrumentedrankings.

# Current checkpoint — bounded tranche closed; retain measured source

SP40 remains **UNMET**. Both displays stayed ON. The October25 tranche used one new hypothesis and stops after this pushed decision checkpoint; do not automatically launch another tranche. Future gameplay features, multiplayer and Workshop/VPS remain deferred. [Current scorecard and decision](validation/STEAM_DECK_TRANCHE_20261025.json).

Movement-sweep source was rejected after twelve captures with mixed pacing, and preserved on `perf/experimental-movement-sweep-0d247f72`. The new seeded Warden preload experiment also received twelve actual-source unprofiled60s D20 captures in two counterbalanced series. Mean maximum frames improved372.391→223.572ms and352.203→235.450ms, paying~125ms during existing loading. AverageFPS22.947→23.127 and22.878→22.867 establishes no throughput gain. Confirmation longest below40 episodes worsened9.980→12.692s with p95/p99 also worse. Pacing safety is not established, so preserve candidate `d55cbb06` separately on `perf/experimental-warden-precache-d55cbb06`; restore its runtime and tests byte-exact retained `4b68237f`. [All measurements, decisions and published raw frames](validation/STEAM_DECK_WARDEN_PRECACHE_20261025.json).

Retainedruntime remains equivalent to4b07f6b/HUDcd37397. Six fresh current-environment retained controls average22.9125FPS/p9577.0717ms/p99111.923ms/1%low6.6317, longest observed drop13.1213s. SteamOS changed externally to3.9.5/kernel7.2.7; previous3.8.28 measurements remain separate. Original-main cumulative improvement is unquantified because matching the valid fixture would require gameplay backports and runtime reconstruction. No percentages compounded.

Candidate/parent GitHubmatrix have the same nine failing rows out of336; no fullgreen claim. Targeted boss/Warden/manifest checks and all twelve native source/model/HUD/renderer/resources/input/display gates pass. All owned games retired. Complete five-scenario180s acceptance, full boss/ordinary play and40cap remain unverified; PR7 stays draft/main unchanged. No requirement tradeoff is justified by the limited hosting diagnostics.

Highest-value future action, only in a new explicitly bounded tranche: obtain exclusive function-level attribution within the dominant NextBot/server cost and require a plausible multi-millisecond algorithmic saving before source implementation. Current evidence does not establish a credible demonstrated path closing the remaining singleplayer40FPS gap. Do not repeat rejected micro lookup/dispatch/cohort/movement families without new rationale.

# Current checkpoint — seeded Gordon model preparation candidate

The bounded October 25 tranche ends at 20:34:30 UTC. New hypothesis 1 targets the measured encounter-start stall. Two focused profiles reproduced Warden Commit at 244.182/250.515 ms. A counterbalanced feasibility series, with the same observer in every arm, reduced Commit from 260.043/243.904 ms to 132.913/135.983 ms by warming the exact seeded model before capture (123.449/124.382 ms preparation). Nested scopes overlap; these are wall times, not exclusive CPU attribution or proof of throughput gains.

Candidate extends the existing BossEncounter:PrecacheLevel loading seam to the authored Warden and warms only CitizenModel(seed). RunManager already holds players with BuildReady=false. No actors, encounter RNG, AI cadence, resources or gameplay values change. Lua 5.4 boss framework 77/77, Warden and 120-source installation/manifest regressions pass. System Lua 5.5 lacks legacy math.pow and is not the canonical runner. [Finite gate and raw evidence](validation/STEAM_DECK_WARDEN_PRECACHE_20261025.json).

Next: six fresh unprofiled P,C,C,P,P,C 60-second frozen D20 source captures, exact loaded-source/model/loading receipt checks before and after, unchanged HUD/renderer/resources/input/both displays ON. Retain only a repeatable hitch reduction without material regression. This remains experimental pending those captures; retained runtime reference is 4b68237f (runtime identical to 4b07f6b). SteamOS is now 3.9.5/kernel 7.2.7, so older-environment numbers cannot establish this tranche's source effect. SP40 remains UNMET, full five-scenario acceptance and capped verification UNVERIFIED; PR remains draft and main unchanged. No automatic next tranche.

# Current checkpoint — bounded two-hour optimization tranche (October 25)

User limits this tranche to approximatelytwohours from18:34:30UTC/deadline20:34:30UTC, atmostthree new hypotheses; finishpushedcheckpoint/decisionreport, no automaticnexttranche. Futuregameplayfeatures/multiplayer deferred; bothdisplaysONalways/unchangedSP40criteria/mainunaccepted. [Scorecard, costs, baseline limits, stoprules](validation/STEAM_DECK_TRANCHE_20261025.json).

Movement-sweep12sourcecaptures complete: meansFPS+4.693%/+2.698%butoverlapping/mixedpairs, confirmation1%low6.545to5.997(-8.36%)andfirstseriesprolongeddropsworse. Do notretainwithoutpacing safety; runtime/testmatrix restoredexact4b07, candidatepreserved onperf/experimental-movement-sweep-0d247f72. [All12/raw](validation/STEAM_DECK_MOVEMENT_SWEEP_20261024.json). Retainedruntime4b07/HUDcd37397 only; D20sixcontrolsmean22.33FPS/fullfiveSP+cap40UNVERIFIED. Originalmaincomparisonrequiresgameplaybackports dueSentrysupportfailure/differentenvironment; cumulativegainUNQUANTIFIED.

Nextnewhypothesis1: targetobservedWardenService260mscommitspike (serverGMVProfpeak279ms). Useexistingfullprofilestoavoidreaudit, thenfocusedcommit/spawn/progressionallcalltimings/finiteprovidersrestore. Onlysourcechangeifdataidentifiesmaterialreduciblework. NativeNextbotLua10.948ms/frame remainslargeststeadycost; no additivebudgetfromoverlappingprofiles. No morelookup/dispatch/cohort microfamilieswithoutnewrationale.

# Current checkpoint — native-vector swept admission without per-centre tables

MeasuredMovementAllowed~22–24ms/sinclusive inMoveToward~108–113 motivates allocationremoval, no predictedFPSgain. Original createslo/hi/axis tablesforeachcentre/step. Candidate native-vector/plain-centres path retains exactclippingarithmetic/.0001threshold/fullpolicy/currentinputs, removesonlytemporarytables; custom/unknowninputs/centres retainoriginal. L54/LJ12317 fullqueryoracle/denial/boundary/parallel/random/mutation/fallback casespass, existingB29runtime/entryhotpath/120manifest/repeatinstaller/syntax pass. CI337newbehaviorgate/notfullgreen. [Finitegates](validation/STEAM_DECK_MOVEMENT_SWEEP_20261024.json).

Next6freshactualsourceP,C,C,P,P,C60s frozenD20stress; beforeafterexactfile/function/helper/currentnativeVector/fullqueryoracle>=1000/source/HUD/renderer/resources/input/bothON. Restoreonlyownparitydenialcounterincrements synchronously, no gameplay/providers/profilers duringFPS. Rejectnoise/regression, confirmunchangedifpromising. BothmonitorsONalways/SP40UNMET/fivefullSP/fullordinaryplay/40capUNVERIFIED/multiplayerdeferred/mainunchanged.

# Current checkpoint — direct AI-step prototype rejected

FixedC,P,P,C23.323/23.558/21.871/23.328FPS; means23.326/22.714(-2.621%), median34.736/36.137,p9579.524/80.679,p99110.515/104.664,longdrops9.135/10.784s. Reject: removingordinarycoroutine resume/yield via exactsourcebody/directprotectednativecallback doesnot improveoverallperformance. No game sourcecandidate. Same55ordinaryactors/twoWatchersunchanged/57initialhostiles/1820models/seeds/resources/input/AIcadence/settings/bothON; nativecallback/thread/source/HUD/renderer/input/display checks pass, allownedrestored/independentretirement/allownedStop. L54/LJ100-step/order/error/foreignyield fixturespass. [Allrows/raw/contracts/limits](validation/STEAM_DECK_BEHAVIOUR_DIRECT_20261024.json).

Next measured bottleneck remains server AI authority; retain existing cadence/coroutines/content. Do not repeat rejected dispatch/cache/geometry-phase/direct-coroutine approaches. BothmonitorsONalways/SP40UNMET/fivefullSP/fullordinaryplay/40capUNVERIFIED/multiplayerdeferred/mainunchanged.

# Current checkpoint — additional production-plan D20 also fails 40 FPS

Additionalrelease-config/dev0D20/54initialhostiles/67planned/1820models onretainedHUDsource:25.080FPS, median33.767ms,p9568.730,p9992.767,1%low7.712,longestdrop9.542s. Same seeds/legalresources/input/graphics/bothON. Nativeplan/runtime/source/HUD/renderer/input/displaygates pass; 120slease recordsdev0 thenrestores1/allownedStop. Captureendsbeforelease; post120sobservationplayerdead, separatefromactivecapture. Earlierprivatebasename/loadstring mistakes failedbeforeFPS/preserved, fixedwithpublicCompileString andcleanupfixtureL54/LJ. [Raw/allmetrics/limits](validation/STEAM_DECK_RELEASE_D20_20261024.json).

This is additional coverage, not a replacement for frozen developer-density stress or a sourcegain; full ordinaryplay/completebossphases remainunverified. StaticgeometryalreadyusesSOLID_BBOX/noPhysCollide, so no collision representationchange justified. Nativehierarchy stillNextbotLua10.94selfms/frame/serverGM3.05/opaqueLua2.81. Next choose a source change in measured repeated server authority with finite native correctness/FPS gate, avoid rejected caches/dispatch. BothmonitorsONalways/SP40UNMET/fivefullSP/40capUNVERIFIED/multiplayerdeferred/mainunchanged.

# Current checkpoint — progression dispatch micro does not justify source change

Noninstallednative57NextBots57000queriesperarm P,C,C,P,P,C16.423/16.025/15.762/16.129/16.422/16.078ms; only~2.3%time reduction, no meaningful predictedgain claimed. All native profile/Player/null/custompublicproviderparity/restoration checks pass; resolverneverinstalled/allownedStop. No sourcecandidate. [Raw/limits](validation/STEAM_DECK_PROGRESS_DISPATCH_20261024.json).

Next additional ordinary release-configuration D20 capture on current retainedHUDsource: build via canonical BuildCurrentLevel withdeveloper mode0, unchanged release population/planner/configuration/gameplay; same legal20Wizard/resources/physicalcourtinput/graphics/bothON. Separate from frozen developer-density D20stress; never replace/reclassify itsfailedcounts oracceptance. Exactnative releaseplan/runtime/source/HUD/renderer/resources/input/display gates, 60s first finiteobservationalrun; no FPSgain inference acrossdifferentcontent. BothmonitorsONalways; SP40UNMET/fivefullSP/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — bounds polling phases rejected after six source captures

P,C,C,P,P,C22.145/22.645/21.926/21.457/23.035/22.746FPS. Means22.212/22.439(+1.020%), p9583.128/82.669ms, p99118.773/116.457ms, 1%low6.549/6.291, longest10.495/17.727s. Reject: overlapping/mixed FPS and worse prolonged drops despite smaller callback cohorts. Restore runtime and implementation-specific phase test byte-exacteef47658. All native source/deadline/HUD/renderer/resources/input/bothON checks pass; postFPS observers independently restored/allownedStop. [All rows/raw/mechanism/limits](validation/STEAM_DECK_BOUNDS_PHASES_20261024.json).

Next attribute dominant server NextBot Lua cost at current authority; reuse bounded diagnostics and avoid repeated tiny lookup/caching candidates already rejected. No AI cadence/content/collision/graphics changes. Both monitors ON always. SP40UNMET; fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — stagger static bounds polling within existing one-second budget

Hostingdiagnostic L23.648/D32 42.042/D32 45.020/L23.014FPS; dedicatedp9543.578/39.377,longdrops6.665/4.183sFAIL. Differenthosting/runtime/tick/networkconfounds, notSPacceptance. [Rows/limits](validation/STEAM_DECK_HOSTING_HUD_20261024.json). NativeClientSimpeak38.63ms motivates3sThinkobserver:1253staticboxes3759calls/28.448ms, three1372callbackframes8.312–11.387msLua body; all1374providersrestored/ownedStop. Rolefalsefieldmicroonly~6.8%, no candidate. [Diagnostic](validation/STEAM_DECK_CLIENT_THINK_20261024.json).

Focusedsource sets64fixedbinarypollphases perEntIndex, everydeadline0<delta<=1sec; DT/transmit immediate retries unchanged, incompletegettersstayawake. L54simulation1280actors23/60/120FPSpeaks60/40/20vsparent1280, samecadence; existingrenderer/120manifest/syntaxpass. LuaJITweakfixture andgeometryfullupdateerrorssameparent/current, notfullgreen. Next6freshP,C,C,P,P,C60s actualsourcecomparison, beforeafterfile/function/deadline/HUD/renderer/resources/input/bothON; AFTERFPSonly3sclientThinkmechanismprobe/restoreeacharm. No duringFPSobserver. Retainonlyrepeatablepacinggain/avgFPSmaintained, confirmifpromising. [Finitegate](validation/STEAM_DECK_BOUNDS_PHASES_20261024.json). SP40UNMET; fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — native collision groups provide no proven replacement

Actual22group sweep restoredbothactors/allownedStop/bothON. InteractiveDebris3 andScriptedNPC19failfourNPCpairqueries. Traceequal0/5/7/8/9/17notphysicalcontactequivalence; no nativepair/player/loot/Climber/Lurkerbehavior proof or FPSgain. No newsourcecandidate. [Matrix/raw/limits](validation/STEAM_DECK_COLLISION_GROUPS_20261024.json).

Next retainedHUD sameDeck hosting diagnostic withfixedlisten/dedicated/dedicated/listen60s, onehuman andunchangedD20subsetcounts/settings/input/bothON. Olderlocaldedicated32~42avgfailedpacing, predatesretainedHUD. Differentprocess/32bitserverbranch/networkingareexplicitconfounds, notisolatedprocess effect orfrozen singleplayeracceptance. Recordruntime/cadence/source/counts/normalresources andretireallownedprocesses. Usecomparisononlytoassesslargerclient/servercontention; do notreplacefiveSPacceptancescenarios. SP40UNMET/fivefullSP/releaseordinary/40capUNVERIFIED/multiplayerdeferred/mainunchanged.

# Current checkpoint — exact-cell shortcut rejected after six source captures

P,C,C,P,P,C22.344/22.663/21.820/21.839/25.061/23.233FPS. Means23.082/22.572(-2.208%),p9578.576/85.485ms,p99106.719/115.342ms,longest12.239/9.522s. Reject: avgFPS/tails worse despite native29727queryparity/micro~30% mechanismbenefit. Restoreall4runtimefiles byte-exacte464ba7d; keepuseful9900float32/nativeboundary/custom/config/large/tinycellregressions; removeobsolete implementation-specific no-center assertion. CI336includes new behavior gate. All6source/native/HUD/renderer/resources/input/bothONchecks pass/ownedStop/rootinstallrestore, allFAIL40. EarlierprivateisvectorCassertwrong: failedbeforeFPS, archived/excluded; correctedvalidationrestartedsix, no failedcapture replaced. [Allmetrics/raw/limits](validation/STEAM_DECK_EXACT_INTERIOR_20261024.json).

Next investigate whether native collision rules can remove engine-to-Lua callback cost while preserving the complete current ray/hull/physical/player/loot/world matrix. Prior group19 failsfourNPCraytraces; do not reuse it or alter mechanical collisions on unsupported assumptions. Read current native collision gates first; source changes only after equivalence/measured benefit. BothmonitorsONalways. SP40UNMET; fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — exact-cell interior source candidate

Navigationprofiles repeat~690kExactCell/~70s71.775/71.221ms/sinclusive; nestedcoordinatesoverlap, Distance1.262/2.978. Firstprofilecontroller metadatafloor15vsactual8failed afterFPS despite8restoredtrue; originalfailurequalified/preserved, remaining2completedafterfix. [Rows/raw/limits](validation/STEAM_DECK_NAVIGATION_CPU_20261024.json). Short3sinstructionexposure restored/errors0 but sparse/linecapoverflow/VMbias, notCPUtime. [Census](validation/STEAM_DECK_INSTRUCTION_EXPOSURE_20261024.json).

Noninstallednativeinteriorprototype matches29727queries/all690currentcells+57actors; micro57000calls89.678/62.613ms, mechanismonly. Source validates canonicalprovider/config/key/nativeinput identities and proves strictlyinteriorpoints within conservativefloatbound; allboundaries/custom/unknown/large/tiny cases keep exactnativecenter. No physicalmargin/acceptedvolume/cadence/content/settings change. ExistingB29spatial/dispatch/doors plusnew9900float32oracle+interiorwork/provider/keymutation checks/120manifest/syntax pass. [Finitegate](validation/STEAM_DECK_EXACT_INTERIOR_20261024.json).

Next6fresh actualsourceP,C,C,P,P,C60s sameD20stress, source/nativeprovider/pointparity and HUD/renderer/resources/input/bothON atboundaries. Rejectnoise/regression; confirm promising. SP40UNMET; five full SP/release ordinary/40capUNVERIFIED; multiplayer deferred/main unchanged.

# Current checkpoint — authenticated account cache rejected after six source captures

P,C,C,P,P,C22.909/22.751/22.638/22.702/23.327/24.292FPS; means22.979/23.227(+1.078%), p9581.278/77.369ms,p99114.541/110.835ms,longest10.367/10.238s. Only1/3pairedFPSdirectionspositive, overlappingranges/medianworse/mixedpacing; reject source candidate despite isolatednative micro benefit. Restore RunManager byte-exact9ef11be9/remove obsolete cacheunit/CIrow/matrix335. All source/nativeC/cache/nativeidentity/currentPlayerState/HUD/renderer/resources/input/bothmonitor checks pass, ownedStop/rootinstallrestore, all sixFAIL40. [All rows/raw/limits](validation/STEAM_DECK_ACCOUNT_KEY_20261024.json).

Next boundeddiagnostic mustattribute the remaining NextBot Lua cost more precisely; inspect the earlier public instruction sampling failure before reusing it. No disabledAPI recovery/processmemory/validitycache/AI/content/cadence/settings change. Both monitors ON always. SP40UNMET; five full SP/release ordinary/40capUNVERIFIED; multiplayer deferred/main unchanged.

# Current checkpoint — authenticated account key source candidate

Native read-only micro100000calls means42.201ms parent/17.759ms candidate, one actual authenticated SP player, method/providers unchanged and IDs redacted. Only feasibility evidence, no FPS prediction; observed call frequency makes isolated savings modest. Source weakly caches only a confirmed native account key, keeps current validity/provider/state queries, clears provider/removal/disconnect/reload boundaries, preserves uncached unknown/zero/custom/unauthenticated paths. Lua54/LJ identity/provider/lifecycle plus Soldier lifecycle/15progression/120source/repeatinstaller/syntax/diff pass. [Native evidence, API references, finite source gate](validation/STEAM_DECK_ACCOUNT_KEY_20261024.json).

Next6fresh actualsourceP,C,C,P,P,C60s unchangedD20subset, read-only source/function/nativeC/cache/currentidentity/profile parity before/after plus retainedHUD/renderer/resources/input/display. Reject noise/regression; confirm promising. Both displays ON always. SP40UNMET; five full SP/release ordinary/40capUNVERIFIED; multiplayer deferred/main unchanged.

# Current checkpoint — hurt-pose membership rejected after six source captures

P,C,C,P,P,C23.179/24.023/22.795/22.235/22.515/21.744FPS. Means22.643/22.854(+0.932%), p9582.337/81.186ms, p99117.938/113.984ms, longest11.806/9.483s. Overlapping ranges/mixed pairs do not demonstrate gain; reject and restore hurt-pose byte-exactbf05ad1a, retain three useful reload/reentrant/registry regressions. Source/function/membership/HUD/renderer/resources/input/display checks pass; all owned games stopped/root install restored; all six FAIL40. [All rows/raw/limits](validation/STEAM_DECK_HURT_MEMBERSHIP_20261024.json).

Next inspect repeated progression reconciliation cost at the observed caller before choosing another candidate; unchanged lifetime binder already early-returns. No frame validity/state cache, AI/content/cadence/settings change. Both monitors ON always. SP40UNMET; five full SP/release ordinary/40capUNVERIFIED; multiplayer deferred/main unchanged.

# Current checkpoint — caller census complete; frozen-pose membership candidate

Repeated caller samples identify progression/status/player identity and hurt-pose queries. Four controls/profile21.981–23.914FPS/allFAIL40; count samples are not exclusive CPU cost. Providers restored/owned games stopped/both monitors ON. [Raw results and limits](validation/STEAM_DECK_VALIDITY_CALLERS_20261023.json).

Frozen-pose hook currently checks every registered hostile. Candidate tracks only owned pose membership, retains registry order/same-frame callback freezes, checks active state freshly every frame, seeds on reload and forgets removed actors. Existing23 plus3 lifecycle/reentrancy cases, animation/death/manifest/syntax checks pass. No FPS claim. Next fixed6fresh P,C,C,P,P,C60s actual source comparison with boundary source/ownership/HUD/renderer/resource/input/display checks. Reject noise/regression; confirm promising gain. [Finite gate](validation/STEAM_DECK_HURT_MEMBERSHIP_20261024.json). SP40UNMET; five full SP/release ordinary/40capUNVERIFIED; multiplayer deferred/main unchanged.

# Current checkpoint — validity forwarding rejected after twelve source captures

Readonlysource6P24.384/C21.646/C22.954/P21.929/P21.574/C22.333FPS. MeansP22.6289/C22.3107(−1.406%),p9581.342/81.034,p99116.030/114.295,longest13.771/11.209s. Firstsource6means22.632/22.593(−0.170%). BothactualsourceseriesfailtoshowavgFPSgain; reject/restoreMotionV2byte-exact92290/removeobsoleteunit/matrixrowback335. Earlierprototype+8.289%wasnotconfirmed. All12actualsource/nativeCcallee/owner/result/HUD/renderer/resource/input/displaychecks pass/allownedStop/rootinstallrestore; allFAIL40. No causalclaimaboutreloadinstrumentation: readonlygatesdidnotestablishbenefit. [All12/raw/limits](validation/STEAM_DECK_NATIVE_VALIDITY_20261023.json).

Next boundedpublicEntity.IsValidcaller-sourcecensus usingone-in2048observeddebug.getinfoframes, cappedsitecounts/nolocals/entityrefs/pointers. Native17providerprofilefindsmanyvalidityqueriesbutnotwhichgamecallers. IdentifyrepeatedworkatcanonicalcallersbeforeanotherAPIshim. Preserveargs/results/errors/providers; control/profile/profile/controlmeasureobservereffects; exactrestore/independentinspection/ownedprocessStop. No debug.sethook/jitAPIrestoration, validitycache or gameplay/cadence/content/settingschange. BothmonitorsONalways; SP40UNMET/fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — first validity source comparison finds no gain

SixP22.699/C22.879/C22.934/P22.066/P23.130/C21.967FPS; meansP22.6316/C22.5932(−0.170%),p9578.375/78.788,p99122.356/109.621,longest11.532/13.868s. Rangesoverlap/mixedpairs; allFAIL40. Prototypegainnotconfirmed; no sourceimprovementretained. Allnativecorrectness/source/provider/HUD/renderer/resource/input/displaywatch checks pass/allownedStop/rootinstallrestore. [Allsix/raw/limits](validation/STEAM_DECK_NATIVE_VALIDITY_20261023.json).

Candidate-onlypreFPSgatechangesmethodownershipthroughreload/foreignowner/reinstallation. PotentialwarmJIT-stateeffectisunmeasured, notclaimedcause. Nativecorrectnessgatealreadyverified; nextfixed6same-game-codeP,C,C,P,P,Cusesreadonlysource/function/Ccallee/result/identitychecksforbothvariants, noreload/reinstallation beforeFPS. Newcomparisongroupkeptseparate; no count/gameplay/setting/FPScriterionchange. Rejectifnogain, confirmifrepeatable. BothmonitorsONalways; SP40UNMET/fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — native validity forwarding source ready for FPS

Freshprivate4C21.588/P23.729/P23.711/C22.221FPS; meansC21.904/P23.720(+8.289%),p9583.547/75.436ms,p99109.944/105.9415ms,longest13.463/9.853s. Bothcandidatesbeatbothcontrols/allmeanpacingbetter; promisingONLY/all4FAIL40/noformalclaim. Freshnativeparity/owner/retirement/watchchecks pass/allownedStop. EarlierincompletesequenceexcludedaftermissingDPMSline; noactualOFFproven/nooldcapturesalvaged. Newstrictcompleteness+DRMwatchconditionsidenticalallfour; originalinhibitoractive/bothON. [Allrows/raw/limits](validation/STEAM_DECK_NATIVE_VALIDITY_20261023.json).

CanonicalsourceforwardsallvalidityqueriesfreshviaCcallee; noresultcache. Ownedreload/foreignowner/custommetatable/unsupportedruntime guards, no behavior/timing/content/settings changes. Productionunit/B29dispatch/entrylifecontext bothLua54/LJ/manifest/repeatinstaller/syntaxpass. NewCI336notfullgreenclaim. Next6freshactualsourceP,C,C,P,P,C60s against92290, nativehash/function/Cupvalue/owner/allentityparityatboundaries plusHUD/renderer/resources/input/bothON/watch. No observers/JIT/GC/settings changes. Rejectnoise/regression; confirmationifpromising. SP40UNMET/fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — native C call attribution complete

FourcorrectedC/P/P/C21.772/22.013/22.614/21.738FPS; 17nativeCproviders/one-in128, allrestored/independentinspection/ownedprocessStop. BothprofilesrepeatNextBotvalidity~7.7million/~70sandposition~2.1millioncalls; movementsetters~117-120k/smalltimedrows. ExistingLuaLocalPos/LocalAngleslatchwrappersskipped/preserved; failedv1preFPSgateisqualifiedseparately. Inclusivecostsoverlap/clockhelperoverheadandaliaseslimitcoverage; profiledFPSnotacceptance/nocausalspeedupclaim. [Rows/raw/limits](validation/STEAM_DECK_NATIVE_CALLS_20261023.json).

Next isolateconstantnativeEntity.IsValidcallee forwarding inprivatefourfreshcontrol/candidate/candidate/control60s feasibility. ObserverFPSabovecontrolsdoesnotprovecauseorbenefit; everyquerymuststillcallnativecheckerfresh andpreserveproviders/arguments/results/errors. No frame-validitycache. Retainonlyactualrepeatablegainwithnativeparity/newsourceverification. BothmonitorsONalways; SP40UNMET/fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — native method fast path rejected after six source captures

P,C,C,P,P,C23.196/22.043/22.839/22.266/22.276/21.153FPS; candidate meansFPSandpacingworse/inconsistentpairs/overlappingranges. Reject andrestore MotionV2 byte-exactb05b; removeunusedimplementation-specificunit/matrixrow. Native519key/currentmethod+field/reload/foreignowner/API fallbackandrestoration atbothboundaries pass. Micro~2x doesnotpredictgameplaygain; all6FAIL40. AllownedgamesStopped/rootinstallrestore. [Allsix/raw/limits](validation/STEAM_DECK_NATIVE_METHOD_SOURCE_20261023.json).

Next fixedcontrol/profiled/profiled/control60s D20onretainedHUDsource: bounded sparsepublicnativeEntity/locomotion/trace methodobserver, timingactualC work insideopaqueLua scopes. Existing service profileMoveToward108-113ms/s includesitsnativeC callees; measureSetPos/SetAngles/GetPos/trace/locomotion beforeanotherfocusedsourcechange. Nativewrapperreturn/error/ownerrestorationandobservereffectcontrolsrequired; inclusivecostsoverlap. No gameplay/settings/AI/cadence/countchange; allownedprocessStop. BothmonitorsONalways; SP40UNMET/fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — native method lookup candidate; actual source FPS next

Native519methodprecedence keys/57actors/29868currentcasespass; safety38658method+fieldcases/13metadatamutations/5removedNextBotlookups pass. Temporarymetadatarestored/candidatefunctionneverinstalled. Mixed74100lookup loopsPmean10.333ms/C5.011ms motivatesmechanismonly, noFPSclaim. PriorLODfieldindexcachesrejected a differentpath. Base recorder1267samplesmean.0264ms/max.5268ms, terminalsave9.4243ms separately; callbackcostcannotexplainframe deficit. [Diagnostics/raw/limits](validation/STEAM_DECK_METHOD_LOOKUP_DIAGNOSTICS_20261023.json).

Sourcecandidateusescurrentrawmetatablemethods/fallbacks, noactor/table/profile/functionvaluecache; ownreload/foreignowners respected. Onlynative-testedWindowsx64engine2026.09.17 enabled; allotherABIskeepnative. Newproductioninstallerunit+AI/B1/entry/B29dispatch/lifecycle/manifest/syntaxpass; matrix336notfullgreenclaim. [Contracts/frozen6run gate](validation/STEAM_DECK_NATIVE_METHOD_SOURCE_20261023.json).

NextsixfreshoriginalsourceP,C,C,P,P,C60s sameD20stress, exactsource/index/core/liveparity/ownedreload/foreignowner/API-restoration atboundaries plusretainedHUD/renderer/resources/input/bothON. No observers/JIT/GC/settingschanges. Rejectnoise/pacing/correctnessregression; confirmifpromising. BothmonitorsONalways; SP40UNMET/fivefullSP/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — typed Warden dispatch rejected after six source captures

P,C,C,P,P,C24.954/22.051/21.461/22.615/21.849/21.414FPS. Everycandidatebelow everyparent; reject andrestorebothruntimefiles byte-exact14364f8c. Static21phase/dance+foreign/reload andnativefile/function/core/extension/57ordinaryresults checks allpass, butdonotprovea performancegain. Keepusefulpost-coretype-mutation andinitialforeign-providerreloadregressions. AllownedgamesStopped/rootinstallrestored. [Allsixmetrics/proofs/raw](validation/STEAM_DECK_WARDEN_DISPATCH_20261023.json).

RetainedHUD remains partialvalidatedD20gain; noothernewruntimechange retained. Next inspectactualnativeentity-field access shape for scopedcurrentLua-tableborrowing inmeasuredmovementpath; avoidwholeentityindexwrappers/cross-framecaches andmeasurebeforeanyFPSclaim. BothmonitorsONalways; SP40UNMET/fivefullSPgates/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — typed Warden dispatch ready for measured comparison

Four managerobserver runs21.290/20.915/22.413/22.988FPS; controlsmean22.139/profiled21.664, rangesoverlap/allFAIL. Repeated Warden.Tick16.48/26.60ms/s standsaboveotheremptyguards, alongside larger usefulroster/close-defense/movementcosts. All31providers restore/independentinspection andownedprocessStop pass. Inclusive sampledrows overlap/canalias, no additiveCPU/FPSgain claim. [Profile/raw](validation/STEAM_DECK_MANAGER_CPU_20261023.json).

Focused candidate puts Warden-only core/dance behindthepubliccurrenttype guard, withcore-before-dance, late typechanges, reload andforeign-owner fallbacks. Existing21phase/dance checks+foreign/reload andWarden24graphs/clones/fuses/commitment/resupply/boss-feedback gates pass;120-source/repeatinstaller/syntax/diff pass. [Contracts/frozen6run gate](validation/STEAM_DECK_WARDEN_DISPATCH_20261023.json).

Next fixedfresh originalsourceP,C,C,P,P,C60s unchangedD20stress, before/afteractualfile/function/capturedcore/dispatchproof plusretainedHUD/renderer/source/normalresource/input/bothON checks. No observer/JIT/GC/settings changes. Rejectnoise/correctness/pacingregression. Staticchecks are notDeckgain. BothmonitorsONalways; SP40UNMET/fivefullSPgates/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — broad behavior router ruled out; manager attribution next

Actual native census finds55ordinaryactors with onlyvariance→MotionV2, twoWatcherswithsevenlexicallayers. No broad wrapper router is justified. Read-only source/upvalue census makesno callfrequency/CPU/FPS claim; allownedprocesses stopped. [Evidence and limits](validation/STEAM_DECK_BEHAVIOUR_CENSUS_20261023.json).

Next fixedcontrol/profiled/profiled/control60s sameD20stress, extendingexistingone-in128public-method observer toboss/archetype managers andmovement authorities. Inclusive estimatesoverlap/samplingcanalias/providerwrappersaffectJIT; controls measureobservereffect. Exactproviderrestoration plusindependentinspection andwholeprocessretirement required. No gamecodecandidate or predictedgain. RetainedHUDsource unchanged; bothmonitorsONalways. SP40UNMET/fivefullSPgates/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — classification guard rejected; actual behavior ancestry next

Nativeparitypasses57bots/64cases and publictypeerror-restoration; no method everinstalled. Parentflatloopmeans0.233ms/candidate0.276ms per57000calls, order/JIT effects large and pureloop maybeoptimizedaway. No costbenefit; discard without productionchange orFPSclaim. [Rawproof/times/limits](validation/STEAM_DECK_STATEFOR_KIND_20261023.json). ActualsourceHUDgainretained, SP40stillUNMET.

Next readonlyactual_BehaviourTickfunctionancestry/sourcecensus. FreshnativeprofileNextBotLua10.948ms/engineframe motivatesfinding repeated pure archetype-guardwrappers; distinguish mandatory generic/sideeffect work. No functions invoked/replaced oractorfields changed; exactsource/function/upvalue links andeligible guard groups only. Useevidence to decidewhethercanonicaldispatchcanremove redundantguardcalls while preservingcallbackorder/mutabletypeandtable/providerchanges; operationcounts alone are notFPSproof. BothmonitorsON, SPscope/fivefullacceptance/releaseordinary/40capUNVERIFIED, multiplayerdeferred/mainunchanged.

# Current checkpoint — remaining CPU is server/NextBot Lua

Fresh retainedHUD nativeprofile completes903hierarchyrows/1688engineframes/twoENDmarkers. Serverinclusive24.468ms/engineframe, largestNextBotprotectedLua self10.948ms, servergamemodeLua3.047ms, opaqueLua2.814ms, leafclassification1.108ms. HUDtextself0.624ms versus earlier1.24crosscapture (notadditivegain/isolatedcomparison). Instrumented20.937FPS/allFAIL isdiagnosticonly. AllownedgamesStop; currentHUDsourceproofpasses. [Raw/scopes/limits](validation/STEAM_DECK_RETAINED_HUD_CPU_20261023.json).

Next finite read-only nativeStateFor classification mechanism/cost probe, motivated by measured querycosts and actualinstalledtype wrapper. Compareoriginal against existingHostileRegistry membership plus liveNextBotmetatable/MetaName and unchangedpublictypeprovider, without cachingactor/profile/result or overridingmethods. Validateactualbots/player/world/NULL/plainprofiles and directmicrotimings before decidinga sourcecandidate. Microtime cannot proveDeckFPS. BothmonitorsON, SP40UNMET/fivefullSPgates/releaseordinary/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — retain measured HUD reuse; remaining CPU attribution next

Unchanged6confirmationP,C,C,P,P,C21.465/24.986/23.358/21.833/22.456/23.585FPS. Means21.918/23.976(+9.391% arithmetic),p9585.153/74.928ms,p99112.514/100.731ms,longest20.654/16.082s. First6means22.263/23.165(+4.052%). All6pairedFPS/p95directionsfavorcandidate; bothseriesp99/dropmeansimprove, individualtailsmixed. Retain canonicalHUDreuse with limitedD20validation, not universal/noise-free/final40claim. All12FAIL40. Nativevisual/state/lifecycle/provider/source/pool/usage/input/endhealth checks pass, allgamesStop/rootinstallrestored. [All12/raw/CI/limits](validation/STEAM_DECK_HUD_CACHE_20261023.json).

Next fresh60s nativeVProf flat+completehierarchy on retainedsource, noLuaCPUobserver/sampler. Separateclientrender/text, serverNextBotLua/simulation and othernativecosts; collectorwaits2ENDmarkers. Existing reports includeprep/IPC and perframeinclusiveoverlap; newdiagnosticwillretainthoselimits. Use freshmeasuredremainingbottleneck for nextfocusedchange. BothmonitorsON; SP40UNMET/allfivefullSPgates/releaseordinarycorroboration/40capUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — canonical HUD first source series promising; unchanged confirmation next

SixsourceP,C,C,P,P,C runs22.391/22.798/23.776/21.634/22.764/22.921FPS. Means22.263parent/23.165candidate(+4.052% arithmetic), p9582.072/78.369ms,p99117.183/114.056ms,longestdrop22.519/8.951s. All3adjacent FPS/p95 effects favorcandidate; thirdFPSmarginonly0.69% and ranks nearlytouch, so run unchanged6freshconfirmation before retaining. AllsixFAIL40. Nativebefore/afterfile/function/cache/pool/usage/publicprovider checks and input/endhealth pass, allownedgamesStop/rootinstallrestored. CIcd326/335/source_changed0/same9andfiveanchors/newcachegatepass; sourceVRaudiopass. [Sixrawresults/native/CI limits](validation/STEAM_DECK_HUD_CACHE_20261023.json).

Next unchangedP,C,C,P,P,C60s samefrozenD20stress againsta135. No further code/setting/instrumentation changes. Confirmation separates variance from usefulgain; no statistical/finalclaim or mainmerge. BothmonitorsON, SP40UNMET/allfivefullSPgates/releaseordinarycorroborationUNVERIFIED; multiplayerdeferred.

# Current checkpoint — canonical HUD native visual/state pass; source FPS next

Freshcd37397f sourcevisual pass: opaque2builds/1hit,fade1nativefallback; exactnativecursor/RGBAallfourframes, hookremoved. Fixedpixelbounds pass: darkmax6/oneOver5,brightmax5/noneOver5,black/fadeexact,backgroundsunchanged. OwnedgameStopped. [RawPNG/state/path proof](validation/STEAM_DECK_HUD_CACHE_20261023.json). No sourceFPSgain claimed. This documentation checkpoint changes no testedgamecode.

Next fixedfresh original-sourceP,C,C,P,P,C60s sameD20stress againsta135fef3. Actualsource/function/line/lexicalcache/6pool/counters checks atbothboundaries; publicDrawLinesunchanged/no privateprototype; normalrenderer/resources/AI/input/cadence/graphics/bothON. Reject noise/pacing/correctnessregression; allfivefullSPacceptance,releaseordinarycorroboration,warmth3x180s/40cap remainunverified. Multiplayerdeferred/mainunchanged.

# Current checkpoint — canonical HUD raster reuse statically validated

Implement onlyownHUDHook rasterreuse; publicDrawLines remainsnativeauthority. SixfixedRTnames, text/font/layout/palette/cleanup invalidation, width/height bounds, fades/nonHUD/foreignprovider fallback, sameframe/reentrantpool safeguards, protectednative-error cleanup and exacttextendstate. No per-callclosureallocation. Lua5.4/LuaJIT cache24command/state comparisons plus saturation/secondview/weakcleanup/provider/reload tests pass; old750text/1200aligned tests,120manifest/installer/syntax/diff pass. NewCItest makes335matrix entries, not a fullgreenclaim. [Sourceplan/contracts/staticlimits](validation/STEAM_DECK_HUD_CACHE_20261023.json).

Next freshactual-source4background visual/stategate acrossseparateframes; requireactualopaquehit/build and fadefallback so a fallback cannot fakepixelproof. Then original-sourceP,C,C,P,P,C60s sameD20stress, nativeactualfile/function/upvalue/pool/counter/renderer/normalresource/input/cadence/bothON gates. No privateprototype/CPUprofiler/sampler/JIT/GC changes. Prototype+5.365% does not certify changedsource. SP40UNMET/allfivefullSPgates/releasecorroborationUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — opaque HUD prototype promising; canonical implementation next

Four freshcontrol/candidate/candidate/controlD20 captures21.260/22.415/21.979/20.873FPS. Means21.066/22.197(+5.365% arithmetic); bothcandidates abovebothcontrols. Meanp9587.657/83.263ms,p99131.245/130.828ms,longestdrop13.817/11.258s. Onecandidatep99147.733ms; no significance/finalacceptanceclaim. AllfourFAIL. Candidate5719/5660hits,331/313builds,12/13fallbacks; exactfunction/owner/lease restoration and wholeprocessStop pass. [Rawfour/visual/parity/limits](validation/STEAM_DECK_HUD_CACHE_20261023.json).

Next canonical HUD-only rastercache, preserving publicDrawLines/foreignproviders/fades/nonHUD/oversize paths. Bound6textures, validate widths/heights/font/palette/reload/layout/cleanup, preserve RT/alpha/blend/clipping and surface-state contract at ownedHUDscope; nativevisual/regression checks before actualsourceP,C,C,P,P,Ccomparison. Prototypeperformance does not certify changedsource. No AI/graphics/content/count/cadence/hostingchange. BothmonitorsON, SP40UNMET/fivefullSPgatesUNVERIFIED/releaseordinarycorroborationUNVERIFIED; multiplayerdeferred/mainunchanged.

# Current checkpoint — opaque HUD prototype fresh visual pass; matched FPS next

Fresh actual-native original/cached four-background comparisons pass predeclared maxchannel8/pixelsOver5<=20: darkmax6/onepixelOver5,brightmax5/noneOver5,black/fadeexact. Backgrounds unchanged. PublicDrawLinesrestored/leasecleared; ownedprocessstopped. No FPScapture/gain fromvisualtest. [Rawimages/metrics/bounds/frozen4armplan](validation/STEAM_DECK_HUD_CACHE_20261023.json).

Next fixedfreshcontrol/candidate/candidate/control60s unchangeddeveloper-densityD20 with existing6slotopaque-onlyprototype, fadeoriginalpath. Verify actualsource/helperhash/native1024x256slots and exact DrawLines/owner/lease restoration; record hits/builds/fallbacks. NoactiveCPUprofiler/sampler/JIT/GC/AI/graphics/countchanges. A measuredbenefitneedsproperproductionbounds/fontreload/state/lifecycleimplementation and newsourcecomparison before retention. BothmonitorsON; singleplayer40UNMET/fivefullSPgatesUNVERIFIED/ordinaryreleasecorroborationUNVERIFIED; multiplayerdeferred; mainunchanged.

# Current checkpoint — namespace binding rejected after six Deck captures

P,C,C,P,P,C60s captures21.604/22.718/20.814/21.489/21.800/22.127FPS. Parentmean21.631/candidatemean21.886(+1.179% arithmetic), overlapping ranges and inconsistent paired effects. Meanp9582.622/82.380ms,p99118.298/112.571ms; longestdrop18.123/19.816s. Reject; restore all four modules byte-exact2ea66fbf. Keep childRunManager regression. Native4function/source/line/upvalue checks pass eachrun; all owned games stopped. [All six results and limits](validation/STEAM_DECK_NAMESPACE_BINDING_20261023.json).

Benchmark qualification: developer fixture doubles discretionary encounter-planning budgets and changes caps/spacing viaM3DenseTesting. Normal-resource records do not establish release-density equivalence. Preserve current stress workload; do not remove counts or revise gates after poor results. Ordinary release-mode corroboration remains separately required/unverified. Both monitors remainON; singleplayer40UNMET/allfivefullSPgatesUNVERIFIED; multiplayerdeferred; maincec10unchanged.

Next: revisit existing opaque-HUD render-target prototype only through fresh visual/lifecycle/bounded-cache gates, then a fixed matched D20 comparison if those pass. Native text CPU is measured; older single candidate38.513FPS atD10 and mixed screenshot evidence do not establish gain or current visual parity. Reuse existing helper; fades retain original native drawing. No HUD change is retained without valid visual/correctness/FPS evidence.

# Current checkpoint — namespace binding candidate ready for measured comparison

Four source modules bind only the existing LOD namespace as a local upvalue. Every child service/actor/profile/provider/lifecycle/graph/result remains live. Status matrix and new child RunManager replacement regression passLua5.4/LuaJIT; entry lifecycle/hotpath with float32 CLI compatibility, sharedAI/B29/roster, Soldier lifecycle, actor progression, routecache,120manifest/installer/syntax/diff pass. Initial CLI harness issues are preserved separately; no fullmatrixgreenclaim. [Candidate, regression receipts and frozen6run gate](validation/STEAM_DECK_NAMESPACE_BINDING_20261023.json).

Next fixed freshP,C,C,P,P,C60s normalD20 source comparison. Native4file/function/line/upvalue namespace proof beforeFPS, actual installed manifest/renderer/normalresources/input/native1tick/GC200/200/bothON gates. No active profiler/sampler or state cache; reject noise/inconsistent benefit/pacing regression. No FPS improvement is claimed yet. Singleplayer40targetUNMET/allfivefullSPgatesUNVERIFIED; multiplayer deferred, maincec10unchanged.

# Current checkpoint — native table identity attribution unavailable

One metadata-only normalD20 control finishes23.045FPS and FAILS pacing. Public tostring(table) uses obfuscated identifiers, so native-register addresses cannot be directly associated. Stop this diagnostic; no decoding or alternate formatter/heap read is attempted, no table owner attribution is claimed. Earlier private loadstring wrapper failed beforeFPS; corrected to supported CompileString and preserved. All owned games stopped; neither profiled arm completed. [Exact attempt/metrics/limits](validation/STEAM_DECK_TABLE_TARGET_20261023.json).

Next focused source hypothesis: bind the existing LOD namespace once in the measured motion, entry, status and roster modules. This removes repeated global namespace reads, while each child service, actor/profile, provider, graph and result is still resolved live. Source never replaces the namespace object during play; reloading a module binds the current namespace. Native shared string-lookup samples motivate a bounded comparison, not a global-lookup CPU total or predicted gain. Run existing lifecycle/sharedAI/entry/motion regressions, then fixed6fresh original-source P,C,C,P,P,C60s D20. Both monitors ON, singleplayer40targetUNMET/allfivefullSPgatesUNVERIFIED; multiplayer deferred; main unchanged.

# Current checkpoint — table-capacity request rejected

Four fresh controls/candidate/candidate/control normal D20 captures measure22.387/21.145/21.429/20.759FPS. Means21.573control/21.287candidate; ranges overlap. Mean p9580.841/85.556ms, p99118.294/124.474ms and longest drop20.702/25.951s all worsen. Reject; no source performance change retained, no significance/causal slowdown claim. Each native proof preserves60tables/57actors, all raw fields/metatables/functions/references, unchanged JIT flags. Candidate setup~10ms with inclusive net heap~2.9MiB; actual capacity and owned allocation are not queried. All owned games stopped, resetting layout. [Exact four runs, receipts and limits](validation/STEAM_DECK_HASH_CAPACITY_20261023.json).

Next: use existing CPU/native evidence to isolate redundant lifecycle work before another focused source candidate. Keep live progression/provider/life transitions authoritative; no per-tick stale-state shortcut. Both monitors stayON. Singleplayer40FPS target UNMET; all five fullSP gates UNVERIFIED; multiplayer deferred; PR7draft/maincec10 unchanged.

# Current checkpoint — native hash-lookup evidence; table-capacity screen

Existing5890CPU samples include2512Lua-module leaves; only270match exact export starts. Current DLL SHA/inode/timestamps and PE unwind ranges improve attribution without disabled APIs. A330sample anonymous interval has reference-compatible table-get branches/node traversal; this is an inference, not a PDB-confirmed symbol. The exact PDB is absent locally and Microsoft returns404; no complete GC/realm/VM-op attribution is claimed. [Metadata, limits and frozen experiment](validation/STEAM_DECK_HASH_CAPACITY_20261023.json).

Next fixed freshcontrol/candidate/candidate/control60s normalD20: one-shot server table reservation via1024private nonnumeric keys, all removed before play. Verify original raw fields/references/functions/metatables unchanged; numeric-key/oversized tables skip. Controls perform same semantic snapshots/key allocations without insertion. Larger memory/cache/GC traversal may offset lookup benefit; actual bucket count is not queried or claimed. No gameplay state cache, recurring instrumentation, forcedGC/JIT knob or count/graphics/cadence change. Private helper passesLua5.4/LuaJIT semantic/partial-cleanup gates; native parity/FPS unverified. Whole owned process retirement resets layout.

Original NPC dispatch runtime is restored; no source gain retained. Both monitors stayON. Target singleplayer40FPS UNMET; five full SP gates UNVERIFIED; multiplayer deferred; PR7draft/maincec10 unchanged.

# Current checkpoint — NPC provider shortcut rejected after six native runs

FreshP,C,C,P,P,C60s normalD20 runs measure21.172/21.414/22.785/20.651/22.425/21.447FPS. Parentmean21.416/candidatemean21.882(+2.176% arithmetic), overlapping ranges. Adjacent differences+1.142%/+10.337%/−4.362% are inconsistent. Meanp9585.291/85.545ms,p99123.440/123.097ms and longestdrop24.958/21.251s are mixed; allsixFAIL. Reject the shortcut and restore exact9b7runtime; keep foreign-provider mutation/removal/fallback regressions. No significance/CPU-cause or gain claim. [All metrics/native receipts/decision](validation/STEAM_DECK_NPC_DISPATCH_20261023.json).

Native file/function/upvalue/provider/state parity passes57actors/60checks perrun; all57candidate predicates match, foreignprovider probes restore synchronously, no profiling inFPS. All owned games stop and root install restores. Both monitors ON. User's goal remains SINGLEPLAYER40FPS; allfivefullSPgatesUNVERIFIED, multiplayer deferred, PR7draft/maincec10 unchanged.

Next: improve native attribution of the remaining Lua-module CPU cost using existing saved samples and the exact public binary's available debug/export symbols. No disabled Lua/JIT API is restored or bypassed. Check feasibility first; no public-symbol availability or function-level attribution is assumed. Preserve current source/settings and prepare the next focused change only from measured evidence.

# Current checkpoint — measured query costs; guarded NPC dispatch candidate

Four fresh controls/profile/profile/control normalD20 runs finish:21.502/21.820/21.169/21.822FPS. Controlmean21.662/profilemean21.494; ranges overlap, no calibrated overhead/significance claim. Both sparse profiles repeat ProgressionState~46.6/48.6ms/s, lifecycleBind~46.6/50.8ms/s and SoldierStateFor~34.8/40.7ms/s; inclusive nested samples overlap. Derived/reconciliation is much smaller. Both20provider identity inspections pass; all owned games stop. [Exact evidence and limits](validation/STEAM_DECK_QUERY_PROFILE_20261023.json).

Candidate avoids the canonical human-Soldier provider's empty NextBot dispatch while its function identity is unchanged. Every query still uses the existing live base resolver. Foreign providers, return/error semantics and callback changes remain. No profile/table/validity cache. New foreign-provider transition tests plus existing Hero/Soldier/removed/inherited/nil/false cases, native-API available/unavailable, Lua5.4/LuaJIT, lifecycle/status/actor/sharedAI B29/120manifest/syntax/diff pass. This is not native performance evidence.

Next fixed freshP,C,C,P,P,C60s original-source comparison, actual native source/provider/result parity before FPS and normal workload/input/settings/bothON proof. No CPU profiler/sampler/JIT/GC/affinity tuning. Reject noise or pacing/correctness regression; no predicted FPS gain. [Candidate finite gate](validation/STEAM_DECK_NPC_DISPATCH_20261023.json). TargetUNMET; all five full singleplayer scenario gates UNVERIFIED; multiplayer deferred; PR7draft/maincec10 unchanged.

# Current checkpoint — singleplayer focus; targeted query attribution

User clarification2026-10-23: current goal is singleplayer40FPS on the actual Deck with both monitors ON, followed by validated publication to main. Defer multiplayer and remote-host access; neither blocks this current scope. All five frozen singleplayer scenarios, normal gameplay/graphics/counts, three warmed180s uncapped repeats, pacing criteria and separate40cap remain required. The preceding six-scenario/access notes are historical; do not ask again for multiplayer access for this current goal.

The maxmcode screen is rejected; stock source/settings retained, all owned games stopped. Current256CI325/334/source_changed0 matches e327's same nine failure names and all five leaf anchors; source/VR/audio pass. c283's source/VR/audio pass; its full matrix is separate/pending. No full green or native40FPS acceptance claim.

Next: fixed fresh control/targeted-query-profile/profile/control60s normalD20. Reuse the finite sparse public-service wrapper mechanism, restricted to status/progression/derived-state queries and movement anchors; no native API/debug hooks or actor-method overrides. Sample one completed callback per128calls, preserve vararg/nil/error/yield behavior, bound lease120s and independently check owned provider restoration. Capture profiler overhead; inclusive sampled estimates can alias and do not prove gross allocation/GC costs. No source optimization or predicted gain is retained from inspection. Both monitors stay ON; target UNMET.

# Current checkpoint — code-byte capacity rejected; external coverage unavailable

Four fresh stock/request/request/stock60s Deck D20 captures measure23.967/22.486/22.165/22.554FPS. Stock mean23.260 versus candidate22.325; p95means75.841/78.565ms, p99means109.108/117.070ms. Mean longest-drop17.023/10.802s improves but all four stillFAIL. Reject maxmcode16384; both candidate FPS averages are below both controls. No statistical significance/cache saturation/cause is inferred. Public option receipts/unchanged JIT flags at request/native source/normal inputs/one-tick startup/all source/workload gates pass. Zero Lua errors at capture boundaries. All owned games stop, clearing temporary options; original code/settings retained. Both monitors ON. [Exact metrics/receipts/retirement/raw locations](validation/STEAM_DECK_JIT_MCODE_20261023.json).

External coverage request is pending: existing dedicated host40.160.86.240 is reachable ongm_flatgrass, zero players/12slots; this Deck has only known_hosts files and no authentication agent. SSH administrative access and three additional actual human Heroes are unavailable. Required four-human test and remote-source identity remain UNVERIFIED. This is separate from local performance, which also remains below target. Existing isolated64server/tooling and frozen scenario are prepared; do not substitute same-Deck dedicated conditions for frozen listen-host conditions. No public server mutation occurred.

TargetUNMET; all six full180s×3/warmed/40cap/fullboss/multiplayer acceptance gates UNVERIFIED. PR7 remains draft, maincec10 unchanged. Continue the measured local source loop; perform remote/multiplayer preparation and tests when actual access/players arrive. Current source/VR/audioCI pass; complete matrix classification is being collected separately.

# Current checkpoint — complete native hierarchy; code-byte capacity screen

Fresh native engine diagnostic contains both completed reports:1589profiled frames, NextBot protected Lua self11.09ms/frame, server inclusive25.469ms/frame; rendering opaqueLua2.8ms, text1.24ms and leafclassification1.19ms. Inclusive scopes overlap and include capture preparation/IPC. Actual active20.543FPS/p9590.791ms/p99132.141ms FAIL is instrumented, not acceptance. Earlier partial hierarchy/21.744FPS is preserved; the collector now waits for both completion markers. Both owned games stopped. [Complete hierarchy/raw paths/limits](validation/STEAM_DECK_NATIVE_HIERARCHY_20261023.json).

No new production optimization is retained. Adjacent movement-field borrowing requires a better correctness/mechanism gate; changing static render group does not bypass the reference leaf pass. Existing incomplete/unlit batches stay excluded. Next: fixed four fresh stock/maxmcode16384/maxmcode16384/stock60s runs, using only the documented public JIT code-byte capacity option. This is independent of previously rejected trace-count/length requests; saturation and unknown native defaults are not assumed. No JIT on/off/flush, flags, GC, AI, content, graphics or source changes. Both realms require fresh option/flag receipts; all game processes retire before next arm. Reject noise/tail regression; no predicted gain claim.

Both monitors stay ON always. Required dedicated-host/four-human access request is pending while local work continues. TargetUNMET; all six full acceptance gates UNVERIFIED; PR7draft/maincec10 unchanged.

# Current checkpoint — timer attribution complete; native hierarchy next

Four fresh normal D20 runs, unprofiled/profiled/profiled/unprofiled, measure22.263/19.375/18.710/21.378FPS. Control mean21.820FPS versus observed19.042FPS: material instrumentation effect; no profiled FPS acceptance. Both profiles receive22timer groups, inclusive sum24.453/23.780ms per second. Weapon-special timer9–10ms/s leads; these rows cannot explain the frame deficit. No timer optimization retained. [Measurements, coverage and retirement](validation/STEAM_DECK_TIMER_PROFILE_20261023.json).

Provider restoration passes; queued wrappers require owned process stop. All four owned games stopped, task autorun and flag removed. Both monitors remain ON. Next: fresh normal D20 native VProf hierarchy without Lua CPU observation, separating simulation/Lua/render costs before another focused change. TargetUNMET; all six full acceptance scenarios UNVERIFIED; PR7draft/maincec10 unchanged.

# Current checkpoint — visibility bookkeeping rejected after twelve runs

Firstseriesmeans19.586parent/20.279candidateFPS(+3.54%); confirmation22.305parent/22.109candidate(−0.88%). Rangesoverlap;averagegaindoesnotrepeat. Confirmationp99improves121.590→104.290ms,butlongestslowepisodeaveragesworseinbothseriesandall12FAIL. Rejectthecandidate; restore rendererbyte-exacte07177e2/SHA2567bec9bbd. Keepusefulregistration/GC/removalregressions,passingLua5.4andLuaJIT. [All12measurements/limits](validation/STEAM_DECK_NATIVE_SELECTION_20261023.json).

Allnativefunction/file/source52client116server/1820models/normalroutechecks pass. Confirmationfreshnativeone-ticklogsarepreserved; exposedfrequency`.1`wasnotchanged. Rebootanddifferentbackgroundloadseparatesessions—nopooledcausalFPSclaim. Allownedgamesstopped. BothmonitorsON/persistentdisplayinhibitionactive. e327CI325/334/source_changed0/sameninefailuresandfiveanchors; source/VR/audiopass.

Next: boundedtimer-callbackCPUattributionusingexistingAuditprofiler. Earlierprofileexcludestimers. Comparefreshunprofiled/profiled/profiled/unprofiled60srunsontheunchangednormalD20route; measureobserveroverheadandcollecttimerrowswithoutclaimingprofiledFPSasacceptance. Preparedproviderproxykeepsregistrationarguments,return/nil/error/yieldsemantics; queuedwrappersrequirewholeownedprocessretirement. No timer instrumentationisinstalledduringcurrentcomparison. TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10unchanged.

# Current checkpoint — unchanged confirmation resumes after reboot warm-up

Firstsixnative-selectionrunscomplete: parentmean19.586FPS/candidatemean20.279(+3.540% arithmetic), overlappingranges. Meanp9592.286/91.554ms,p99138.672/136.701ms; longestbelow40episode35.850/42.391s. AllsixFAIL. No validatedgainretained. Exactnativefile/functions/source/resources/input/focus/bothONpass. RepeatunchangedP,C,C,P,P,Cusingpinnedsourcee07177e2/e3271bb8. Userpause/rebootinterruptedconfirmationbeforeFPS; rawstartupretained. Ten-minuteordinaryD20devicewarm-upthenfreshprocesses; no content/AI/graphics/hostingchanges.

Cadenceclarification: exposedlisten-hostfrequencyis`.1`,whilefreshnativeengine reportsone-tickscheduling. ThreeordinaryD20BehaveUpdatecallbackseach447times/10.0068s,mostly1/2simulationticksapart. Theinitialliteral`.015`warm-upassertionwaswrongandstoppedbeforeFPS; noCVarwaschanged. Distinguish66Hzsimulation/requestedschedule/observedcallbackrate. Historicalpaireddataremainatmatchedsettings; donotfabricatehistoricalper-actorcadence. [Actualprobe,correctionandlimits](validation/STEAM_DECK_AI_CADENCE_20261023.json). Temporarybindingsrestore; allprofilingmustretirebeforeFPS. Bothdisplayinhibitionnowrestoredasagraphical-sessionuserunit.

TargetUNMET; allsixfullacceptancegatesUNVERIFIED; PR7draft/maincec10unchanged. Next: finishwarm-upandunchangedconfirmation,comparecombinedevidence,thenretainorrevertthecandidateandcontinueoptimization.

# Current checkpoint — native visibility selection bookkeeping candidate

The sampled allocation profile completes inbothrealms; currentmethodinspections1511server/4137clientfindnoprofilingwrappersandoptionalheapsamplingiscleared. Instrumented17.241FPSisnotnormalperformance. Every64samplescanaliasrenderpasses; do notextrapolateallocationtotals. Geometrydrawhaslargesampledheapgrowth. [Nativeattributionandlimits](validation/STEAM_DECK_ALLOCATION_PROFILE_20261023.json).

Candidate replacesperviewgrownentityselectiontableswithaweakentity->exactpasstokenmap. Bothkeysandvaluesareweak,soonlytheactiveviewownsthetoken. ExactstrongvaluecandidatefailsremovedentityownershipunderLuaJITCLI; correctedcasepassesLuaJITandLua5.4. Initial713parentstartupstoppedbeforeFPS;nocandidatetested/logspreserved. Valuescontainviewscalarsonly; new/nestedviewsstillneedtheirownselection. Draws/bounds/camera/NoDraw/fallbacksremain. Nativevisibility,300drawparity,weakcleanup,samepassregistrationreplacement,manifest/syntax/diffpass. NextfixedP,C,C,P,P,C60snormalD20comparisonwithactualfile/functions/source/workload/GC200/200/bothONproof; noactiveprofiling/sampler. [Frozencomparison](validation/STEAM_DECK_NATIVE_SELECTION_20261023.json). NoFPSgainclaimed. TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10unchanged.

# Current checkpoint — GC step change rejected; sampled allocation attribution next

Four fresh stock/candidate/candidate/stock60s Deck D20 captures measure20.906/20.886/20.728/19.934FPS. Means20.420stock/20.807candidate overlap; p95means89.834/90.230ms and p99means132.657/142.798ms do not improve. AllfourFAIL. Reject publicstepmul100; actualpause200/stepmul200restoredinbothrealmsandallownedgamesstop. NativeAPI/source116server52client/normalresources/input/focus/bothONgatespass. No statistical/causal slowdown claim. [Fullrawmeasurements/restoration](validation/STEAM_DECK_GC_STEP_20261023.json).

The existing opt-in CPU profiler now supports sampled inclusive net heap changes, using two count queries every configured16–4096calls. Default profiling and ordinary gameplay leave this disabled. Positive/negative samples can includeGC and nested scopes; they are not gross allocations or GC CPU time. No result tables are added percall. Cadence, signed deltas, nil/vararg returns, sampled errors, callbackrestoration and invalidoptions pass; capture/profile/5analysis/120manifest/syntax/diff pass. Exactoldsourcefailsnewgate. Nativeattribution remainsUNVERIFIED; next normalD20profile samples every64calls, with normalGC200/200 and bothmonitorsON. Observercost is diagnostic; final ordinary acceptance must disable profiling.

TargetUNMET; allsixfullscenariosUNVERIFIED; PR7draft/maincec10unchanged.

# Current checkpoint — bounded heap evidence; GC step comparison next

Read-only heap/interval traces finish on normal frozen listen-hostD20 with20.201FPS/p9586.942ms/p99122.945ms: instrumenteddiagnosticFAIL. Bothsamplersretire; selftimed bodies average4.04us/client and2.33us/server, excluding hookdispatch/GCfromstorage. Client30of91intervals>80msarewithinonesampleofheapdrops; mostarenot. This is association, not causalGCcost/functionproof. Flattracestorageandprep/postamblesremainexplicitlimitations. [Rawtrace/parameterreceipts](validation/STEAM_DECK_MEMORY_TRACE_20261023.json).

A separatepublicAPIroundtripreadsandimmediatelyrestores pause200/stepmul200inbothrealms,withcollectionrunningbefore/after; noFPS. Next: fixedfreshstock/candidate/candidate/stock60sruns,onlypublicstepmul100versus200aftercanonicalsetup. Pause200remains; no collectorstop/restart/fullcollect/forcedstep,activeprofiler/memorytrace/sampler/JIT/affinity. Requireactualbefore/afterAPI/running/source/resources/input/geometry/bothONandrestorationreceipts. Throughput/memory/finalizerlifetime risks require measuredregressionreview. No gainisclaimed.

BothmonitorsstayONalways. TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10unchanged.

# Current checkpoint — dedicated64 runtime still fails frame pacing

A separate same-Deck Linux64 dedicated Dungeon20 diagnostic averages40.407FPS, median22.196ms, p9542.534ms, p9956.218ms and max313.020ms. Time below40 is30.694s; longest drop4.339s/five episodes>=2s. FAIL. BothmonitorsstayON1280×800@60/external1920×1080@75. This changes server architecture/JIT/engine branch and privatecheatflag configuration; it does not isolate bitness or replace the frozen listen-host benchmark. Earlier Linux32dedicated42.003FPS also failed tails. [Actual captures and limits](validation/STEAM_DECK_DEDICATED64_20261023.json).

Source52client/116server, normalWizard20/seeds/resources,1820models,57roamers+9bossactors,physicalroute,node207,normalAI66Hz/.015/hosttimescale1/no god/noclip and oneactualhuman/fourslots pass. Engine2026.10.22/x86-64/LuaJIT2.1beta3 requires standardsv_cheats1 for the intendedAIcadence; no gameplay cheats used. AllfourSentryslotsadmitted; the unfiltered postcombat20pointprobe hits17floors/3livehostilebodies, so clean20/20postcombatsupport is unverified. Bothownedprocessesstop. Three setup failures have noFPS and remain preserved. Current670CI325/334/source_changed0 matches previousninefailure names; source/VR/audio pass.

Boundary counters showclient141.46%/server112.19%ofonecore and DRMgraphics17.49% busy. No activeprofiler/sampler/JIT/affinity orsourcechange was used. Next: investigate CPU pacing/allocation behavior before another focused runtime/source comparison. Allsixfullscenarios/threewarmed180sruns/capped40/fullboss/fouractualhumansremainUNVERIFIED. TargetUNMET; PR7draft/maincec10unchanged.

# Current checkpoint — client profile captured; dedicated runtime comparison preparation

Existing bounded client/server CPU profiling completes on normalD20. Instrumented18.395FPS/p9596.628ms/p99126.531ms fails and is not normal performance. Client render phase averages13.95ms/frame; generated-geometry hook2.60ms/frame, hostile Draw1.64ms/frame and combat-feedHUD1.11ms/frame are larger measured rows. Scopes overlap and exclude unwrapped engine/timer work. Server BeforeAI57.27ms/s and CloseDefense38.54ms/s remain substantial. Actual non-VR runtime reports idle with zero active hooks/timers/native resources. [Raw rows/limits](validation/STEAM_DECK_CLIENT_PROFILE_20261023.json).

The post-check flags two permanent server lifecycle callbacks as leftovers; source confirms these are expected static hooks. Server profile/capture state is absent and1511current entity-method checks find no profiling wrappers. Original failed JSON is preserved; the checker is corrected. It halted before client post-inspection, so that receipt remains unverified. The owned process stopped, clearing all observers; no independent client-binding retirement claim is made.

Earlier same-Deck dedicated42.003FPS/p9543.540ms used a32-bit Linux/LuaJIT2.0.4 server. Prepare an isolated64-bit server to compare architecture with normal66HzAI/content/graphics/source. This is a separate hosting diagnostic, never a replacement for the frozen listen-host failure. The first anonymous installer reports Missing configuration; metadata refresh plus explicitLinux retry downloads the64-bit branch. No client/oldserver files are changed.

Both monitors stay ON. Target UNMET; all six full scenarios UNVERIFIED. PR7draft/maincec10 unchanged.

# Current checkpoint — diagnostic overlay does not explain the deficit

Four fresh D20 captures finish at22.007on/21.249off/20.434off/20.961onFPS. Means21.484on versus20.841off (−2.991% arithmetic) provide no supported benefit from disabling Source net_graph. All four fail and ranges overlap; no statistical slowdown cause is claimed. Native preflight/start/end values match1/0/0/1; every other recorded setting is identical. cl_showfps0/cl_showpos0/developer0 remain. Source/resources/input/focus/both-display gates pass. All owned games stop and originalnet_graph1 is restored. [Raw metrics and restoration](validation/STEAM_DECK_OVERLAY_COST_20261023.json).

Keep the useful four start/end diagnostic fields; no per-frame work or normal preference change is retained. Next: same frozen D20 with the existing opt-in bounded client/server CPU profiler. Its FPS is instrumented diagnostic only; inspect hook/entity cost and restoration rather than treating it as acceptance. Preserve normal native visuals, counts, AI and both monitors ON1280×800@60/external1920×1080@75.

Target UNMET; all six full scenarios UNVERIFIED. PR7draft/maincec10 unchanged.

# Current checkpoint — record diagnostic overlays before measuring their cost

Existing capture configuration now records net_graph,cl_showfps,cl_showpos and developer at start/end only. No per-frame work, setting or gameplay changes. Current saved client config has net_graph1, but actual native values still require verification. Capture/profile/analysis,120-source manifest, syntax and diff checks pass. [Plan and scope](validation/STEAM_DECK_OVERLAY_COST_20261023.json).

Next: fresh net_graph1/0/0/1 D20 diagnostics with actual start/end values, all other settings/resources/counts/AI/actions fixed and both monitors ON. Preserve the gameplay HUD and native visuals. This tests instrumentation overhead; no FPS gain or full acceptance follows source inspection/tests. Restore prior overlay preference afterward.

Public host-threading controls remain unavailable. Entry reuse and all other unvalidated candidates remain reverted. Target UNMET; all six full scenarios UNVERIFIED; PR7draft/maincec10 unchanged.

# Current checkpoint — public host-thread mode unavailable

Actual Windows64/P10 native read-only probes find neither host_thread_mode nor host_threaded_sound through GetConVar in either realm. mcore1, queue2 and threaded bones1 are already active. No setting, flag, API or game state was changed; no FPS is measured by this capability check. Both monitors remain ON. [Exact public capability receipts](validation/STEAM_DECK_HOST_THREADS_20261023.json).

Next: client/render cost investigation with normal native walls and presentation intact; check actual diagnostic overlays before measuring their overhead. Existing wall hiding/batch visual-loss experiments remain ineligible. Entry reuse remains reverted. Target UNMET; all six full scenarios UNVERIFIED; PR7draft/maincec10 unchanged.

# Current checkpoint — entry-context reuse rejected after pacing review

Twelve timed Deck captures complete. Candidate average21.970FPS versus21.043control (+4.402% arithmetic) repeats a positive average direction. Pacing remains unsuitable: combined longest below40 episode averages31.952s versus23.181s; confirmation p99 averages120.270ms versus113.456ms. All12fail. Reject the change for this pacing task and restore EntrySafety byte-exactly to f6772638. This is not a causal regression or statistical-significance claim. Keep21behavior/lifecycle cases/71assertions. [Complete evidence/limitations](validation/STEAM_DECK_ENTRY_CONTEXT_20261023.json).

The confirmation helper accidentally renamed its opt-in environment flag, so its extra actual-function/clock receipts are missing. The first six have complete receipts. Every confirmation still has116server/52client verified source hashes, including the correct installed/mounted entryfile, plus normal seeds/resources/input/focus/bothON. Do not fabricate retrospective function proof. The helper is corrected. A fourth-arm startup failure has noFPS and is archived; that unchanged arm succeeds on retry. All owned games stop.

Next: read actual public host-threading ConVars/defaults/flags without changing settings. Native evidence places substantial server and render work on the main thread; current benchmark enables mcore1/queue2/bone1 but has not recorded host_thread_mode. Availability, effect and correctness are unverified. No threading setting is applied yet.

Both monitors remain ON1280×800@60/external1920×1080@75. Target UNMET; all six full scenarios UNVERIFIED. PR7 remains draft; main stayscec10dc54. No entry reuse, JIT, affinity, key, query or animation candidate remains.

# Current checkpoint — entry source comparison mixed; unchanged confirmation next

Six fresh source runs complete: controls20.954/20.624/21.109FPS average20.896; candidates21.107/22.298/22.450 average21.952 (+5.053% arithmetic). Two candidates exceed the control range and one overlaps. Every capture fails. All three candidate longest drops below40 are longer than their paired controls; average p99 is similar. Do not retain a validated gain from this mixed first series. [All metrics/receipts](validation/STEAM_DECK_ENTRY_CONTEXT_20261023.json).

Actual file CRC, four public function locations, nativeCclock/plain metadata, normal seeds/resources/population, physical input, focus and both-display gates pass. End health211/168/211/160/211/211 varies without a demonstrated cause. All owned games stop and the candidate is reinstalled while quit. CI74e8ec47 is325/334/source_changed0, with the same nine failing names and five file/line anchors as9d2/438/3cf; source, VR and audio pass.

Next: unchanged source/conditions in another fixed fresh P,C,C,P,P,C60s comparison to check repeatability and the pacing concern. Both monitors stay ON1280×800@60/external1920×1080@75; normal AI/resources/counts/actions/graphics/power remain. No active profiler/wrappers/device sampler/JIT setting/affinity. No source gain or full-scenario acceptance is claimed.

Target UNMET; all six full scenarios UNVERIFIED. PR7 remains draft; main stayscec10dc54.

# Current checkpoint — guarded reuse of already-serviced admission context

BeforeAI currently services entry ownership, then Claim repeats Service and Context. Candidate extracts the same admission core and borrows the serviced context only while native function/C-clock identities, plain tables, current owner/state/graph/seed/level/epoch/run and future deadline match. Custom providers, metatables, inherited methods, clock changes and lifecycle/deadline changes keep public Claim. Admission results and actor positions are never cached; service cadence, quotas, movement and combat remain.

21cases/71assertions pass; the exact parent fails the redundant-work gate. Existing shared AI, B29 quotas/lifecycle/production coroutine/withdrawal/routes/freeze/UI and spatial/config/refresh gates pass. The selected42check checkpoint has38initial passes, three known parent failures and one missingNode failure; that manual-reader check passes after installing official checksum-verified Node24.22.1. No full green matrix is claimed. [Candidate scope and gates](validation/STEAM_DECK_ENTRY_CONTEXT_20261023.json).

Next: verify actual source/function locations, native clock and metadata, then fixed fresh source P,C,C,P,P,C60s D20 runs. Both monitors remain ON at1280×800@60/external1920×1080@75; same normal resources, counts, AI, actions, graphics and power. No private wrappers/profilers/samplers during FPS. Keep or revert only on supported performance and regression evidence.

Target UNMET; all six full scenarios UNVERIFIED. PR7 stays draft; main remainscec10dc54. Both JIT settings, affinity, key-cache, animation and per-call player-query candidates remain rejected.

# Current checkpoint — trace-length setting rejected; guarded entry candidate next

Four fresh D20 arms finish at22.073stock/22.252candidate/20.755candidate/20.883stockFPS. Means21.478stock and21.504candidate (+0.122% arithmetic) overlap without useful benefit. All captures fail. Public maxrecord16000 requests succeed in both realms with identical optimization flags; no JIT on/off/flush, disabled API, affinity, profiler or active sampler is used. Source, normal seeds/resources/population, physical input, focus and both-display gates pass. Both monitors stay ON at1280×800@60/external1920×1080@75. All four owned games stop, clearing the setting. Reject it. [Evidence](validation/STEAM_DECK_JIT_RECORD_20261023.json).

Next: guarded reuse of the context already serviced by BeforeAI, with current owner/state/graph/seed/level/epoch/run, deadline, original-function and plain-table checks. The isolated candidate passes19cases/65assertions plus existing shared AI/B29 contracts; the exact parent fails its redundant-work gate. This is source preparation and operation evidence only, not a Deck gain. Keep public callbacks, admission decisions, fresh positions and normal service cadence. Native source verification and matched source FPS remain required.

Target UNMET; all six full scenarios UNVERIFIED. PR7 stays draft; canonical main remainscec10dc54. No JIT setting or affinity remains.

# Current checkpoint — thread placement rejected; trace-length comparison next

Both monitors stay ON at internal1280×800@60/external1920×1080@75. Four fresh D20 arms complete: stock21.344, separated22.525, separated20.065, stock21.398FPS. Stock mean21.371 versus candidate21.295 (−0.355% arithmetic) supplies no supported gain; reject the masks. Main CPU2 and worker0,1,4,5,6,7 masks remain exact over both candidate captures; actual siblings2–3 are verified. All owned games stop, clearing masks. Source/function, normal seeds/resources/population, physical input, focus and display gates pass. All four captures fail; end health153/211/154/163 varies without a demonstrated cause. [Full measurements](validation/STEAM_DECK_THREAD_PLACEMENT_20261023.json).

Next: public jit.opt.start maxrecord16000 versus untouched stock, four fresh stock/candidate/candidate/stock60s arms. Native Lua module CPU/table-lookup evidence motivates a trace-length hypothesis; trace aborts and native default numeric limits are not observed. The prior maxtrace cache-count change had no benefit and stays rejected. Require both-realm API/unchanged-flag receipts, source proof and ordinary workload; no disabled API, JIT on/off/flush, profiling wrapper, affinity or active sampler. Boundary counters are uniform. No JIT setting is retained without measured benefit and regressions.

Cell-key runtime remains restored exactly to1ce30e75, with useful28062case tests and120/116/52sourcewatch coverage retained. Target UNMET; all six full scenarios UNVERIFIED. PR7 remains draft; canonical main stayscec10dc54.

# Current checkpoint — cell-key cache rejected after six original-source Deck runs

Both monitors remain ON at internal 1280×800@60 and external 1920×1080@75. Controls21.539/21.033/22.529FPS average21.700; candidates21.446/20.664/19.703 average20.604 (arithmetic−5.05%). All six60s captures complete and fail. Ranges overlap; no general slowdown cause or statistical significance is claimed. The installed key function passes12,864 native comparisons and halves100k-call microcost, but that does not supply a gameplay gain. Reject the cache and restore the generator byte-exactly to1ce30e75. Keep28,062 behavior cases and source coverage120total/116server/52client. [Measurements and decision](validation/STEAM_DECK_CELL_KEYS_20261023.json).

All source/function, normal resources/seeds/population, physical input, focus and display gates pass. End health156/201/160/206/211/211 varies without a demonstrated cause; structured ends60.452–61.420s include post-FPS time. Full fight phases and multiplayer behavior remain unverified. All owned games stop. Candidate43821d1a CI is325/334 with the same nine failing suite names and five file/line anchors as3cf; source, VR and audio pass. No full green claim.

Next: compare stock thread placement with mainCPU2/workers0,1,4,5,6,7, using actual2–3 SMT siblings and boundary-only counters. Earlier D1 all-threads-four-core masking had no benefit; this distinct experiment tests separating the main thread from its own workers, not a measured SMT cause. Preserve normal gameplay, graphics, power and both monitors.

Target UNMET; all six full acceptance scenarios UNVERIFIED. PR7 stays draft; canonical main remainscec10dc54. No key-cache, callback-coalescing, animation, player-query or JIT-setting candidate remains.

# Current checkpoint — cell-key source candidate; native source/FPS validation next

A pure native prototype passes 12,864 key comparisons, including all 690 actual graph cells, signed zero, non-integers, strings, invalid inputs and concatenation metamethods. Six alternating 100,000-call measurements average 12.740 ms for the parent and 5.792 ms for the fixed component lookup. This is narrow prototype evidence, not installed-source or gameplay FPS proof.

The generator now borrows 255 fixed positive integer strings when the runtime uses unified numeric string representations. It retains original operands for zero and all uncached inputs; it stores no graph or actor state. The source manifest now covers the generator: 120 total / 116 server / 52 client. All affected count fixtures explicitly cover the new authority. Key contracts pass 28,062 cases on both Lua and standalone LuaJIT; existing transport, B28 replay/source, shared AI, route and entrance-safety gates pass. [Evidence and limitations](validation/STEAM_DECK_CELL_KEYS_20261023.json).

Next: installed-source value/function receipt, then a fresh original-source parent/candidate/candidate/parent/parent/candidate D20 comparison with matching manifests. Both monitors remain ON at internal 1280×800@60 and external 1920×1080@75; normal graphics, AI, resources, population and frozen physical actions remain.

The JIT-capacity screen is complete with no useful effect (stock mean 20.930 FPS, requested32768 mean 20.913); reject the setting. The later instruction-hook diagnostic severely perturbs gameplay to about 1 FPS and misses capture-duration tolerance. Its hook interval was requested but not independently verified, and no sample/restoration file was collected before the owned process stopped. Do not use it for timing or coverage attribution; no hook survives process cleanup. No callback-coalescing or JIT candidate is retained.

Target UNMET; all six full scenarios UNVERIFIED. PR 7 remains draft; canonical main remains cec10dc54. Source candidate is pending native source/FPS verification and is not a completed performance claim.

# Current checkpoint — callback screen inconclusive; public JIT-capacity comparison

Both displays remain ON at internal 1280×800@60 and external 1920×1080@75. Four fresh-game private callback arms complete: parent 21.559, candidate 22.881, candidate 22.914, parent 22.812 FPS. The arithmetic mean difference is +3.209%, but the final control nearly matches both candidates and control spread exceeds the mean difference. Do not retain a source gain from this screen. All captures fail the budget. Both leases restore original callbacks; all source, normal resource, physical-input, focus and display receipts complete. [Measurements and limits](validation/STEAM_DECK_COLLISION_COALESCE_20261023.json).

End health differs (parents 188/191, candidates 211/211), without an established cause. The direct return matrix does not prove complete hook precedence, physical contacts or multiplayer correctness. The prepared source edits were never installed or committed; they are archived privately and the isolated worktree is clean. Mounted gameplay remains unchanged from 3cf2e875.

The public jit.opt.start API accepts maxtrace=32768 in both realms while reported optimization flags remain identical. No jit.on/off/flush or disabled reflection/profiler workaround is used. Stock numeric capacity is not publicly exposed; saturation or eviction is a hypothesis, not an observed cause. A predeclared fresh-process stock/32768/32768/stock D20 comparison is running with normal gameplay/settings and boundary-only counters. The first stock arm is 21.117 FPS, p95 85.610 ms: FAIL. No JIT configuration or gain is retained yet.

Target UNMET; all six full scenarios UNVERIFIED. PR 7 remains draft; canonical main remains cec10dc54. Finish the capacity comparison, inspect complete source/resource/input/display/flag and memory evidence, then retain or reject on measured effect and continue.

# Current checkpoint — native CPU samples; callback comparison in progress

Both displays stay ON at internal 1280×800@60 and external 1920×1080@75. A native 99 Hz main-thread diagnostic saves 5,890 samples with zero loss. Saved PE image ranges map 42.65% to lua_shared.dll, 15.84% to client.dll, 10.66% to server.dll and 9.95% to engine.dll. These are module shares, not exact Lua-function, realm or GC attribution. Instrumented gameplay still fails: 21.212 FPS, p95 83.325 ms, p99 123.191 ms, longest drop 23.338 seconds. Sampling overhead is unmeasured.

The collector rejected the requested profiler SIGINT after flushing. Intact raw FPS was recovered before another launch; no post-capture CPU snapshot or display check is fabricated. The standard public jit.profile module is unavailable in both realms. No disabled API or native-module workaround was used. Failed startup harness attempts are preserved; their private bridge and stock menu edits are restored exactly. Native launcher command forwarding now resumes the paused failed-menu overlay, with actual client ACK and readiness gates.

A combined collision-callback prototype passes 6,400 return comparisons over 80 cases with zero mismatches and unchanged registrations. A predeclared fresh-game parent/candidate/candidate/parent 60-second screening comparison is running with no profiling or device sampler. Native collision flags/groups, AI, counts, normal resources and frozen actions remain. No source candidate or performance gain follows the value gate alone. [Raw evidence and limitations](validation/STEAM_DECK_NATIVE_CPU_20261022.json).

Target UNMET; all six full acceptance scenarios UNVERIFIED. PR 7 remains draft; main remains cec10dc54. Finish the comparison, check complete receipts and restoration, then retain or reject on measured evidence before the next focused change.

# Current checkpoint — native collision alternatives rejected before source changes

Both monitors remain ON: internal 1280×800@60, external 1920×1080@75. Sparse callback classification restored both bindings after 68.02 seconds. Separation ran 3,573 calls/s and latch handling 3,068 calls/s; most sampled pairs involved static geometry. Callback-body estimates total 13.2 ms/s and do not measure native bridge or broadphase overhead. The diagnostic capture still fails at 22.43 FPS.

The predefined native trace gate rejects group 19 with custom checks disabled: all four NPC-pair traces change, although four player shots, four movement hulls and floor support match. Exact groups, flags, health and positions were restored; no production change follows. Native constraint.NoCollide is unavailable because both actual actors lack the required physics bodies. No constraint was created and state was restored. [Evidence](validation/STEAM_DECK_COLLISION_20261022.json).

Next: sample the main thread at 99 Hz with native user cpu-clock events and no Lua wrappers to separate execution, GC and engine costs. Sampling is diagnostic only. Source 3cf2e875 retains no animation or player-query candidate. Target UNMET; all six full acceptance gates UNVERIFIED. PR 7 remains draft and canonical main remains cec10dc54. CI is 325/334 with the same nine failing names and five leaf anchors as the preceding runs; source, VR and audio checks pass.

# Current checkpoint — player-query candidate rejected after six Deck runs

All six original-source D20 attempts complete with native source/function receipts, normal resources/counts/AI, structured60s+ input endings and BOTHdisplaysON. Controls21.943/22.025/21.671FPS average21.880; candidates21.397/21.046/21.030 average21.158 (arithmetic−3.30%). Every candidate is slower than its adjacent control, tails vary and allcapturesFAIL. No statistical significance or CPUcause is inferred from three pairs. Reject the candidate; restore RunManager and Staging runtime files exactly toafff7087. Keep15behavior-only query cases/55assertions; existingSharedEnemyAIWork/syntax/diff pass.

The native1007case/value/guard/microtiming proof remains valid historical evidence, not a gameplaygain. No private counters, debughooks, provider replacements or device samplers ran in the FPS windows. The manual-stop metadata change only exposes/invokes the existing stop callback afterFPS; CreateMove body is byte-identical. [Raw results/conditions/decision](validation/STEAM_DECK_PLAYER_QUERY_20261022.json).

TargetUNMET; allsixfullacceptancegatesUNVERIFIED; PR7draft/maincec10 unchanged. Allownedgames stopped. Next: native collision callback/broad-phase attribution, then a focused measured change if warranted. BothmonitorsONalways/internal1280×800@60/external1080p75. No unvalidated query/animation candidate remains.

# Current checkpoint — installed active-player query gate passed; source FPS next

Installed73bcd0c0 passes1007native value/state-transition checks with all default/nativeAPI/table guards true. Slot, deployment, missing-profile and same-seed State replacement remain fresh; originals restore. Six100kquery microarms preserve results: parent155.155–158.439ms versus installedcandidate55.448–58.131ms. This is narrow query timing, not gameplayFPS. The first debugcallhook counter undercounts eventheknownparent; retain it as an INVALIDdiagnostic with full restoration/gameStop, neveractualcallcount evidence.

afff7087 fullCI returns325/334FAIL with the same nine names AND allfivefile/lineanchors asf889. The seven sharedB28fixture failures are cleared. Source/VR/audio pass. Current73bcd0c0 CI remains a separate pending gate. [Evidence](validation/STEAM_DECK_PLAYER_QUERY_20261022.json).

Next: frozen freshoriginalsourceP,C,C,P,P,C gameplay comparison with BOTHdisplaysONalways, internal1280×800@60/external1080p75. Preserve normalsource/seed/counts/AI/input/graphics andfailedattempts. No profiler or in-window device sampler. TargetUNMET; allsixfullacceptancegatesUNVERIFIED; PR7draft/maincec10 unchanged.

# Current checkpoint — per-call active-player query candidate; native source timing pending

Both monitors stay ON at all times, external1080p75/internal1280×800@60. The native deployed-Hero probe confirms3identity lookups/1profile query per IsActivePlayer call. Private within-call prototype100kqueries150→47ms; guardedprototype189–192→79–81ms in a separate process. Both pass1006checks andrestoreproviders; this is microevidence only, not gameplayFPS or wholeacceptance.

Candidate shares only original function identities from RunManager, then reads current identity/slot/profile/deployment once per call. It caches no identity, PlayerState or eligibility across calls. Custom provider/validity/nativeAPI/tablemetatable/registry changes retain the existing path, order and results. Staging.IsDeployed and role/life/progression rules remain. LiveGDD06 revision is unchanged;4Hero+6Soldiercap and20srespawn remain. No tuning/GDD edits.

The production-query contract passes17cases/78assertions including removal/reconnect, same-seed state/map replacement, staging, roles, bots, mutable-registry tampering, custom callbacks and native/globalvalidity. Existing SharedEnemyAIWork includes this gate. Deployment, inventory transition, Damsel staging,196Soldierqueue assertions, TimeManagement, stagingevent/SQLite, Crypto/SQLite and syntax/diff gates pass. Next: fresh installed-source nativepath/transition/counter proof, then matched original-source gameplay comparisons. [Evidence](validation/STEAM_DECK_PLAYER_QUERY_20261022.json). TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10 unchanged. Prior animation candidate remains rejected.

# Current checkpoint — animation candidate rejected; shared fixture repaired

Keep BOTH displays ON always: internal1280×800@60/external1080p75; session blanking inhibition remains held. Six original-source attempts preserve the frozen P,C,C,P,P,C order. Valid controls21.247/22.322/21.942FPS average21.837; valid candidates21.113/21.352 average21.232. Ranges overlap, tails are inconsistent and every run fails. Candidate03 dies ordinarily at47.315s/node157 and has only47.275active seconds; retain it as failed/incomplete with no replacement. This is three valid controls/two valid candidates/one failure, not three complete pairs. No statistically established slowdown is claimed.

The installed native resolver microprobe passes5763checks across57realactors and reduces114000queries from183.576–184.547ms to96.994–99.490ms with equal results and restored cache fields. That narrow cost reduction does not supply a whole-game FPS gain. Reject the candidate and restore sv_hostile_animation.lua exactly to62d587cb. Retain behavior-only cache invalidation tests and source coverage119total/115server/52client. The five completed FPS runs verify actual function/filehashes, normal resources/1820models andbothON. Console ticks>=60s andmanualhookstop corroborate physical input; manual stop produces no structured end receipt. Fullphases remainunverified.

eb1 fullCI is318/334FAIL: seven NEW sharedB28fixture count failures plus nine known parent failures. Repair the fixture to115 and explicitly require the animation source; keep all gameplay assertions. All seven affected gates pass locally, plus animation/skeleton/manifest/transport/syntax/diff checks. NewCI pending; no fullgreen claim. [Complete decision and raw paths](validation/STEAM_DECK_ANIMATION_CACHE_20261022.json).

All owned game processes are stopped. Next: finite native measurement of repeated per-call player/deployment queries; no persistent identity/state cache or skipped callback checks. TargetUNMET; allsixfullacceptancegatesUNVERIFIED; PR7draft/maincec10 unchanged. Continue required ordinary gameplay/fullphase/fourhuman coverage.

# Current checkpoint — animation cache candidate; native timing pending

Both displays remain ON at all times, external1080p75/internal1280×800@60. The normal60s Deck D20 route is22.329FPS,p9577.102ms,p99116.449ms,longest drop25.236s: FAIL. Boundary counters show the main task96.17%ofonecore and0.420srunqueuewait in64.917s; gameGPUgraphicsengine6.28%busy. This points to main-thread CPU work without changing monitor power or graphics.

A bounded broad Lua diagnostic restores2244bindings after skipping68duplicatealiases. Inclusive estimates overlap; wrapping CellCenter changes its identity fallback, so that timing is excluded. The first alias lease failed restoration and its game was stopped; raw failure remains. Animation resolution is a frequent shared query. Candidate borrows the current native instance table only for an owned cache hit; currentmodel/razor/hold checks and original miss/inherited/missing fallback remain. No actor, animation, combat or AI timing changes.

Focused animation/skeleton/fallen/entry/hurt/Razor/lifecycle gates pass; exact parent fails the new native-shaped owned-cache test. Native original-source timing remains PENDING. Next: finite native microdiagnostic, then matched fresh source gameplay measurements; retain only supported benefit. [Evidence](validation/STEAM_DECK_ANIMATION_CACHE_20261022.json). TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10 unchanged.

# Current checkpoint — both displays stay on; frame budget still fails

Explicit user requirement: keep BOTH monitors ON at all times and achieve40FPS in that configuration. Session idle inhibition is held; external1920×1080@75 is restored and internal1280×800@60 retained. No future monitor-off arm is allowed. Historical off data remains diagnostic only. The final both-on short Dungeon20 arm is21.129FPS,p9587.416ms,p99120.272ms,longest drop15.186s: FAIL. No source improvement is inferred from the display series.

f889bf95 full CI completes325/334FAIL. All nine failing suite names AND exact file/line anchors match bc95; the new8d boss-framework fixture failure is cleared. Source/VR/audio checks pass. No full green matrix or performance acceptance is claimed. [Display/CI evidence](validation/STEAM_DECK_BOTH_DISPLAYS_20261022.json).

No game/server remains active. Next: bounded before/after process/thread CPU and scheduler accounting around the same ordinary gameplay route, preserving both displaysON and all workload/settings. TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10 unchanged. Continue measured optimization and missing gameplay/multiplayer coverage.

# Current checkpoint — dedicated finale still fails tails; integration fixture repaired

A separate same-Deck dedicated Dungeon20 diagnostic averages42.003FPS, median19.822ms, p9543.540ms, p9955.264ms, max275.124ms, longest drop4.619s/four episodes>=2s: FAIL. Preserve the frozen listen-host failure at22.934FPS; this variant does not replace it. Exact source,1820clientmodels,normalWizard20/seeds/resources,one human/four slots,66HznativeAI,57roamers and allninebossactors are verified. Native ownership/support passes; one commit and zero retries. Full phases, upper floor, Hector/rescue and four actual humans remain unverified.

Native profiling attributes25.000ms/frame inclusive to server simulation,11.320ms to NextBotLua and12.772ms to rendering; preparation and overlapping scopes are included, so these are diagnostic only. Sparse samples restore173bindings, then detailed entry samples restore162. Movement and entry checks are the larger measured shared costs. Do not cache across callback-bearing admission paths or change cadence without proof. No further runtime candidate follows8b0b531e yet.

The8d478035 full CI run is324/334: one NEW boss-framework fixture failure plus the nine known parent failures. The two finale integration fixtures supplied floors only to ray queries. They now provide native-style point-width vertical hull support; every composition, rollback, exactly-once handoff and rescue assertion remains. All76boss-framework cases pass locally. This is test-only repair; runtime/source8b remains unchanged. New full CI is pending, not claimed green. [Raw evidence and results](validation/STEAM_DECK_FINALE_SUPPORT_20261022.json).

Both local game/server processes are explicitly stopped after the diagnostic. Next: continue measured shared CPU/client-cost investigation and required coverage. TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10unchanged. Restore externalDP1to75Hzafterbenchmarks.

# Current checkpoint — finale composition repaired; functioning fight still fails

Retain 8b0b531e's native floor-support repair. The same frozen Deck route now commits one Gordon, four clones and all four Sentries exactly once, with zero composition retries and zero Lua errors. All four real Sentries pass the post-capture ownership and five-point support gate. Ordinary incoming damage reduces HP211 to192 during the run. The baseline could not commit combat, so its 5.447→22.934 FPS change measures the repaired retry pathology, not identical functioning-fight workloads or acceptance.

The functioning fight still FAILS: 22.934 FPS, median36.877ms, p9576.116ms, p9998.104ms, max468.224ms, longest drop25.195s. Only phase1/lower-court coverage is observed. The later native ownership probe finds the player dead after the capture; that is not hidden or used as performance acceptance. Next: same-route native VProf diagnostic on the functioning fight, preserving source, resources, counts, AI and graphics. [Raw results and coverage](validation/STEAM_DECK_FINALE_SUPPORT_20261022.json).

Target UNMET; all six full gates UNVERIFIED. PR7 stays draft and canonical main remains cec10dc54. Continue measured optimizations and missing upper-floor, full-phase, Hector/rescue and real four-player coverage. Restore external DP1 to75Hz after benchmarks.

# Current checkpoint — native finale support defect; same-route source validation next

The first clean Deck Dungeon 20 lower-court run fails: 5.447 FPS, median 196.041 ms, p95 305.864 ms, p99 334.240 ms, maximum 387.357 ms, longest drop 58.818 seconds. Input reaches waypoint 187 with zero Lua errors. No encounter commits: 263 complete-group retries each reject all four required Sentries. Combat and phase coverage remain unverified. The private route's incorrect cell-size assumption was corrected before its first timing capture; the clear 640-point, 288-unit-radius route is now frozen.

A bounded native admission probe records 44 support refusals and restores both methods. Native rays miss the generated floors; zero-width, one-unit-tall hulls hit all 20 footprint samples within 0.03125 units of the expected height. Change only T:Supported's query. Preserve its five points, mask, filter, range, normal, height tolerance and non-actor support checks, plus full route, stair and occupancy checks. Preserve the complete composition and existing retry cadence.

SPOT-08 passes 262 assertions; the exact parent fails the new native BBOX floor case. Warden, SPOT-06 (116), SPOT-07 (130), Hector/finale lifecycle, manifest/transport, B28 and syntax checks pass. The manifest now covers 118 total / 114 server / 52 client files. Next: install the committed candidate and repeat the same Deck route. No source FPS gain or encounter acceptance is claimed yet. [Evidence](validation/STEAM_DECK_FINALE_SUPPORT_20261022.json).

bc95 CI source/VR/audio checks pass; the full matrix remains failed at 325/334 (run 39845300211). SteamOS authorization policy denies the optional GameMode governor test; CPU settings remain unchanged. Continue unaffected work. Target UNMET; all six full gates UNVERIFIED; PR 7 stays draft and main remains cec10dc54. Four actual players remain unavailable. Restore external DP1 to 75 Hz after benchmarks.

# Current checkpoint — vector candidate rejected; retained runtime restored

Six frozen fresh-process actualDeck source comparisons finish with no repeatable benefit. Current39.014/36.561/35.921FPS averages37.166; parent37.469/37.877/36.318 averages37.221. Ranges overlap, two adjacent pairs are slower, tails are inconsistent and every run fails the budget. Revert51d8a5a0 movement/B7test changes exactly to32d82a82; no gain or proven slowdown is claimed. Native12000case exact math/input proof and all focused correctness gates remain valid historical evidence, not FPS acceptance.

The sequence was frozen parent/current/current/parent/parent/current before its first parent result, with external sensor monitoring OFF uniformly. Earlier sampler-on/off source runs remain as exploratory diagnostics; one pair does not prove observer overhead and is not mixed into the source comparison. Every source arm verifies its actual native motion algorithm/wrapper chain, normalWizard13/3items/seeds/population/1348models, source hashes and complete60s input/capture; eachprocess is explicitly quit. [Raw metrics, conditions and decision](validation/STEAM_DECK_MOTION_VECTORS_20261022.json).

Candidate51 CI lowend/VR/audio passes. Fullmatrix325/334 has the same9knownparent suite/anchor signatures (raw39841156806), notgreen. Earlier two fixture omissions were repaired in32d82a82; assertions retained. Runtime now keeps the validatedc11historycache/b19modelpreload/77bossdraw repair and earlierCPU/render improvements, with no Motioncandidate. TargetUNMET; sixfullgatesUNVERIFIED; PR7draft/maincec10unchanged. Next: inspect remainingCPU/render scheduling cost and continue fullboss/finale coverage without changing the frozen workload or acceptance limits.

# Current checkpoint — native history serialization hitch reduced; full budget still fails

Retain c11c3567 as a recurring history-save hitch improvement. Six alternating same-process native comparisons preserve identical decoded1000-row history and equal payload sizes: parent44.004–50.333ms (mean46.068), cached3.900–5.600ms (mean4.613). The actual native JSON mutation/order/replacement gate passes320452assertions; originalhistory/writer/encoder restore, and no test rows reach the preferred disk file. Source I/O profiling shows151JSONcalls total10.751ms/max5.251ms(reportexportaftercapture), with no active-gameplay encode>=1ms, versus the earlier1028.736ms/max53.799ms. All three profiling bindings restore.

The original Deck listen-host180s uninstrumented route still FAILS:36.343FPS,median26.121ms,p9539.632ms,p9962.382ms,max168.912ms,longest9.489s/13episodes>=2s. The older36.331FPS average is indistinguishable within noise; do not claim steady FPS or full-tail acceptance from one before/after run. Input completes180s. Exact raw paths and data are in [native cache evidence](validation/STEAM_DECK_HISTORY_CACHE_20261022.json).

A separate68s same-call server diagnostic records1122tiny log appends/305866bytes at1039.757ms total/max33.367ms;233JSONcalls total19.232ms/max1.107ms. Logging cost is observed, not changed. All APIs restore. Next: narrow the normal AI phase cost without changing cadence/condition servicing; remaining bosses/finale/fullphase and four actual players remain unverified. Existing/static cache gates below pass. CI correctly catches two stale capture/profiler fixture manifests missing the new feedback source; both now include it and both local gates pass. This is test-data repair only; runtimec11 remains unchanged. New CI/full matrix is pending; c11 did not reach the full matrix. Target UNMET, all six full acceptance gates UNVERIFIED, PR7draft/maincec10 unchanged.

# Current checkpoint — encounter-entry stall reduced; steady frame budget still fails

Retain b19bccfb as an asset-stall improvement, with no steady FPS claim. Two fresh native source runs (no private precache or extra profiling) move the same eight Chuck/Jane models into the existing held loading period. Loading records 1.196/1.164 seconds of boss asset work; maximum gameplay frames are 117.762/134.200 ms, versus the 1,218.346 ms baseline with the cold commitment measured at 1,175.624 ms. The selected citizen, real encounter RNG, canonical checkpoint, actor counts and render bounds remain correct. Both short runs still fail steady timing: 38.156/37.015 FPS, p95 39.502/40.467 ms, p99 62.301/66.257 ms. Full phases and warmed acceptance remain unverified.

Current runtime b19bccfb (label 0070179c changes tests/docs only) completes the frozen Dungeon10 v5 input for 180.041 seconds through waypoint198. Its unprofiled capture averages36.331FPS, median25.929ms, p9539.986ms, p9973.949ms, max159.411ms and longest below40 episode13.179seconds: FAIL. Compared with the older36.460FPS baseline this supplies no steady gain; do not attribute route/preparation differences to source performance. Raw captures and thresholds remain unchanged.

Model-preload framework76cases and companion118assertions pass. Source-watch and population transport pass after updating their manifest expectation to112server/116total sources. Bootstrap recovers its skeleton timeout in isolation; known quiz164/dodge177 failures remain. Completed0070179c integration remains325/334 with the same nine known parent failure signatures; source/VR/audio CI pass. No full green matrix is claimed. Native bounds proof and ordinary incoming damage are observed; V1 coverage correction below remains binding.

Next: measure a separate same-Deck dedicated configuration with identical normal AI cadence and source, while retaining the frozen listen-host acceptance. Continue later-level/full-phase preparation. Target UNMET; all six complete gates UNVERIFIED; PR7 remains draft and canonical maincec10dc54 is unchanged. Four actual players remain missing. ExternalDP1 must return to75Hz after benchmarks. [Compact measurements](validation/STEAM_DECK_BOSS_PRECACHE_20261022.json).

# Current checkpoint — native boss draw repair proved; performance still fails

Installed77db9cfe normal Chuck/Jane DrawActor returns complete51times. Both actual render bounds match the native-model/scale expansion, the beaver marker remains, the finite probe restores in0.97s, and both realms report zeroLuaerrors. This passes the finite native API/draw-bounds repair gate; full appearance/phase/performance acceptance remains unverified. Its60s orbit is37.533FPS,p9538.551,p9959.781,max1197.560,longest2.659s: FAIL. No FPSgain is attributed to the correctness repair.

A separate75s bounded boss-method profile restores everybinding. BossService7.594inclusive ms/s, routevalidation only7calls/0.471ms/s/max12.590ms; nestedrows overlap. No route rewrite is warranted. The first-entry~1.2s stall is absent in the warmed repeat, but asset loading is not yet proved as cause. Next: a fresh-process native VProf capture of firstentry, then normal later/finale baseline preparation.

Private ordinary behavior dispatch also fails to demonstrate a repeatable gain: parent33.869/36.720FPS versus direct36.989/36.019, overlappingranges. Everydirectcallback runs exactly1canonicalstep (94585/94137), zeroerrors, all34ordinaryactor overrides restore. Watchers/newactors retaincoroutines; cadence/counts unchanged. Rejecttheprototype; no productionAIchange. A separatePlayer-onlylookup microprototype is also leftunadopted: only~0.3ms/10kactualqueries, no wholeFPSclaim.

Current target UNMET, all six complete acceptance gates UNVERIFIED, PR7draft/maincec10 unchanged. Preserve the frozen scenario thresholds/routes and actualfailedcaptures. ExternalDP1 stilltask60Hz, restore75afterbenchmarks. Fouractualplayers remainmissing. Currentgame explicitlyquit17:43UTC beforefresh nativecold-encounterdiagnostic.

# Current checkpoint — native boss draw API repair; source gate passed

The first normal-resource Dungeon14 orbit exposes a production client error at cl_boss_encounter.lua:91: util.GetModelBounds is absent. Native Entity:GetModelBounds is present for both Chuck and Jane. The old code marks the model/size signature before throwing, leaving its intended RenderMultiply and expanded bounds unapplied. Use the native Entity method and publish the signature only after setup completes; preserve scale, origin arithmetic, module drawing and server gameplay.

Both presentation transports pass all18modular bosses. A new existing-harness draw gate verifies native Entity bounds with util API absent, exact scale/origin/render bounds, unchanged setup reuse and model/size invalidation. It fails on the exact parent and passes the repair. Fresh installed native bounds/appearance/no-error verification and equivalent boss profiling follow. This is a rendering correctness repair, not a measured FPS gain.

Normal preparation now proves Wizard17/HP180/AR2clip20/3canonicalitems, Dungeon14 seed1217158876/layout1761773386,54roamers/1748models. A320point radius700 court circuit passes native PlayerHull sweeps before boss commit; dynamic hazards remain. The first60s, sourcecb90f2e7, averages37.585FPS,p9539.403ms,p9956.940ms,max1227.957ms,longest3.702s. FAIL timing and clean runtime; onlyphase1 observed. Raw `/home/deck/deborah-benchmarks/boss-baseline/cb90f2e7/d14-route60-run1/`. This is an iteration, not warmed full acceptance.

Target UNMET; all six complete gates UNVERIFIED. PR7 stays draft/maincec10 unchanged. Previous candidate rejection/evidence below remains authoritative history.

# Current checkpoint — typed component candidate rejected; retained runtime restored

Six matched60-second actual Deck comparisons of a76ef534 complete with fresh native installation/restoration receipts. Current37.985/37.420/37.012FPS averages37.472 versus parent35.589/37.491/35.719 averaging36.266. The positive arithmetic difference3.325% is not separated from observed variation; ranges overlap and one adjacent pair is slightly slower. Tails are inconsistent and all six fail the budget. Do not claim a gain or proven slowdown. Restore both static-box source files exactly to5889d8bf/runtime4d0a6d80; preserve candidate history and evidence.

Native correctness passed1209boxes, raw SetDTVector and custom bounds/pose/angle methods, with synchronous restoration. Candidate scoped checks28/29 retain the exact existing keycard hook.Remove test-double failure. These facts do not establish performance. Raw `/home/deck/deborah-benchmarks/typed-components-source/a76ef534/`; compact receipts accompany the iteration record. Original installed-hook full acceptance was never claimed for the diagnostic clones.

Next: establish the remaining normal boss/later-level baselines and inspect the measured AI/context work for a focused same-call improvement. No across-frame actor/cache shortcut or altered tick/AI cadence is authorized. Target UNMET, all six complete gates UNVERIFIED, PR7 draft, maincec10dc54. Current game was explicitly quit17:00UTC before restoration; start a fresh independently owned unit for next native work.

# Current checkpoint — typed component batching candidate; native timing pending

The raw bounds-notification probe proves native Vector copies and typed setter notifications, but direct SetDTVector does not notify. Cross-frame bounds caching is rejected. This narrower candidate retains every fresh bounds/pose getter and batches components only for proven native return types. Declared Vector getters are verified against their captured native GetDTVector reader; native GetPos/GetAngles method identities verify pose types. Unknown/replaced APIs retain scalar reads. Unlike rejected b04e1224, no per-value native type check is added to the hot path. No cross-frame values, selection, counts, collision or timing are cached/changed.

Existing renderer/geometry regressions pass. Complete scoped gate and native mutation/override/raw-datatable/restore proof precede any gain claim. Compare equivalent actual Deck runs and retain only a repeatable benefit. Current acceptance baseline and all full gates below remain failed/unverified; target UNMET, PR7 draft.

# Current checkpoint — complete physical baseline fails; broad Lua profiling

Current source68a6a9d3 exactly restores runtime4d0a6d80 after rejecting component-read candidate b04e1224. Native use is available in persistent user service `lod-deck-movement-profile-20261022`; no device-access blocker. No production source candidate is active.

The physical Dungeon10 route is now315points. Existing authored upper landings, north-side lower returns and hull-validated corner clearance support ordinary player movement; no collision/AI changes. Native input completed180s alive, health164→102, and cleared both prior stalls. Canonical NewCampaign resets fixtures while retaining the warmed VM/JIT. A strict preflight waits for1348models/materials; playback starts with audit sampling. These preparation corrections are frozen before further performance changes; old failed routes/captures remain.

The first aligned warmed180s baseline is36.460FPS, median25.276ms, p9541.771ms, p9980.233ms, longest below40 5.788s/13episodes>=2s: FAIL. This is one baseline, not complete scenario acceptance. Raw `/home/deck/deborah-benchmarks/dungeon10-physical-v5/68a6a9d3/baseline180-run1/`. Source checks and idleVR hold. Normal Magic casts, shooting, damage/reloads and pickups are logged; exact coverage enumeration remains.

A scalar swept-entry prototype matches2916native cases per arm but supplies no reliable gain in four matched60s arms: parent35.436/37.145FPS vs scalar35.862/33.319 (means36.290vs34.591, overlapping ranges). Every public-method lease restores the original; no production change. The native engine profile instead attributes15.561ms/frame inclusive to Lua calls, including4.711ms NextBot behavior; server10.964ms/render9.454ms overlap these costs. Scope averages include preparation, not acceptance FPS. Next: short bounded FProfiler call trace to identify expensive Lua functions and peaks outside current coverage, restore the debug hook, then optimize the measured larger cost and repeat.

Target UNMET; all six complete acceptance scenarios UNVERIFIED. Keep PR7 draft and maincec10dc54. Four actual players remain unavailable. Preserve all workload/settings/timing criteria and restore external DP1 from task-set60Hz to original75Hz after benchmarks.

# Current checkpoint — actual Dungeon10 gameplay misses frame budget

The Deck rebooted overnight. A persistent user service now keeps the Windows64/Proton10 game alive across tool calls; native captures work. The older unexplained closures are historical evidence, not a current access blocker. No media session survived reboot. External DP1 is temporarily60Hz for matched measurements and must return to75Hz afterward.

Installed282451f5 has runtime source4d0a6d80. Fresh normal Dungeon10 is Wizard13/HP164/164/AR2clip20 with exactly3 canonical equipment items, campaign654759232/level1217158872/layout306806046,36roamers/18planned groups/59planned bodies/1348native models. The earlier six-item/Magnum checkpoint has unexplained equipment provenance; its normal-resource claim is unverified. Do not grant those extra weapons.

The first warmed180s gameplay capture averaged42.899FPS but failed p9531.420ms, p9950.403ms, longest slow episode2.721s/four episodes>=2s. Coverage also failed: the NPC-derived route hit an authored stair guard at waypoint60 after65s. Private playback now uses the existing Navigator upper landings at six points; actual normal input clears that guard in2.612s and hull sweeps are clear. No production collision/AI/source change or source gain is attributed to this preparation fix. Later playback stalls at waypoint90, so full route coverage remains incomplete.

The first60s corrected-route unprofiled baseline is39.251FPS, p9534.561ms/p9953.708ms, longest below40 1.957s: FAIL. Separate full profiling costs material FPS (33.502) and identifies generated geometry, combat-feed drawing and repeated entry-safety checks; those inclusive rows overlap and are not acceptance timing. Next: use a bounded detailed profile to isolate a focused canonical improvement, regression-check it, then compare equivalent uninstrumented source builds. Raw records: `/home/deck/deborah-benchmarks/dungeon10-diagnostic/282451f5/`; resumable private state: `/home/deck/deborah-recovery/CHECKPOINT.json` and `RESUME.md`.

The last retained optimization4d0a6d80 remains validated only for its matched arrival gain (+2.007%,33.979vs33.310FPS). Seven scoped checks/native dispatch pass; full matrix325/334 has nine exact baseline failures. All six complete scenarios, three warmed180s repeats each, separate40cap verification and four actual players remain UNVERIFIED. Target UNMET; keep PR7 draft and do not promote to main as completed40FPS work.

# Previous checkpoint — missing-target admission candidate; target unmet

Fresh uninstrumented8a012398 arrival is32.431FPS, p9537.459ms/p9944.027ms;
the separate full profile is29.172FPS and materially perturbs performance. A finite
one-in64 service sample restored all29bindings. A two-second target counter found
2,880 close-defense admission calls, all with invalid targets. Rejecting that
impossible admission before repeated permissions/geometry gives33.056versus
32.518FPS mean in four short wrapper arms (+1.655%), all failing40FPS.

The source candidate adds only the early native-invalid-target return to canonical
BeginCloseDefense. TickCloseDefense still services status/life; valid-target
commitment/timing remains unchanged. Seven scoped checks pass, including actual
close-defense/Watcher dispatch, status expiry/callbacks and B7 visibility. Next:
fresh installed-source six-arm comparison with exact old function reconstructed
from8a012398; retain only a reproducible gain. No production performance claim yet.
All six full scenarios, warmed180s triplicates, capped play and four actual players
remain unverified. Keep frozen listen-host criteria and normal population/graphics.

# Previous checkpoint — fresh broader profile required; target unmet

The retained live NextBot progression lookup4a6b4aa2 remains the latest source
optimization (+2.458% in the recorded fresh six-arm comparison, all failing40FPS).
Subsequent native32, entity-index, close-defense, affinity and Xalia experiments
showed no reliable useful gain; all were restored. The existing experimental
wall-batch path also misses the budget and visibly omits wall faces; rejected.
Native32's hidden locale-warning modal was diagnosed, allowing actual30.649/30.474FPS
measurements; runtime/visual/shutdown limitations prevent recommending it.
See the current iteration record for exact comparisons and raw locations.

No production change follows4a6b4aa2. Restart the long-lived Windows64/Proton10
process, verify normal native renderer/source/settings/counts, establish a fresh
baseline, and profile broader simulation/rendering cost before another candidate.
Preserve frozen listen-host conditions; the local dedicated candidate remains
separate. All six complete scenarios, three warmed180s repetitions each, capped
verification and four actual players remain unverified. Do not merge as completed
40FPS acceptance. Hosting and four-player access questions remain pending while
independent profiling and scenario preparation continue.

# Previous checkpoint — live NextBot state lookup candidate; target unmet

Clean685 native readback verified111server/51client source hashes and authoritative
cadence/topology metadata. A fresh native32 startup with+nb_update_frequency0.015
before+map retains one tick withsv_cheats0 after a real client joins, despite a
startup protected-cvar warning. A20s counter confirms71,868movement calls and
194,051travel units, then restores its wrapper. The separate local-dedicated
candidate remains outside frozen listen-host acceptance:48.456FPS stationary
misses tails; ordinary first-sector input reaches46.856FPS over80.886active seconds,
p9533.534ms/p9951.083ms and a3.454s slow episode before normal death. It fails.

A finite control/candidate/candidate/control Deck listen-host probe of direct live
NextBot progression lookup measured32.646/32.729 versus33.352/33.217FPS. The small
signal justifies a source candidate, not a completed gain or40FPS acceptance.
The canonical lookup now borrows the live native instance table per call, after
validity; Player incarnation handling and absent/inherited/API-missing fallbacks
remain. Replacement/removal, ordinary AI and human Soldier/Hero lifecycle checks
pass. Eight selected checks pass; the dodge migration assertion at177 reproduces
on parent1335 and matches the prior known matrix failure. No full-green claim.
Fresh installed4a6b4aa2 native checks confirm61NextBots own the expected profile,
the real Player matches, and deferred native removal returns no stale state. Six
alternating30s listen-host arms measure33.649FPS current source versus32.842FPS
old authority (+2.458%), with disjoint FPS ranges; retain the focused change.
Tail latency is not consistently improved and every arm fails40FPS. Next: diagnose
the previously unmeasured native Linux32 startup hang while preserving the frozen
listen-host condition, then resume heavier gameplay profiling. All six scenario gates,
three warmed repeats, capped play and four actual players remain unverified.

# Current checkpoint — server cadence evidence; target unmet

The local native-server candidate now connects through127.0.0.1 with documented
socket-loopback mode. A material correction: native default NextBot updates were
seven ticks, versus one in the listen-host log. Controlled20s counters show
10,756 movement calls/98,691 travel units at the default, versus67,066/217,258 at
one tick. Earlier53–54FPS dedicated results are **not comparable AI workloads**.
A new one-tick30s diagnostic reaches51.566FPS, p9523.887ms/p9928.753ms, but uses
sv_cheats1 solely to set the protected cadence cvar; normal production hosting,
full gameplay coverage and frozen listen-host acceptance remain unverified.

Capture support now records authoritative server topology/human count, tick/time
scale, NextBot cadence/budget and cheat/AI/transport settings; client capture also
records multicore, threaded bones and socket-loopback mode. Five targeted suites
and changed-file syntax pass. This is source-validated diagnostic support, not a
performance gain. Next: install the exact clean checkpoint, verify native metadata
readback, then investigate a cadence-preserving production candidate without
quietly slowing AI. Keep required workloads/thresholds fixed. Hosting and actual
four-player session questions remain pending; independent preparation continues.

# Previous checkpoint — focused Deck comparison; target unmet

The floor candidate48740b24 improved mean FPS5.70% in three matched30-second
stationary Deck diagnostics: baseline21.68–21.81FPS, candidate22.67–23.13FPS.
Separate profiles agree on lower floor-rendering cost. Native walls, normal
population, graphics and collision remain. The first normal17-node route and
red-card pickup completed; later visibility/cleanup coverage is still required.
The distinct multicore1 diagnostic reached26.77FPS and was restored to0.
A second candidate now removes known invisible collision boxes from the client
render queue after alternating prototype measurements improved about4%; focused
regressions and923-file syntax pass; installed collision, full-update recovery
and the normal red-card route were observed. A source-only repeat comparison is
still pending. Separate stable-Proton10/threaded-rendering diagnostics reach
33.28–33.61FPS in three fresh stationary repeats, still failing the frame budget.
Native CPU samples and bounded query timing point to remaining main-thread Lua /
simulation cost; GPU telemetry does not establish saturation. The static-wall
native Think experiment produced no measurable benefit and was rejected.
The separate native Linux64 investigation found and isolated a compiler code
allocation loop; a bounded allocator setting removed it, but native still reaches
only31.24–31.40FPS. Larger compiler caches/traces gave no measurable gain. Restore
the faster Proton10 condition: fresh fullscreen1280×800 controls reach32.68–32.93FPS.
The next focused candidate rejects ordinary NPC kinds before redundant native
lookups in the Player-only human-Soldier provider. Soldier/AI/status regressions
pass; source fingerprint coverage is expanded. Fresh installed repeats reach33.21–33.49FPS with reduced sampled query cost,
but later32.06FPS controls show session variation larger than the small gain.
A subsequent fresh alternating candidate/old/old/candidate/candidate/old
comparison confirms33.098 versus32.416FPS mean (+2.104%), disjoint FPS ranges.
Retain the guarded provider; tail latency still fails and is not consistently
improved. These short mechanism comparisons are not acceptance scenarios.
Slab batching, native mesh submission, engine fullscreen and compiler-cache
reset prototypes gave no useful gain and were restored; no such prototype ships.
A separate same-Deck nativeLinux32 dedicated server with publicWin64/P10 client
reaches53.29–54.23FPS in four30s stationary diagnostics, p9521.54–22.55ms and
p9926.52–26.89ms. This changes hosting/server VM together and does NOT satisfy
the frozen listen-host or full gameplay gates. Windows beta64/P10 was slower
(31.63–31.83FPS) and public is restored. PublicWindows32/P10 listen host was slower (29.60–29.77FPS); restored public64.
Bounded MotionV2/entry/animation profiling identifies repeated server Lua updates.
Native movement suppression and allocation-free entry sweep prototypes gave no
useful gain and were restored. A longer normal-input first-sector diagnostic reached83.95 active seconds before
normal death:27.11FPS, p9571.04ms, p99115.30ms. It fails duration and performance
and remains partial coverage. A separate combat profile confirms continued entry/close-defense/native behavior
cost and combat-feed drawing; normal death leaves only16.4 active seconds, so it
is diagnostic only. No further source shortcut was retained. Resume the measured
loop after the pending hosting decision; arrange three additional real clients
for the required multiplayer gate. Exact failure/profile/controller receipts are
in the iteration record. Temporary controllers are removed and processes stopped
while awaiting that information. Same-Deck dedicated hosting is a pending
explicit criterion decision. The public server currently has zero actual players,
so four-player native coverage remains unavailable.
The independent follow-up rejected native-validity and collector-pause probes.
It also corrected a restart setting mismatch: df106dc1's combat profile and the
first31a09219 control used multicore0, while all earlier source comparisons and
unprofiled gameplay used1. Optional checked-in benchmark settings and a validated
post-map launch order preserve1 on restart; a preflight rejects mismatches.
The complete31a09219 matrix is325/334, all nine failure anchors matching parent;
no additional production Lua change is retained. Exact receipts are in the record.
Full40FPS acceptance remains **unmet/unverified**. See the
[iteration record](validation/STEAM_DECK_20261021_ITERATIONS.md) for raw locations,
focus/environment corrections, regressions and interpretation. Next: isolate
remaining simulation/rendering cost, finish frozen gameplay checkpoints, and
continue equivalent measurements. All required scenarios, three warm repeats
and capped verification remain open; no completed40FPS claim is authorized by
these stationary results.

# Previous checkpoint — Steam Deck baseline access and pacing evidence

The October21 optimization request requires measured native Steam Deck≥40FPS
and verified publication, including three warm uncapped repeats per required
scenario and separate40FPS-cap verification. This target remains **unverified**.
Canonical source base1335a3c8b16c5ff0cbf00f1baebdb8b8aeb7fd20 has no fresh
native baseline. The missing local checkout, denied sandbox escalation and
inaccessible GPU prevent installing and measuring its complete build here.

Ordered bounded frame evidence, 1%low/time-below40/continuous-drop summaries,
terminal-gap evidence and conservative offline analysis are source-validated.
The [benchmark protocol](STEAM_DECK_BENCHMARK.md) fixes settings, workloads,
thresholds and repeat requirements; physical routes/checkpoints still require
the first native baseline before performance edits. The [preparation record](validation/STEAM_DECK_20261021_PREPARATION.md)
separates this diagnostic publication from the unfinished optimization task.
Next: restore authorized host execution/full checkout, capture the current-build
baseline and profiler overhead, then repeat measured optimization/regression
cycles. Preserve all prior gameplay, visibility, sound and multiplayer gates.

# Previous checkpoint — consultant-guided low-end optimization

User authorizes selectively adopting useful consulting advice. Preserve native
progression props and cargo rendering. Implement bounded/time-sliced cargo reuse,
frame-wide pushback cosmetic limits, reusable reentrant trace predicates,
bounded native modular-boss keyframes with legacy rollback, idle audio hook
retirement, and repaired performance-source fixtures/coverage. Exact scoped
static gate and native limitations: [evidence](validation/CONSULT_OPTIMIZATION_20261014.md).

Next: fully quit/update/install main, restart gm_flatgrass, run `lod_perf_start 180`
and play through combat/map/gates/boss/transition. Return console_latest.txt and
performance_client_latest.txt. ≥40 FPS and native appearance/bandwidth remain
unaccepted; no Workshop/VPS operation. The feat-repeat/Neil-console and physical
map/key visibility gates below remain regression constraints.

# Previous checkpoint — ordinary feat repeat guard and stock Neil console

On main d8ca361, human/automatic commits now enforce current eligibility and
highest replacement ranks. Invalid next-hand cards repair deterministically;
saved duplicate nonrepeatable selections restore later unresolved choices, with
legitimate fallback repeats retained. Neil's release uses a floor-seated stock
HL2 console and red angled stock button, plus the portal's existing large aimed,
rebound-key-aware prompt. Existing release/protection/quiet-feed rules remain.

19 selected checks and full Lua syntax pass on unchanged source. Initial legacy
fixture failure is retained; native appearance/Use/co-op and saved-state repair
remain pending. See [evidence](validation/FEAT_REPEAT_NEIL_CONSOLE_20261013.md).
Next: fully quit/update/install main, restart gm_flatgrass, verify recovery
choices, then aim at the post-Yellow console and press E to release Neil. No
Workshop/VPS operation or routine GDD edit.

# Previous checkpoint — Neil release button and quieter logger

Author's three corrections on main `4d14c2b140b9845a0d46c53957dc0695830e3744`.
Yellow now directs the party to a reachable stock-prop E release button before
the unique Neil/Brute hunt can spawn. Exact ownership, shared receipt, retries,
reserved access and a low inset pedestal retain progression and clear spawn
centers. Sanctuary visuals retire; bilateral protection remains with combat
nullification notes. The lower-right tail admits combat only; full menu/L history
retains all canonical records, cues, order and bounded persistence.

23 selected checks passed on frozen source before the final map-style prop inset;
5 final prop/hunt/full-build/installer/syntax checks pass on unchanged final source.
110 installer / 106 server / 48 client source identities are covered. Google
rejected the scoped GDD mirror; the author's correction governs and proposals/
failure receipts remain. See [evidence](validation/NEIL_RELEASE_LOGGER_20261013.md).

Next native action: fully quit/update/install main, restart gm_flatgrass, open
Yellow and press its release button; confirm one hunt, invisible sanctuary note,
combat-only tail and full L/menu history. Native physical Use/collision/co-op and
Steam Deck ≥40 FPS remain unaccepted. No Workshop/VPS operation.

# Previous checkpoint — legal cross-floor routes and stock progression pickups

Author's Dungeon-1 NO LEGAL ROUTE screenshot and all-angle stock-prop correction,
based on main `3893adc3d3f262d9c10548823d24edabd19119f9`. The client searched only
collected floors for an objective on an unfound floor. Existing bounded Compass
transport now supplies an ordinary found-floor map from the complete canonical
server graph, with native stair guidance and stale-state guards. Unfound topology
stays private; live locks, party discovery and personal Magic remain.

All four keycards and Jail Key now have native stock bodies on owned low stock
pedestals. The map shares their seating/render authority. Model pivots cannot
move touch anchors; Black-card and boss receipt checks agree. Custom body drawing
and distance culls retire. Required-prop failure is rejected before activation.

23 checks pass with unchanged source: 576 objective routes / 48 layouts, 12 real
full SQLite builds / 35 protected map paths, signed-floor prop seating / 2160
native DrawModel calls and retained map/navigation/key-receipt regressions.
Identity coverage: 101 installer / 97 server / 42 client. Parent cross-floor
failure is reproduced and preserved. See [evidence and limits](validation/PROGRESSION_ROUTING_STOCK_PROPS_20261013.md).

Next native action: fully quit/update/install main and restart gm_flatgrass;
follow the ordinary map to the red gate on another floor, then orbit and collect
map/cards/key near/far and above/below. Native rendering/contact/jumping/co-op and
Steam Deck ≥40 FPS remain open. No Workshop/VPS operation or routine GDD edit.
This finite source gate is not complete-matrix or native acceptance.

# Previous checkpoint — stock physical floor-map props

Author's continued native invisibility report and physical-prop request, based on
main `a2ab35a46a976dc6b198b2c55b06f34dbca1cd95`.
Source candidate `d53c3756571429a6d09d3392ed9ff753dda1a66a` replaces the custom globe body with an upright
stock binder and separate solid stock block. Native dimensions/rendering, complete
bounds and a low pedestal clear of the cell's arrival center address visibility
and collision; the current map cell and closed-door entry plan remain. Both
entities and Map Finder helpers retire with the shared pickup owner. Party maps,
cue/notice, personal map Magic and navigation feats remain.

17 selected CI checks pass on the exact candidate in Actions run 38450969612,
including actual prop/rendering boundaries, pickup/Compass, real SQLite builds,
source identity and changed production syntax. Coverage is 94 installed /
90 server / 38 client. The unavailable local executor and inherited full-matrix
failures are explicit; native GMod appearance/collision/co-op and Steam Deck
≥40 FPS remain unaccepted. The scoped GDD mirror again failed; proposed text and
receipt are preserved. Evidence:
[stock-map repair](validation/FLOOR_MAP_STOCK_PROPS_20261013.md).
Next native action: fully quit/update/install and restart gm_flatgrass; approach
and circle the book/gold block, then touch it and confirm the shared floor unlock.
No Workshop/VPS operation.

# Previous checkpoint — map/navigation feats and relentlessly proud GPS

Author additions on `4cd2232a99d3a996f67d0ba7b47df4eb5cc03ec2`, integrated with
the Jail Key/Hermit repair on parent `95597c0c0352d40ee428410e634fcc03e62b2809`.
Internal Compass (WIS 15) retains the ordinary bounded objective breadcrumb on
an unfound floor's open Magic panel, with walls hidden. Map Finder (WIS 13)
passively shows actual uncollected map globes through walls and ceilings in world
view, including other floors. GPS remains WIS 17/G/no Magic, corrects moving
wrong-way travel on its 0.20-second update and cycles sixteen eight-writer praise
lines with a 0.25-second post-phrase pause. Existing idle/lifecycle rules remain.
All three reuse ordinary ownership, route and presentation authorities; a proven
cached jail/arena traversal bypass is repaired at the shared navigator.

41 selected checks pass against 59 frozen changed files and the pinned parent;
catalog/Manual now include 114 ordinary feats and source coverage is 91 installed /
87 server / 36 client. Initial fixture failure and incomplete accidental broad
run are retained. Evidence and limits:
[navigation additions](validation/NAVIGATION_FEATS_20261013.md).
Google rejected the narrow live author-rule mirror; exact proposals/failure are
preserved and the author's explicit corrections govern. Next native action:
fully quit/update/install and restart gm_flatgrass; with the feats owned, verify
unfound-floor trail/Magic, globe visibility through walls/ceilings, GPS repeated
praise and immediate reverse correction, then G cancellation. Native/co-op/audio
and the outstanding Steam Deck ≥40 FPS acceptance remain pending. No Workshop/VPS
operation.

# Previous checkpoint — conspicuous Jail Key and native Hermit portrait API

Author's key-visibility/pedestal request and native nil-method report, based on
main `4cd2232a99d3a996f67d0ba7b47df4eb5cc03ec2`. The Jail Key now has complete
bounds, an upright viewer-facing display and a real 40×40×28-unit jumpable plinth.
Gold/ivory against deep blue-violet and dark trim provide contrast; wall depth,
original pickup/receipt/progression and same-entity lifecycle remain. Hermit
portrait animation writes the base_anim property without calling a method absent
on ClientsideModel. Cached unarmed roles and the prior map clarification remain.

35 distinct focused checks pass (36 executions), including 640 key views, the
real portrait path, 905-file Lua syntax, boss/receipt, floor-map/SQLite, lifecycle
and exact 81 installed / 77 server / 31 client source coverage. The old errors
and fixture failures are retained. The broader run is incomplete, with inherited
fixture failures and campaign timeouts, not a full-matrix pass. Google rejected
the scoped live GDD amendment and pointer; the author's request governs and
proposed text/failure receipts are retained. Evidence and limits:
[key/idle repair](validation/KEY_VISIBILITY_IDLE_20261013.md).
Next native action: fully quit/update/install, restart gm_flatgrass, open Hermit
dialogue without an error, then after the boss orbit the visible key, jump onto/
over its pedestal and collect. Native visual/jump/co-op and Steam Deck ≥40 FPS
acceptance remain pending. No Workshop/VPS operation.

# Previous checkpoint — blank Magic map panel and collected-floor bootstrap

Author's clarification/native report, based on published main
`df567c8dd970296314771d268a337196c5552c43`. Q/M/VR now open the existing panel
on an unfound floor and show the reminder inside it while personal Magic drain
and map-up effects continue. Layout discovery remains shared per physical floor.
Panel metadata no longer depends on knowing the resolved origin first; pickups
push the new discovered subset, so collecting a map reveals an already-open panel.
Hermit and generated Manual explain the clarified rule. All prior globe, prompt,
party ownership, placement and pickup presentation remain.

31 finite checks pass, including real pickup→party mirrors→two-realm transport→
HUD→Magic/movement, both origin signs and packet-before-NW2 ordering. Two parent
failures are retained. Evidence and limits:
[map-panel correction](validation/FLOOR_MAP_PANEL_20261013.md). Source coverage
is 78 installed / 74 server / 29 client. Google rejected the narrow live GDD
correction; the author's explicit instruction governs, with the failure recorded.
Next native action: fully quit/update/install and restart gm_flatgrass; open Q
before discovery, see the reminder and Magic drain/effects, touch the globe while
open and observe its layout, then enter an unfound floor and close with M.
Native/co-op acceptance and Steam Deck >=40 FPS remain pending. No Workshop/VPS
operation.

# Previous checkpoint — floor-map access/visibility repair and Hermit prompt

Author's native report and prompt request, based on published main
`47f4e74e4790155b149de323d956ca155585b622`. Removed the developer-mode exceptions
that made every floor available in installed development builds. Q/M/VR on an
unfound floor closes/denies with “Map not found — find this floor's map”; server
transport, party mirrors and real personal Magic admission follow discovery.
Paper is now a cached floating globe with a viewer-facing eye and complete bounds.
The existing large staging prompt also covers the Hermit, rebound Use and reveal.
Shared touch ownership, entrance paths, ditty/notice and tutorial remain.

24 finite checks pass, with three parent failures retained. Exact source/evidence
and native limits: [floor-map repair](validation/FLOOR_MAP_REPAIR_20261012.md).
Coverage is 76 installed / 72 server / 28 client sources. All current-turn live GDD
writes failed; prior 00/01 amendment remains and subsystem mirrors are incomplete.
Next native action: fully quit/update/install, restart gm_flatgrass, observe the
Hermit prompt, Q denial before pickup, globe/eye from different sides, shared
pickup and Magic cost, then denial on the next unfound floor in developer mode.
Native visual/co-op acceptance and the previous Steam Deck >=40 FPS gate remain
pending. No Workshop/VPS operation.

# Previous checkpoint — shared collectible floor maps

Author-requested map correction on main `297ed8c3bae1771b9eb2310e77a101d5f4daf0db`.
Exactly one party-owned pickup per physical floor replaces automatic access;
no inventory item. Placement is within six closed-door graph steps of the first
arrival, with an event-protected path. Q/M/VR show only found floors; transport,
both decoders, build caches, personal Magic and lifecycle enforce that rule.
Pickup uses the keycard ditty and a large four-second three-line notice; Hermit
and generated Manual explain finding/sharing/Magic. Cash floors are included.

21 selected checks pass, including 48 layouts / 146 floor paths and 12 full
28-event/SQLite builds / 35 paths. Source coverage: 76 installed / 72 server /
27 client. Live GDD 00/01 records the amendment and readback; Google rejected
05/06/07/HUMAN edits, so those mirrors remain incomplete. Evidence, failure
receipts and exact limits: [floor maps](validation/FLOOR_MAPS_20261012.md).
Next native action: fully quit/update/install main, restart gm_flatgrass, hear
the tutorial, deploy, verify Q denial before pickup, then touch the entrance-area
map and observe the ditty/notice, shared floor access and personal Magic drain.
Native map/co-op appearance and the previous Steam Deck >=40 FPS gate remain
pending. No Workshop/VPS operation.

# Previous checkpoint — living unarmed friendly NPCs

Author-requested animation interjection, based on published main
`b839ee68e37850ab05764358e0fb903c8260e4dd`. The eight-role writers' room supplied
three paired advisory passes; Quinn/Ned assembly keeps restrained, distinct
mannerisms. Live GDD 00/01 now routes 05 LOD-NPC-IDLE-001 and 07
LOD-NPC-IDLE-TUNING-001, with a compact HUMAN mirror; design/readback preceded
game changes and preserved existing text.

Hermit, Game Master, Wounded Scavenger and Prison Surveyor now use same-faced
stock animated player-model variants with explicitly unarmed, draw-driven idles.
Client-only cached bones/flexes add role-specific gestures, nods, smiles and
independent blinks; the Hermit portrait matches. No added actors, server animation
loop, RNG stream or service change. Rescued women, sole Deborah succession,
statue and giant Hector projection remain. Source verification covers the eight
NPC authorities at existing cadence: 66 installed / 62 observed / 23 client.

Fifteen relevant regressions and four syntax/shell/whitespace checks pass;
17 changed/new Lua files parse. Fixture failures remain archived. Evidence and
limits: [friendly idle checkpoint](validation/FRIENDLY_NPC_IDLE_20261012.md).
Next native action: fully quit/update/install main, restart gm_flatgrass and
approach the Hermit, then press E. Observe living idle/empty hands and matching
portrait; later service-event observations cover all three roles and spent-quiz
hiding. Native appearance and the previous stationary Steam Deck comparison /
sustained ≥40FPS remain pending. No Workshop/VPS operation.

# Previous checkpoint — twenty-chapter staging story

Author-requested lore interjection, based on published main
`f7353f2fd4fdb85794a39845c518446e1473c5e3`. The live GDD was updated and verified
before game edits: 00/01 route 05 LOD-LORE-001 (eight-role writers' room, full
character/relationship bible, exact script), 06 LOD-LORE-UI-001 and 07
LOD-LORE-GATE-001. All previous GDD text was preserved; HUMAN mirrors the story
packet and05 includes the relationship diagram.

Source now implements optional E dialogue at the existing guide, a distinct
chapter for each Dungeon1–20, the authoritative revealed-Hector override, all
nineteen ordinary damsels' three-variant conversations, and Deborah's two Cash
epilogues. Actual reward parameters/cadences and settlement remain unchanged.
Long text and the separate service receipt scroll; campaign epoch, death,
deployment, dungeon and guide replacement retire the window. Manual content
agrees. Eighteen selected checks pass, including sixteen Lua parses and relevant
progression/succession/finale/timer regressions. Evidence and limits:
[staging story checkpoint](validation/STAGING_LORE_20261012.md).

Next native action: fully quit GMod, pull/install main, restart gm_flatgrass and
approach the Hermit with E. Check the Level1 instructions and scrolling, then the
new Level2 conversation on the next staging visit. Later native gates cover
all women, already-claimed services, independent players and the existing
Hector→Deborah finale. The previous stationary Steam Deck comparison and final
sustained≥40FPS target remain pending. No Workshop/VPS operation.

# Previous checkpoint — verified moving-view Steam Deck capture

The October 10 18:20:52 upload verifies clean published build
`db51ecc024472b6b273af7f55cece5bc7b843c63`: all 54 recorded module hashes agree
with mounted/installed/published/local source; 19 client sources report verified.
Both 60-second phases finish, with complete 270-row client/369-row server profiles
and final server transport, fixed preferences, idle VR and zero Lua errors.
Active FPS is 24.7637 unprofiled / 34.4209 profiled; sustained ≥40 FPS remains
unmet. This is a native below-target observation, not optimization attribution.

The pair was played while moving/fighting: endpoint displacements 2,567/2,968
Source units and changed yaw/pitch, living-body mirrors 36→29, two cleared
contacts and menu/nonactive gaps. Same generated campaign/layout, 1,476 native
walls, 36 initial wanderers. Its FPS difference cannot measure profiler overhead.
The diagnostic command and final report transport are runtime observed; a
controlled stationary comparison is still missing. Existing rendering and AI
caches were inspected; do not add speculative broader caches or change accepted
graphics/population to compensate for this uncontrolled comparison.

This checkpoint banks the raw native evidence, reproducible verifier and current
sequencing only. Live GDD 00 → 01 → 05/07 was read without edits. All 2,010 tracked
game/Lua/tool files remain byte-identical; archive integrity, verifier parsing,
fresh capture verification and whitespace pass. Preserve prior completed static
gates without rerunning them. See
[native pair evidence and replay](validation/STEAM_DECK_20261010_PROFILE_PAIR_NATIVE.md).

Next native action: reuse the exact verified installed build; no game update is
needed for this documentation-only checkpoint. On gm_flatgrass, deploy once,
then remain inside the arrival sanctuary facing the maze. Run
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_compare 60`.
Close the console and do not move, aim, attack or open menus through both phases
(about two minutes plus warmups). Keep GMod open through the final server reply;
return performance_client_latest.txt + console_latest.txt. Verify source,
identical view/settings, workload, complete profiles, idle VR and errors before
timing attribution. Native controls and unchanged appearance/gameplay still need
observations; sustained traversal/combat ≥40 FPS remains the final gate. No
Workshop or VPS operation.

# Previous checkpoint — recurring Favored Enemy identity pool

User-authorized balance interjection before the pending Steam Deck test; published parent main `b1e604b5d380492ff55de1c2c12eb22df911fa4c`. Fresh live GDD 00 → 01 → 04/05/07 governs the seam; 04 LOD-ID-002 records the requested future-pool restriction and exact readback is preserved.

Future Favored Enemy identity rolls use only model families enrolled by ordinary nonobjective dungeon encounters or the existing autonomous wandering roster. The Nodule/Barnacle family is excluded entirely, including its Lurker alias. Boss-only, boss-companion-only and other unique models no longer enter through registration. The resulting pool has 14 recurring families; saved v2 and legacy v1 perks retain their exact mechanics without rerolling. Combat, populations, appearance and graphics preferences are preserved. The canonical manual agrees. Existing source verification adds the selector: 58 installed / 54 population / 19 client capture modules.

11/11 bounded checks pass on unchanged snapshot `fa24b5472b931339bf77edc42dea1df956c383f1e84c79f0791c87f74f8154ff` (2,590 files): seven selected canonical suites, published-parent rejection, all 10 changed/new Lua parses, installer shell syntax and whitespace. Evidence, raw receipts, preserved fixture failure and replay: [Favored Enemy checkpoint](validation/FAVORED_ENEMY_20261010.md). Do not repeat prior completed full gates absent new changes or contradictory evidence.

Next native action remains fully quit/update/install main, restart gm_flatgrass, briefly confirm the equipment/per-button Magic controls below, then the same-scene `lod_perf_compare 60` procedure. New characters draw from the filtered pool; existing characters retain saved perks. Return performance_client_latest.txt + console_latest.txt and any control/appearance observations. Native controls and sustained ≥40 FPS acceptance remain open. No Workshop or VPS operation.

# Previous checkpoint — equipment and Magic selector controls

User-authorized QoL interjection before the pending Steam Deck test; published parent main `e1e634e04e82a06bf1873195607a06f47a825e9c`. Live GDD 00 → 01 → 03/06/07/90 was read; 03 selection and 06 LOD-UI-008 now record the requested controls and were read back.

Double-click item tiles to equip in the ordinary compatible slot or stow/unequip through existing server requests. Explicit hand placement, inspection and drag/drop remain. Content now uses Form selector gestures: LMB/RMB for RMB; M3/M4/M5 for that button. Each casts its own Form plus independently owned Content/RAW. Legacy characters migrate their former shared Content to all four buttons. Normal ownership, progression, spend, cooldown, status, rider, equipment, ammunition and lifecycle authorities remain. Spellbook costs/labels and the canonical manual agree. Source verification expands to 57 installed / 53 population / 19 client capture modules at existing cadence.

17/17 bounded checks pass on unchanged source `8adaba9efc66c523446952ff5e4c18373cb338a149929be9b35efd25c645f068` (2586 files): 14 selected canonical suites, all 17 changed Lua parses, shell syntax and whitespace. Production/tool hashes are rechecked after documentation packaging. Preserve previous completed full performance gates. Evidence and replay receipts: [controls checkpoint](validation/INVENTORY_CONTROLS_20261010.md).

Next native action: fully quit/update/install main, restart gm_flatgrass and briefly confirm double-click equipment plus two different button-specific Form/Content casts (including RAW independence). Then run the unchanged same-scene `lod_perf_compare 60` command below from the arrival sanctuary, staying still through both phases/final server reply. Return performance_client_latest.txt + console_latest.txt and any control/appearance observations. Native controls and ≥40 FPS acceptance remain open. No Workshop or VPS operation.

# Previous Steam Deck checkpoint — same-scene profile diagnostic

Verified clean published main `3d3c05ce8c4aedf498ecfbb698548a087bbfe16a`.
The October 9 18:40:50 capture independently matches all 49 recorded source
hashes and reports 17 verified client sources, complete 273-row client/376-row
server profiles, fixed preferences, fully idle VR and zero Lua errors.
Active FPS is 19.5371, median 42.486 ms, p95 86.115 ms; all 36 windows fail 40 FPS.
The scene has 1,792 native walls and 60 initial living wanderers, versus 1,434/36
previously. Different generated scenes prevent attributing FPS to the aura cache.
Native performance remains below target; no isolated regression is established.

Profiled geometry and shared admission/close-defense checks remain costly.
Inclusive rows overlap, include instrumentation overhead and do not measure GPU
cost. No unprofiled capture of this build is available. Before a broader source
optimization, add a bounded paired diagnostic through the existing observer:
`lod_perf_compare 60` runs unprofiled then profiled in the same live scene with
separate warmups, and retains both complete raw reports in the existing file.
The baseline is frozen before phase two; camera scalars are copied at the first,
last and five-second samples. Existing source/settings/population/resource
checks and final server transport remain. No gameplay, appearance, population,
preference or tuning changes. Fresh live GDD 00 -> 01 -> 05/07 governs this seam.
Source coverage remains 53 installed / 49 population / 17 client capture modules.

7/7 selected checks pass on the final unchanged 2,582-file snapshot; three
changed Lua files parse. All 14 raw streams and receipts are independently
verified. The actual paired fixture retains both samples through final transport
and covers frozen data, views, interruptions, active-profile shutdown/cleanup/
refresh, stale callbacks/replies, restart, codec/save failures and idle bounds.
The unchanged parent is rejected by the new diagnostic-presence gate. Preserve
all earlier completed work/full-matrix evidence without another rerun. Only
documentation/evidence packaging follows, with production/tool hashes rechecked
before immediate non-force publication. See
[finite diagnostic gate and raw evidence](validation/STEAM_DECK_20261009_PROFILE_PAIR.md).

Next native action: fully quit/update/install main, restart gm_flatgrass, remain
in the arrival sanctuary facing into the maze, and run
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_compare 60`.
Close the console and stay still with the same view through both phases. Leave
GMod open through the second completion/final server reply; return
performance_client_latest.txt + console_latest.txt. Inspect both exact source,
configuration, view, workload, profiles, idle VR and error evidence before timing
attribution. This fixed-order stationary diagnostic does not certify sustained
combat/traversal FPS; actors and clocks continue. New command execution remains
native-unverified. The final acceptance gate still requires unchanged
appearance/gameplay and sustained >=40 FPS. No Workshop or VPS operation.

# Previous checkpoint — reduced-effects hostile aura orbit

Verified published parent main `7853634ae455a213b84cbe04e10b2435d3130b89` and
clean checkout. The fresh October 9 18:11:37 UTC native capture verifies that
exact install and all 48 recorded mounted source hashes: 28.0046 active FPS,
median 31.784 ms, p95 58.836 ms, 1,434 native walls and 36 initial living
wanderers. All 36 five-second windows fall below 40 FPS. Complete profiles,
fixed preferences, fully idle VR and zero client/server Lua errors pass.
Different generated scenes prevent isolated FPS attribution; >=40 FPS remains
unmet. Inclusive hostile Draw averages 0.113480 ms over 47,059 calls; timings
overlap, include diagnostic overhead and do not measure GPU cost.

Extend the existing monster aura presentation with exact reduced-effects orbit
offset reuse per actor/radius. Preserve every native input read, color/vector
allocation and sprite, full-effects animation, current preferences, statuses,
helper replacement/between-sprite callbacks, nested draws, NaN/retry, refresh
and weak retirement. No appearance, model, gameplay, population or tuning
change. Fresh live GDD 00 -> 01 -> 05/07 governs this implementation-only seam.
Existing source verification expands to 53 installed hashes, 49 population
modules and 17 client capture modules at its unchanged cadence.

Finite gate passes: published-parent/candidate 255,405-row native traces match
across 218 branch/boundary/callback/lifecycle cases and 13,920 moving-actor aura
draws. Trigonometric calls fall 55,680 -> 232; all 167,040 native input reads,
97,440 vectors, 13,920 colors and 27,840 sprites remain. The unchanged parent
fails only the new work bound. 11/11 selected checks pass on identical frozen
source; seven changed/new Lua files parse. Every successful raw stream/receipt
is independently hash-verified; failed fixture/setup attempts remain archived.
Do not rerun the preceding completed 317-check gate without new contrary
source/evidence. These are work counts, not native FPS certification. Only
documentation/evidence packaging follows, with production/tool hashes rechecked
before non-force publication. See
[finite gate and raw evidence](validation/STEAM_DECK_20261009_AURA_ORBIT.md).

Next native gate: fully quit GMod, pull/install verified main, restart gm_flatgrass
and use
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply; return performance_client_latest.txt
and console_latest.txt. Require exact source, unchanged appearance/gameplay,
complete profiles, idle VR, no new Lua errors and sustained >=40 FPS. Native FPS
for this candidate remains unmeasured. No Workshop or VPS operation.

# Previous checkpoint — hostile visual scale key reuse

Recovery verifies published main `b8b9cfd6c4efb711fa2d8fe18f15e1fc75681505`,
including the physical-footstep checkpoint. The latest available native capture
still precedes it: clean `0fe2df6`, 21.3329 active FPS, median 40.331 ms,
p95 75.604 ms, 1,604 native walls and 58 initial living wanderers. Complete
profiles, fixed preferences, idle VR and zero Lua errors are recorded. Hostile
Draw averages 0.097224 ms over 51,372 calls; inclusive timings overlap and do
not measure GPU cost. Different generated scenes prevent isolated FPS
attribution. Sustained >=40 FPS remains unmet.

Extend the existing hostile visual-scale key cache to reuse formatting when
all resolved inputs match exactly. Preserve current native getter and pose/recoil
callback work, original rounding and matrix decisions, signed zero, NaN/custom
fallbacks, formatter/converter replacement, full update, refresh and weak entity
retirement. No drawing, bounds, model, movement, gameplay, population, preference
or authored tuning change. Fresh live GDD 00 → 01 → 05/07 governs this
implementation-only checkpoint. The existing installer/source verification now
covers hostile cl_init.lua: 52 installed hashes, 48 population modules and 16
client capture modules, with the existing once-per-session hashing cadence.

Finite gate passed: published-parent/candidate native traces match across 942
branch/boundary/callback/lifecycle cases and 13,920 stable-body draws. Formatting
calls fall 13,920→58 while all 125,338 native input getters, 13,920 model
submissions and 58 matrix/bounds updates remain. The unchanged parent passes
behavior comparison and fails the new work bound. These are headless work
counts; no FPS gain is yet measured. All 317 canonical checks pass on the same
frozen 2,575-file source (66 corrected-run receipts plus 251 continuation
receipts); all commands and 634 raw streams are independently verified. All
887 Lua files parse. Failed partial and interrupted evidence is preserved.
Documentation/evidence packaging alone follows, with all frozen source/test
hashes rechecked before non-force main publication. See
[finite gate and evidence](validation/STEAM_DECK_20261009_HOSTILE_SCALE.md).

Next native gate: fully quit GMod, pull/install verified main, restart gm_flatgrass
and use
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply; return performance_client_latest.txt
and console_latest.txt. Require exact source, unchanged appearance/gameplay,
complete profiles, idle VR, no new Lua errors and sustained >=40 FPS. No Workshop
or VPS operation.

# Previous checkpoint — physical-footstep native field access

Recovery verifies clean remote main `0fe2df6ac8fcbecaf9fea712d6d43fdf83ad4508`;
all four CI workflows succeeded. The complete October 9 UTC native capture
verifies that exact install, 15 client sources, fixed preferences, fully idle VR
and zero Lua errors. Active play averages 21.3329 FPS, median 40.331 ms,
p95 75.604 ms and p99 121.233 ms. Its different generated scene contains 1,604
native wall models and 58 initial living wanderers; the preceding scene had
1,270 walls and 36 wanderers. This does not isolate the repeated-view change's
FPS effect. Sustained >=40 FPS remains unmet. The physical-footstep Think hook
averages 0.2561 ms over 11,940 calls; profiles include overhead and overlapping
inclusive timings, and do not measure GPU cost.

Extend EnemyVariance's existing physical-footstep hook to read owned values
from the native entity's current Lua table during adjacent comparisons. Keep
ordinary lookup for inherited/missing/legacy fields, native writes, validity,
every position/velocity poll and the exact distance arithmetic. Reacquire after
position/velocity/distance callbacks; retain no cross-tick table, scalar or
visibility cache. Preserve physical footfall timing, the 80-unit travel cap,
one independent stride RNG draw per completed step, all actor state/lifecycle,
population, graphics preferences, gameplay and approved Crate presentation.
Extend the existing installer/mounted-source manifest to include this module:
51 installed source hashes, 47 watched runtime modules. Keep source hashing at
the existing once-per-session cadence, outside the physical-footstep hook.
Fresh live GDD 00 → 01 → 05/07 governs this implementation-only checkpoint;
no authored tuning or design change is needed.

Finite gate passed: actual published-parent/candidate state, native-write,
movement and RNG traces match exactly across 159 boundary/fallback/callback/lifecycle
scenarios and 13,920 representative hostile ticks. Entity lookups, native table
queries and native type queries fall 143,376→100,572, counting every added query. All 32,016
native writes, 13,920 position/velocity polls and 1,044 RNG draws remain. The
unchanged parent fails the new work bound. The final frozen gate passes 316/316
canonical suites and 886 Lua parses on an unchanged 2,572-file snapshot; all
commands, individual receipts and 632 raw streams are independently checked.
Earlier interrupted evidence and two incomplete source-count fixtures' seven
dependent failures are retained; the repaired fixtures pass those seven checks
before the final complete pass. Documentation/evidence packaging alone follows;
all eight changed source/test hashes are rechecked before non-force publication.
See [finite gate and native evidence](validation/STEAM_DECK_20261009_PHYSICAL_STRIDE.md).
These are headless work counts; the new build's Steam Deck FPS remains unmeasured.

Next native gate: fully quit GMod, pull/install verified main, restart gm_flatgrass
and use
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply; return performance_client_latest.txt
and console_latest.txt. Require exact source, unchanged world appearance/gameplay,
complete profiles, idle VR, no new Lua errors and sustained >=40 FPS. No Workshop
or VPS operation.

# Previous checkpoint — exact repeated-view frustum reuse

Recovery verified clean remote main `8868d20629ddd89e4503b2fafc036e5766402d1e`
and the newest exact-source three-minute capture: 30.3866 active FPS, median
30.271 ms, p95 50.162 ms and p99 84.058 ms. The scene has 1,270 native wall
models and 36 initial living wanderers. Complete client/server profiles, fixed
preferences, idle VR and zero Lua errors are recorded. Different generated
workloads prevent isolated attribution; sustained >=40 FPS remains unmet.

Extend the existing generated-box snapshot to reuse the pure frustum result
only for the exact same current eye scalars and immutable view coefficient
identity. Every pass still reads current native bounds/pose, camera axes and
projection. Changed geometry replaces the snapshot; any camera/projection
change invalidates reuse. Preserve every native draw, overlay, hazard/grate,
fallback, resource/lifecycle, model, collision and gameplay. No frame lease,
rounded key, population/timing/tuning/preference change or experimental batching.
This new checkpoint supersedes the preceding checkpoint's narrower prohibition
on visibility caching only for exact repeated inputs. Fresh live GDD navigation
00 → 01 → 05/07 governs implementation; no authored design change is needed.

Finite gate passed: exact published-parent/candidate native mesh/wireframe/fallback
traces match across 330 scenarios, including exact boundary/projection and
live basis-override cases. In 120 moving-camera frames with two identical-view
submissions, actual production frustum evaluations fall 28,800→14,400 while
all 115,200 native geometry getters, 2,160 camera-basis component reads,
28,800 mesh draws and 9,600 wireframes remain. The published parent must fail
the new work bound. Preserve all existing renderer/culling/lifecycle assertions;
29 focused checks and 885 Lua syntax files pass. All 315 canonical suites have
passing coverage on the same frozen 2,569-file source. The initial full run
passed 312/315; three existing campaign tests exceeded its shorter 120-second
timeout. Their unchanged commands pass with the canonical 600-second limit;
both attempts are retained, with 636 raw streams, all commands/receipts and
29 focused logs independently checked. Only documentation/evidence packaging
follows; production/test hashes are rechecked before non-force publication.
Counts are headless work evidence, not native FPS certification. See
[finite gate and native evidence](validation/STEAM_DECK_20261008_EXACT_VIEW.md).

Next native gate: fully quit GMod, pull/install verified main, restart
gm_flatgrass and use
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply; return performance_client_latest.txt
and console_latest.txt. Require exact source, unchanged world appearance/gameplay,
complete profiles, idle VR, no new Lua errors and sustained >=40 FPS. No Workshop
or VPS operation.

# Previous checkpoint — exact plane-support reuse

The October 8 UTC / local native capture verifies clean main `30d180f`, all
15 client and 46 population source hashes, complete 180-second profiles,
fully idle VR, fixed preferences and zero Lua errors. Active play averages
26.7192 FPS, median 32.779 ms, p95 63.844 ms and p99 108.667 ms. The new scene
has 1,338 native walls and initially 40 bodies / 36 living wanderers, versus
1,284 walls / 36 bodies in the preceding capture; FPS changes do not isolate
the aligned-HUD source change. Portrait paint averages 0.8287 ms versus 0.9406
previously, also without isolated attribution. Sustained >=40 FPS remains unmet.
Console entry evidence now records admission denials and a deployed Hero;
it still does not establish every sanctuary branch's native acceptance.
Generated static geometry averages 1.8892 ms per recorded hook invocation
(100.3602 CPU ms per recorded second); timings are inclusive, overlapping,
include profiler overhead and do not measure GPU time or flag-specific work.

Reuse only direction-dependent frustum planes and box support scalars in the
existing generated-geometry snapshot. Read the actual view axes/projection,
eye position and every box's native bounds/pose on every pass. Exact basis,
projection or box snapshot changes invalidate the relevant arithmetic; never
cache visibility, round view keys, impose a lease, skip submissions, change
culling planes/tolerance, hide native walls or promote experimental batching.
Immutable coefficient sets preserve nested-camera ownership. Retain all
meshes, UVs, colors, wireframes, fallback, collision, models, graphics preferences,
population and gameplay. Fresh live GDD 00 → 01 → 05/07 governs this
implementation-only checkpoint; no authored tuning/design change.

Finite gate: published-parent/candidate native mesh/wireframe/fallback traces
must match over 300 render passes covering translating cameras, all view axes,
FOV/aspect, mutable/replaced bounds and pose, live accessor overrides, hazards,
grates, kind/life, full update/transmission, incomplete/nested views, refresh
and removal. In 240 warmed passes with 120 boxes (30 rotated), repeated
support/plane absolute-value operations fall 111,600→0. All 115,200 native
geometry getters, 2,160 camera-basis component reads, 28,800 mesh draws and
9,600 wireframes remain. The exact parent must fail the new work bound.
These are headless operation counts, not native elapsed-time/FPS savings.
Preserve the existing 173 visible-corner / 73 conservative-plane oracle cases
and accepted renderer/cache/resource regressions. The frozen source passes
29/29 focused checks, 314/314 canonical suites and 885 Lua parses. All 2,566
source files remain unchanged during both gates; every command/receipt, 628
matrix stream hashes and 29 focused log hashes are independently checked.
Earlier fixture failures remain preserved and unused. Only documentation/
evidence packaging follows; both changed code/test hashes are rechecked before
non-force main publication. See [finite gate and native evidence](validation/STEAM_DECK_20261008_PLANE_SUPPORT.md).

After validated publication, fully quit GMod, pull/install, restart gm_flatgrass
and use the usual fixed-preference three-minute capture:
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply; return performance_client_latest.txt
and console_latest.txt. Require exact final source, complete profiles, idle VR,
no new Lua errors, unchanged floors/stairs/grates/hazards, walls and overlays,
intact gameplay and sustained >=40 FPS. No Workshop or VPS action.

# Previous checkpoint — aligned HUD text work reuse

The October 8 UTC / local three-minute native capture labels clean main
`0a10367`, verifies all 15 client and 46 population source hashes, complete CPU
profiles, fully idle VR, fixed preferences and zero Lua errors. Active play
averages 29.6510 FPS, median 30.672 ms, p95 53.305 ms and p99 92.372 ms, with
1,284 native walls and 36 recorded living wanderers. The preceding capture had
1,614 walls and a different population/layout; this does not isolate the prior
optimization's FPS effect. Sustained >=40 FPS remains unmet. Entry evidence has
no recorded admission decisions, so it does not accept every sanctuary branch.
The shared portrait callback averages 0.9406 ms per paint; aligned captions use
the stock ten-selection/ten-measurement outlined text path.

Extend the existing shared HUDText native path to known horizontal/vertical
alignments. Measure live font dimensions once per label, retain stock offset →
alignment → ceil order, all nine outline glyphs plus foreground, exact colors
and original return behavior. Owned coordinate caches invalidate on current
alignment dimensions; no font metrics persist across paints. Custom text
conversion, unknown alignments and partial APIs keep stock fallback. The already
optimized left/top feed retains zero measurements and its existing span reuse.
No portrait model, pose/sample cadence, label/wrapping, lifecycle, gameplay,
population, geometry, graphics preference or authored tuning changes. Live GDD
00 → 01 → 06/07 governs this implementation-only checkpoint.

Finite gate: actual published-parent/candidate traces match across 750 drawing
scenarios, including all nine alignments, floating-point boundaries, live font
changes, coordinate ownership, custom conversion and fallback. Trace SHA256:
`0660a9b9d7ba938fb66785f5852227ae218a8ee9b9f7570c634672219a5ddcf6`.
Across 1,200 labels, font selections and measurements each fall 12,000→1,200,
outline Color allocations 1,200→0; all 12,000 draws and 24,000 ceil operations
remain. The exact parent fails the new aligned-work bound. Existing 42,000-draw
feed work stays unchanged. Portrait regressions now exercise actual shared
HUDText. These are headless work counts, not FPS savings. The frozen source
passes 20/20 focused checks, 314/314 canonical suites and 885 Lua parses. All
2,563 source files remain unchanged during both gates; every command/receipt,
628 matrix stream hashes and 20 focused log hashes are independently checked.
Only documentation/evidence packaging follows; all three changed code/test
hashes are rechecked before non-force main publication. See [finite gate and native evidence](validation/STEAM_DECK_20261008_ALIGNED_TEXT.md).

After validated publication, fully quit GMod, pull/install, restart gm_flatgrass
and use the usual fixed-preference three-minute capture:
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply; return performance_client_latest.txt
and console_latest.txt. Require exact final source, complete profiles, idle VR,
no new Lua errors, unchanged portrait/weapon/status/readout appearance, world
visuals and gameplay. Sustained >=40 FPS remains the native acceptance gate.
No Workshop or VPS action.

# Previous checkpoint — shared enemy AI field and cell work

The October 8 UTC / October 7 local three-minute capture verifies clean main
`0388d03`, complete CPU profiles, fixed preferences, fully idle VR and zero
Lua errors. Active play averages 21.8151 FPS, median 37.870 ms, p95 77.751 ms
and p99 129.473 ms, with 1,614 native walls. The generated workload differs
from earlier captures; sustained >=40 FPS remains unmet. Server close-defense
and sanctuary BeforeAI average 44.756 and 41.560 CPU ms per recorded second.
Timings are inclusive; their sum is not a frame budget.

Borrow repeated plain entity fields only across adjacent callback-free
comparisons in shared close-defense. Sanctuary BeforeAI queries current cell
depth only when it can still affect the decision after admission. Preserve
status/life cleanup and query order, callback mutations, primary commitments,
claim/service/cancel order and fresh positions where cell depth is needed.
No status cache, AI cadence, cooldown, attack, quota, population, geometry,
graphics preference or authored tuning changes. Live GDD 00 → 01 → 07 governs
this implementation-only checkpoint; the live revision remains unchanged.

Finite gate: exact published-parent/candidate traces must match. Across 3,600
production close-defense calls, modeled native Lua-field reads fall
161,400→134,400 while all 12,000 status queries remain. Across 5,001 admission
calls, exact-cell queries fall 5,001→2,001 and position queries 15,003→12,003.
All 20,608 semantic trace rows match, including callback/expiry/primary and
claim-time movement cases. The exact parent fails the work bound. These are
headless work counts, not hardware FPS. The frozen source passes 21/21 focused
checks, 314/314 canonical suites and 885 Lua parses. All 2,560 source files
remain unchanged during both gates; every command/receipt and all 628 matrix
stream hashes are independently checked. The installer/runtime manifest now
covers close-defense (50 installer / 46 runtime sources); absent/mixed sources,
transport and cached hashing pass. Earlier fixture failures and interrupted
attempts are preserved and not reused. Only documentation/evidence packaging
follows; all nine authority/test hashes are rechecked before publication.
See [finite gate and native evidence](validation/STEAM_DECK_20261008_ENEMY_AI.md).

After validated publication, fully quit GMod, pull/install, restart gm_flatgrass
and run the usual fixed-preference three-minute capture:
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply, then return
performance_client_latest.txt and console_latest.txt. Require exact source,
complete profiles, idle VR, no new Lua errors, intact AI/status/entry behavior
and world visuals. Sustained >=40 FPS remains the native acceptance gate.
No Workshop or VPS action.

# Previous checkpoint — combat-feed span work reuse

The October 8 UTC / October 7 local three-minute capture verifies clean main
`8bac44a`, complete CPU profiles, fixed preferences, fully idle VR and zero
Lua errors. Active play averages 22.3049 FPS, median 38.212 ms, p95 82.537 ms
and p99 120.064 ms, with 1,556 native walls. The generated workload differs
from earlier captures; sustained >=40 FPS remains unmet. CombatRollFeed is the
largest measured HUD callback, averaging 1.2393 ms over 3,944 rendered frames.

Reuse colors and exact rounded outline coordinates within the existing layout
span. Borrow the selected native font only inside one immediate DrawLines call;
other paints always establish their own font. Preserve all ten native text
submissions per span, position/order/font/color/alpha, live palette changes,
layout invalidation, HUD/history parity, expiry, ACKs and dice explosions. No
renderer, preference, graphics, timer, cadence, authored tuning or gameplay
change is included. Live GDD 00 → 01 → 06/07 governs the checkpoint.

Finite static gate: actual published-parent/candidate raster traces match;
warmed 600-frame feed keeps 42,000 draws while font selections fall 4,200→600,
Color allocations 4,200→0 and coordinate rounding 84,000→0. The exact parent
fails the new work bound; all 313 drawing scenarios match. Position/palette/metric
mutation and release of retired layouts are verified. The frozen source passes
20/20 focused checks, 313/313 canonical suites and 884 Lua parses. All 2,556
source files remain unchanged during the gates; all commands, receipts and 626
matrix stream hashes are independently checked. Documentation/evidence alone
follows, with production/test hashes rechecked before publication. Headless
work counts do not establish FPS savings. See [finite gate and native evidence](validation/STEAM_DECK_20261008_HUD_SPANS.md).

After validated non-force main publication, fully quit GMod, pull/install,
restart gm_flatgrass and use the fixed-preference three-minute capture:
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply, then return
performance_client_latest.txt and console_latest.txt. Require exact source,
complete profiles, idle VR, no new Lua errors, intact feed and world visuals.
Sustained >=40 FPS remains a native acceptance gate. No Workshop or VPS action.

# Previous checkpoint — drawable static-box Lua-field reuse

October 8 UTC / October 7 local capture verifies clean `4af3b40`: 21.9185 active
FPS, 38.689 ms median, 81.794 ms p95, 141.747 ms p99; 1,732 native walls,
complete profiles, fixed preferences, fully idle VR and zero Lua errors.
The generated workload differs from earlier captures, so this is not an
isolated source regression. Sustained >=40 FPS remains unmet.

Extend the existing verified weak static-box Lua-table borrow through drawable
readiness/accessors and snapshot ownership, retaining live native validity,
hidden state, bounds, pose, inherited/custom accessor fallback and every draw.
Snapshot rebuilds read current native scalars once. No timer, cadence, tuning,
population, gameplay, renderer, graphics or saved Options change is introduced.
The paired scene retains 14,400 draws while counted native entity-field reads
fall 273,600→172,800 (36.8421%); all 726 recorded mesh/wireframe rows match.
The exact parent fails the new work bound. These are headless counts, not FPS.

The frozen candidate passes 29/29 focused checks, 313/313 canonical suites and
884 Lua syntax files; all source files stay unchanged during the gate, and
all 313 receipts/commands plus 626 raw stream hashes are independently checked.
Documentation/evidence packaging alone follows; code/test hashes are rechecked
before the non-force main publication. See [finite gate and native evidence](validation/STEAM_DECK_20261008_LUA_FIELDS.md).

Next: fully quit GMod, pull/install verified main and obtain the usual exact-
source three-minute fixed-preference gm_flatgrass capture with:
`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Leave GMod open through the final server reply, then return
performance_client_latest.txt and console_latest.txt. Floors/stairs/grates/
underdeck and sustained >=40 FPS remain native acceptance gates. No Workshop
publication or VPS operation is included.

# Previous checkpoint — F3 team-menu hint below the campaign clock

October 7, 2026: recovered renderer progress is banked on verified main
`7364a7df49e4eb86266245387080947959fba376`, tree
`65156b6235a07962201662c499d3283c45149c15`. Its frozen 313-suite evidence,
source hashes and archive were reverified during recovery.

The author's subsequent QOL request moves the existing Soldier, waiting-Soldier
and spectator F3 hint to the upper-left HUD at (22, 104), directly beneath the
campaign clock at (22, 72). The existing small outlined font and role/menu
lifecycle remain in use. The production team-menu validator passes 229
assertions; campaign-timeout and HUD-text regressions, the production drawing
position probe, changed-file Lua syntax and diff checks pass. Native placement
and the recovered renderer's hardware performance await the usual local
playtest/capture below. Publish this bounded QOL checkpoint immediately.

# Previous checkpoint — notification-backed static-box classification

October 7, 2026: the complete fixed-preference native capture verifies clean
published `d02c9e4`, all 44 exact population hashes, 14 client presentation
fingerprints, complete CPU profiles, idle VR and zero Lua errors. It averages
27.1493 active FPS, median 32.779 ms, p95 61.674 ms, p99 95.382 ms, with 1,456
native walls and initially 36 living wanderers. All 36 pacing windows remain
below 40 FPS. Different generated workloads prohibit source-only FPS attribution.

The generated-geometry callback is still the largest measured custom client
renderer. Extend the existing entity/weak-registry seam with notification-backed
nonzero BoxKind classification. Native pre-write deltas invalidate the cache;
unreceived zero values and unknown accessors retain live polling. Keep immediate
geometry/pose/hidden-state checks, full-update/transmission/refresh recovery,
exact draw submissions/order, native resources, population, AI, graphics and
Options. No timer, tuning or preference is added. Include the shared datatable
source in installer/client/server source verification.

The paired 1,200-box/120-pass production scene preserves 14,400 draws while
reducing native kind reads 144,000→0 and validity calls 144,000→14,400.
All 726 recorded mesh/wireframe rows match; the exact parent fails the work gate.
Cached collision boxes also use zero native entity-field reads through weak Lua
table borrowing, with guarded fallback for missing/copied tables or accessors.
The final isolated source passes 29/29 focused checks, 313/313 canonical suites
and 884 Lua syntax files with all 2,551 source files unchanged. After interruption,
120 hash-verified passing receipts were reused under that exact manifest and all
193 remaining suites ran fresh. All commands, receipts and 626 raw stream hashes
are verified; cross-source attempts are preserved and not reused. These are
headless operation counts, not hardware FPS. Publish verified main, then obtain
native acceptance; only evidence/documentation packaging follows the source gate.
See [the finite gate and native evidence](validation/STEAM_DECK_20261007_KIND_NOTIFICATIONS.md).

Then collect the usual exact-source three-minute fixed-preference gm_flatgrass
capture with `lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`.
Return performance_client_latest.txt plus console_latest.txt after the final
server result. Sustained >=40 FPS and native visual acceptance remain open.
No Workshop or VPS operation is included.

# Previous checkpoint — generated-geometry render state reuse

October 7, 2026: the complete exact-source `d582729` capture averages 26.3639
active FPS, with 1,486 native walls, 36 living wanderers, idle VR and no Lua
errors. Camera/map preferences change during recording and the generated
workload differs from the preceding capture, so the FPS difference is not an
isolated source benefit. All four parent Actions workflows pass. Sustained
>=40 FPS and native camera/map visual acceptance remain open.

Generated static geometry remains the largest measured custom rendering
callback. Extend its existing TexturedBox authority with pass-local reuse of
identical material/tint/alpha state. Preserve all mesh/UV/matrix submissions,
visibility, draw order, wireframe boundaries, native resource lifetimes and
ordinary direct APIs. Unknown helpers use the ordinary path; nested/throwing
scopes unwind their own state. No server rules, population, graphics settings,
camera/map behavior, tuning or experimental wall-batch defaults change.

The paired warmed 120-floor/120-pass scene keeps 14,400 draws while reducing
native state writes from 72,000 to 600. Exact mixed mesh/wireframe submissions
match, and the parent fails the new work gate. The completed frozen gate passes
313/313 suites and 884 Lua syntax files, with all 2,548 source files unchanged.
After interruption, 62 canonical passing receipts were independently verified
and reused, then all 251 remaining suites ran; all 313 commands/receipts and
626 raw stream hashes are independently verified. These are headless operation
counts, not FPS. Publish the coherent source checkpoint, then collect the usual
fixed-preference native capture. See
[finite gate and native evidence](validation/STEAM_DECK_20261007_DRAW_STATE.md).
No Workshop or VPS operation is included.

# Previous checkpoint — saved camera/map Options and Steam Deck performance

October 7, 2026: the author requests a third-person checkbox and separate map
size (0.5–1.5×) and opacity sliders while optimization continues. Live GDD
normalized 01/06/07 and the bounded HUMAN Options paragraphs are amended and
exact-readback verified before implementation. Extend the canonical saved
preference, native base camera, Options UI and minimap presentation authorities.
The menu scrolls on small windows; all map layers share one cached transform
and opacity scope without rebuilding topology. Preserve first-person/current
map defaults, native weapon/cinematic/VR views, Magic and all server rules.
The accompanying bounded performance change removes per-frame quadrant
rectangle records; paired default drawing submissions remain identical. The frozen gate passes
313/313 suites and 884 Lua syntax files; the paired 10,000-frame probe
allocates 1.503 KiB versus 10,859.472 KiB. These are headless operation
counts, not native FPS.
See [author scope](briefs/PLAYER_OPTIONS_20261007.md) and
[finite gate/evidence](validation/PLAYER_OPTIONS_20261007.md).

The new complete exact-source `00dd5ea` native capture averages 17.0759 active
FPS with 1,684 walls and 64 living wanderers, idle VR and zero Lua errors.
It does not test the subsequent safety-coordinate cache on parent `bed0d456`;
all four parent Actions workflows pass. Sustained >=40 FPS and these options'
native visual/camera acceptance remain open. Freeze/validate the coherent
checkpoint, publish verified main immediately, then perform the single native
gate in the validation document. No Workshop/VPS operation is included.

# Current Steam Deck checkpoint — exact cell-centre coordinate reuse

October 7, 2026: the new complete native capture verifies clean `00dd5ea`,
10 client renderer and 44 population fingerprints, idle r2 VR and zero Lua
errors. The startup toolgun warning is gone. Active rendering averages 18.3706
FPS with 1,552 walls and 54 living bodies; the previous capture had 1,366 walls
and 40 living bodies, so these runs do not establish a controlled regression.
Sustained >=40 FPS remains unmet. Safety queries are a measured server hot path.
Extend the canonical cell-centre calculation with exact native scalar reuse,
invalidated on every cell/config/origin mutation, preserving immediate safety,
targets, AI cadence, population, graphics and the accepted native renderer.
The paired 10,000-query probe constructs zero centre Vectors instead of 20,000, with exact native-coordinate equivalence; this is not an FPS claim. The complete frozen gate passes 313/313 suites and 884 Lua syntax files.
See the [finite gate and native evidence](validation/STEAM_DECK_20261007_CELL_COORDINATES.md).

After frozen source validation and verified main publication, collect the usual
three-minute gm_flatgrass capture with
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Preserve Proton/windowed/graphics settings, complete both client/server results,
and return performance_client_latest.txt plus console_latest.txt. Native FPS
acceptance remains open; no Workshop or VPS operation is included.

# Previous Steam Deck checkpoint — static draw snapshot reuse

October 7 UTC / October 6 local, 2026: recovered the published Magic/Q/M/toolgun
checkpoint at `8f6667098481dbcd034efe9013b05a95086f386b`; all four Actions workflows
pass, including the complete frozen matrix. Resume the authorized performance
pass using the retained exact-source `9f88e54` capture (23.7135 active FPS and
fully idle VR). Generated static geometry is the largest measured custom client
callback. Its existing mesh cache now borrows the box renderer's validated scalar
snapshot instead of reading native bounds/pose components again in the same pass.
The same owner and exact raw draw arguments are required; general callers retain
the ordinary API. Every render pass still reads current native geometry, preserving
immediate mutations, culling, meshes/UVs/materials/transforms and native lifetimes.
The paired 120-box/120-pass scene has byte-identical submissions and reduces
native vector component reads from 273,600 to 129,600 (52.63%). These operation
counts are not a hardware FPS claim. The frozen candidate passes 313/313 suites, 29/29 focused checks and 884 Lua syntax files, with no source changes during the full gate. See the [finite gate and evidence](validation/STEAM_DECK_20261007_DRAW_SNAPSHOT.md).

After the frozen source gate and verified main publication, the next required
evidence is the ordinary exact-source three-minute gm_flatgrass capture with
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Check floors/stairs/walls, the new Q/M/magic feel and disappearance of the startup
toolgun warning. Sustain >=40 FPS remains the open target. Preserve population,
gameplay, graphics settings and idle VR. No Workshop or VPS operation is included.

# Previous intervening correction — Magic costs and map keys

October 7 UTC / October 6 local, 2026: the author requests Q and M for the map,
cheap Beam/Super Ball, Bolt 4, Cone 9, Melon 11, cheaper remaining Forms and all
Content riders, plus smaller Bomb/Missile explosions. The live GDD normalized
03/06/07 and HUMAN are amended and exact-readback verified before implementation.
The canonical catalog updates existing definitions in place on refresh; shared
casting, selection/snapshot and the regenerated manual carry the same prices.
Q/M retain ordinary map ownership, cache and focused-UI rules. VR overlay r2
retains the optional Sandbox pickup-list editor outside the weapon autoloader,
preventing that folder from registering a toolgun without shared.lua. The
installer safely upgrades the exact published predecessor as well as pristine
upstream, preserving operator-modified copies. See
[author scope and complete cost tables](briefs/MAGIC_MAP_20261007.md) and
[finite gate and evidence](validation/MAGIC_MAP_20261007.md).

The new exact clean `9f88e54` native capture verifies ten renderer and 44
population sources and confirms idle VR in 42 resource snapshots, including
all 36 pacing windows and both realms: no VR players, runtime hooks, recurring
timers, method overrides, pending work or native resources. The native VR idle
gate passes. The only reported Lua error is the single startup toolgun warning;
its r2 source repair needs a new native boot. Active rendering is **23.71 FPS**
over 129.08 seconds, median 35.969 ms and p95 75.075 ms. Sustained >=40 FPS still
fails. Preserve native walls, all population/gameplay constraints and previous
HUD/overlay optimizations. Different generated workloads prevent a controlled
before/after FPS comparison. After this bounded correction, resume the measured
rendering/AI optimization pass; the new profile's largest measured client LOD
callback is generated static geometry (138.41 ms/second, inclusive wall-clock).
Nested timings overlap and GPU/engine work remains unmeasured. Headset activation
and the new balancing/input feel remain separate native acceptance gates.

# Previous intervening correction — Hair Trigger

October 5, 2026 author correction: Hair Trigger is one nonrepeatable DEX 13 feat
at 55% faster firearm firing; Rapid Fire and Lead Storm are removed. Revolver,
pistol, shotgun, SMG and AR2 share the 1.55 cadence multiplier. AR2 projectile
spacing and completed-burst cycles both use it. Existing owned/resolved ranks
collapse to one Hair Trigger; unchosen retired cards use canonical stored-hand
repair. The card and manual say "Increase firearm firing rate by 55%."
Live HUMAN and normalized 04 rules are reconciled and readback-verified; the
current catalog has 112 ordinary feats, six fallbacks and nine capstones.
See [author scope](briefs/HAIR_TRIGGER_20261005.md) and
[finite source checks](validation/HAIR_TRIGGER_20261005.md).

Published on main at `85789e3211c4c9082fc1d938908c7542c7dd10a4` before resuming
the optimization pass below. It preserves the accepted native wall renderer and the overlay optimization.
Native firing feel and sustained 40 FPS acceptance remain open; no Workshop/VPS
operation is included.

# Current author direction — Steam Deck performance

October 7 UTC / October 6 local, 2026: before testing the HUD checkpoint, the
author requests zero recurring unused VR work and automatic resume on VR presence.
The current bounded checkpoint scopes the actual pinned VRMod addon's hooks and
timers, suspends idle runtime registrations and shared desktop method overrides,
defers native loading to local headset start, and preserves passive presence
networking. First join/local start resumes support; last exit/disconnect returns
to idle after finite teardown. Invalid disconnects retire proxy entities; queued
creation cannot outlive its owner. Both hands drop through the canonical pickup
authority, preserving world props and remaining VR players' holdings while
retiring the final native motion controller. The ordinary development installer
applies the same offline overlay as the dedicated launcher, safely migrating only
a pristine old dependency. Existing performance files automatically include VR
counts plus independent mounted hashes for all 139 addon Lua/two bridge files.
No recurring diagnostic poll is added. The previous HUD/cache, accepted native
wall renderer and all population/gameplay constraints remain. See
[VR idle finite gate and limits](validation/STEAM_DECK_20261007_VR_IDLE.md).
The complete frozen source gate passes **313/313 suites and 884 Lua syntax files**,
plus all 139 mounted overlay Lua probes and the 14-check VR gate. Canonical
commands, all 313 individual receipts/626 raw stream hashes and unchanged
2,529-file source digests are independently verified. Complete raw evidence and
the two interrupted inspection passes are preserved with that finite gate.
Native sustained >=40 FPS and headset acceptance remain open; no Workshop/VPS
operation is part of this pass.

October 5, 2026: optimize the post-music-removal build for sustained >=40 FPS
on Steam Deck, Proton, windowed, Arch Linux Desktop mode. Reported baseline is
approximately 15 FPS, not an instrumented measurement. This implementation pass
supersedes historical sequencing, preserving game rules, population, progression,
safe arrival, authored bosses and ambient/event audio. Validated non-force pushes
to main are authorized; Workshop publication and VPS deployment remain held for
native acceptance. See [current evidence](validation/STEAM_DECK_20261005.md).

The current candidate extends the existing Reduced Effects setting with spatial
batches of the original container hulls and simpler diffuse lighting; section
hues, UVs, warning overlays and native collision remain. It skips render work for
invisible collision boxes and retains unchanged render bounds. The canonical
navigation cache retains completed sanctuary routes without evicting the existing
72 home-distance trees; mixed-source testing repaired the first checkpoint's
shared-tree regression. Exact paths, gate/event/filter invalidation, population,
combat and progression remain protected.

`lod_perf_start 180` adds bounded, opt-in rendered-frame evidence after wall
preparation/warmup, including active-play percentiles, five-second pacing windows,
configuration, source verification and resource snapshots. Source checks and
synthetic work reductions are evidence of implementation, not native FPS.
The first exact-source native capture timed out with all 1,542 walls unbatched
and zero frame samples. This is unmeasured FPS. Its population observer ran, but
the console truncated the full source list and the separate DATA file could not
be located. The repair removes the duplicate wayfinding appearance writer,
lets batches consume the canonical desired sampler, bounds preparation before
sampling, and mirrors existing population evidence automatically into the client
capture. See [native failure, repair and finite retest](validation/STEAM_DECK_20261005_NATIVE_REPAIR.md).
The next exact-source capture on main 438c3d8 measured 18.71 FPS (1,529 active
frames / 81.72 seconds; p95 113.06 ms) and the supplied video shows missing wall
surfaces. Replacement batching was ready with all 1,448 originals hidden when
sampling began. This fails visual acceptance and does not meet the 40 FPS target.
Native wall rendering is restored by default while keeping Reduced Effects and
the other optimizations. Batching is retained only behind the explicit, unsaved
`lod_wall_batches 1` test switch; native draw errors restore every original and
stop retrying. Exact native failure remains unproven; bounds/count/static tests
cannot certify rasterized visibility. See [visibility repair and evidence](validation/STEAM_DECK_20261005_WALL_VISIBILITY.md).

The author accepts native wall visibility on exact clean main 6dc145d: "Walls
look good again." The new capture verifies all seven renderer/41 population
sources, with batches disabled and zero hidden originals throughout its live
windows. It measures 13.68 active FPS / 41.80 seconds, p95 137.926 ms, on a larger
1,868-wall maze. Different generated workload prevents a controlled comparison
with the earlier 1,448-wall run. The 40 FPS target still fails.

The next source checkpoint repairs a demonstrated perpetual appearance loop:
138,048 applications without becoming idle. The sole native writer now applies
material/color/skin once per exact model and invalidation lifetime, preserving
the original appearance and <=192-model batch. Native getter acknowledgement
remains diagnostic rather than a reason to rewrite the same appearance forever.
World/palette/model-owner/mode/refresh changes reapply it. Keep the now-accepted
native renderer; experimental batching remains opt-in. See [fresh evidence and
idle-writer repair](validation/STEAM_DECK_20261005_WALL_IDLE.md).

The new clean f657913 capture confirms native quiescence: 1,364 applications
before sampling and no further appearance writes across all 19 live windows,
with batches disabled and zero hidden originals. It measures 28.96 active FPS
over 92.95 seconds, median 31.063 ms and p95 56.397 ms. The smaller maze prevents
a controlled comparison with the previous 1,868-wall run. The appearance-loop
gate passes; sustained 40 FPS still fails. The author reports an improvement.

The current bounded checkpoint removes off-camera board/logo submissions through
the existing conservative current-view sphere test, skips signage in depth/sky
passes and caches exact instance text metrics. Placement, distance and nearest-64
brand admission stay unchanged; native walls remain enabled. Frame receipts add
copied overlay counts/timings and verify branding as an eighth renderer source.
The population/installer manifest grows coherently to 42 sources. The parent's
complete-matrix CI failed before the full matrix because the installer test raced
background startup children against temporary-directory cleanup. The repaired
test owns, terminates and reaps only its installer descendants before cleanup.
See [capture, finite gate and repair](validation/STEAM_DECK_20261005_OVERLAYS.md).

The author now requests autonomous optimization/testing until native evidence is
necessary. The next bounded source checkpoint keeps only the exact nearest 64
brand candidates, using the original append/sort path at or below that ceiling
and a bounded heap above it. It retains immediate quad submissions and weakly
caches each model's latest fitted corners, with at most two physical faces.
Pose/scale, artwork/metadata, safe-area, physical bounds, helper and Lua-refresh
changes invalidate the cache; cleanup/replacement does not retain retired models.
The paired parent/candidate probe retains the same selected/drawn logos while
reducing 600 steady draws from 19,800 to 600 vector constructions and from 600
to zero repeated fit resolutions. Maximum sorting falls from 968 records to
64 in the fixed loaded scene. Existing capture windows copy candidate/admitted
counts automatically; no new setting, native mesh, hidden wall or game rule is
introduced. See [finite checks and limits](validation/STEAM_DECK_20261005_BRANDING.md).

The October 6 capture independently matches all 42 installed/mounted source hashes
to clean main `7f93cb145fdf1e84fa6a3cfebb62cba76511aab2`. It spans 179.92 measured
seconds (163.50 active), with 17.31 active FPS, median 47.440 ms and p95 104.987 ms.
All 2,830 active frames exceed 25 ms; sustained 40 FPS fails. This generated maze
has 1,718 wall models and 60 initial roamers across three floors, versus 1,364
models and 36 roamers across two floors in the earlier f657913 capture. Graphics
settings match; this is not a controlled source-regression comparison.
The sole wall appearance writer stays idle at 1,718 applications, zero retries,
and zero hidden originals in every live window. Window snapshot logo CPU costs
range 0.390–1.010 ms (median 0.583); wayfinding reports zero visits/draws. These
isolated CPU snapshots cannot identify the remaining engine/server/GPU frame cost.

The next bounded checkpoint extends the existing capture with optional `profile`
attribution after warmup. It measures existing LOD hooks, native entity callbacks,
selected AI/navigation services and the client PreRender-to-PostRender interval.
Watcher and entry safety are timed at their canonical bodies/calls without
changing their exact binding identities; original callback arguments, all
returns and errors remain intact. Weak ownership and guarded restoration protect
retired models and newer method bindings. A single admin-owned, finite server
lease sends bounded five-second progress reports plus a final reply; the same
performance file preserves partial evidence on immediate quit and merges a
matching final reply. Default capture/play has no profiling wrappers or scans.
Inclusive rows overlap; diagnostic overhead is included, native engine/timer/
gamemode-method work remains partly unmeasured, and this is not GPU profiling.
No gameplay, authored tuning, geometry, population or graphics default changes.
See [native result and CPU attribution](validation/STEAM_DECK_20261006_PROFILE.md).

Recovery on October 6 verifies that published source `0e26d65` completed all
four CI workflows successfully, including **309/309 complete integration suites**
and **879 Lua syntax files**. The full artifact, suite-log hashes and all 562
production file hashes independently match the clean checkout. The complete
[archive and verification receipt](validation/STEAM_DECK_20261006_PROFILE.md#completed-published-matrix--recovered-october-6-2026)
close the pending source gate. No unfinished source change or newer profiled
native capture was recovered. Continue at the native attribution gate below.

The next native action after source publication is a fully restarted gm_flatgrass
capture with `lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Keep Proton, windowed Arch Desktop, resolution, graphics settings and loaded
population; play through the full capture before quitting. Wall bodies, nearby
boards and company artwork must remain visible when turning and crossing stairs.
Return performance_client_latest.txt + console_latest.txt; client/server CPU rows,
overlay counters and population are included automatically. This measures the
remaining bottleneck; it does not claim an additional FPS improvement. Sustained
40 FPS acceptance remains open. Workshop and VPS remain outside this pass.

The next complete capture independently matches all 42 authorities to clean
main `a4ecb4b`, measuring 21.37 active FPS (171.18 seconds; median 40.164 ms,
p95 79.436 ms). It has 1,406 wall models and 40 initial roamers on two floors.
The static-geometry render hook is the largest measured game-code render row;
3,572,160 static-box Think calls mostly poll an existing one-second deadline.
Server attribution fails explicitly because its JSON exceeds the wire ceiling;
missing server rows are not evidence of inexpensive AI/navigation.

The current bounded source checkpoint uses conservative oriented-box support planes
instead of broad origin spheres, shares one native bounds/pose snapshot per
drawable box/pass, and schedules the existing bounds refresh at its existing
one-second deadline. Incomplete datatables retry immediately; transmission wakes
the callback and the existing weak registry survives Lua refresh. Meshes, floor
UVs/material/colors, grates, stairs, false-floor visibility, native wall bodies
and all server geometry/gameplay remain unchanged. Oversized finite CPU reports
use native compression, retaining all rows/timings, with the original 60,000-byte
wire ceiling and a 262,144-byte decompression ceiling. Small JSON reports retain
their existing wire format. The corrected frozen source passes 309/309 complete
integration suites and 879 Lua syntax files, with exact raw log/source hash
verification and failed-attempt evidence preserved. See the
[finite source/native gate](validation/STEAM_DECK_20261006_STATIC_GATE.md).

After publication, repeat the same fully restarted three-minute profiled capture.
Require complete server attribution, visible floor/stair/wall surfaces and no
new Lua errors; measure the remaining bottleneck and the still-open >=40 FPS
target. Use the same console batch and two upload files above. No Workshop/VPS
operation is included.

The next exact-source capture on clean main `8b89517` averages 18.42 active FPS
over 166.22 active seconds (median 46.331 ms, p95 87.786 ms), with 1,696 wall
models and 54 initial roamers on three floors. The preceding capture had 1,406
walls and 40 roamers on two floors; different workload prevents a controlled
regression claim. All source authorities match, native walls remain enabled and
both realms report zero Lua errors. Compressed server attribution now arrives
completely with `server_status=received`; its transport gate passes. Static
geometry remains the largest game-code render row, about 9.6 ms per rendered
frame. Server sanctuary and close-defense callbacks are also measured, without
changing their existing semantics or polling in this checkpoint.

The next bounded source checkpoint resolves the current camera planes once per
render pass and caches native box-axis scalars with the existing geometry/pose
snapshot. Exact identity-axis boxes reuse absolute plane coefficients; arbitrary
rotations retain their oriented support calculation and original tolerance.
Every pass still observes bounds, pose, kind and hidden-state changes; nested
cameras and Lua refresh retain separate current ownership. No cross-pass
visibility cache, distance/draw cap, mesh, UV, floor material or gameplay change.
See [native evidence and finite validation gate](validation/STEAM_DECK_20261006_PLANES.md).
The corrected frozen candidate passes all 309 integration suites and 879 Lua
syntax files; every canonical command, raw stream and source hash is verified.
Parent/candidate work reduces 120-box/120-pass basis-component reads from
1,166,400 to 1,080 and absolute-value operations from 216,000 to 1,800 while
retaining the exact visible surfaces. Full evidence and source bytes are retained
with that gate; no native FPS gain is claimed.
After verified source publication, repeat the same three-minute native capture
and return the same two files. Native surfaces, complete server rows and >=40 FPS
remain the acceptance conditions; work-count improvements are not FPS proof.

The following exact-source capture on clean main `a447d9f` averages 16.56 active
FPS over 104.69 active seconds (median 58.654 ms, p95 103.064 ms), with 1,648 wall
models and 54 initial roamers. All eight renderer/42 population authorities match,
settings remain unchanged, server attribution is complete and both realms report
zero Lua errors. The preceding capture had 166.22 active seconds and a different
maze; no controlled FPS regression or improvement is established. Static geometry
remains the largest measured game render row. Sanctuary and close-defense checks
account for 8,116.97 and 7,874.36 inclusive server CPU milliseconds respectively.

The current bounded checkpoint removes repeated native position-component reads
inside live sanctuary queries and direct-actor source-resolution allocations.
Admission still runs its existing service/context and all needed distance queries;
empty/far searches avoid allocating an unused nearby array. No cross-call spatial
cache, polling/timing change, tuning, population, rendering or combat redesign.
The paired unchanged parent/candidate gate retains 5,145 boundary cases and live
mutations; 10,000 distant membership queries use 20,000 -> 10,000 native position
reads. Direct-source and far-admission GC-stopped allocation growth drops to zero
in the fixed doubled workloads. All 310 complete integration suites and 880 Lua
syntax files pass, with independent command/receipt/raw-stream/source verification.
The inherited asset rebuild check produced an observed partial PNG prefix; the
exact frozen parent asset was restored and independently rebuilt/decoded. Final
source hashes match the initial snapshot; the observation and its unproven cause
remain in the evidence. No texture change is published.
See [native evidence and finite gate](validation/STEAM_DECK_20261006_ENTRY_HOTPATH.md).
After publication, deploy before starting the established three-minute profiled
capture and return the same two files. Exact source, intact surfaces, safe opening/
close defense, complete server attribution and sustained >=40 FPS remain the gate.

The next complete native capture independently matches all eight renderer/42
population authorities to clean main `7de6a8359af27713526a4d0108c110bac3bee9ed`.
It measures 24.86 active FPS over 165.78 seconds (median 35.727 ms, p95 68.876 ms),
with 1,340 walls, two floors and 39 living wanderers at its snapshot. Different
generated workload prevents a controlled comparison with the preceding 1,648-wall
capture. Complete server attribution arrives and both realms end with zero Lua
errors; 4,112 of 4,122 active frames exceed 25 ms, so sustained >=40 FPS still fails.
The parent's four CI workflows have completed successfully.

The current bounded source checkpoint removes repeated native text measurement
from the measured combat-feed draw path (mean 1.925 ms per HUD callback). Exact
coalesced-span advances are owned by bounded layouts and invalidate on text/font,
screen-size and Lua-refresh changes. The existing UI authority selects the font
once for left/top HUD text and retains the same nine one-pixel outline offsets,
foreground, ceil placement, semantic colors and fade. Other alignments retain
the stock helper. There is no event/lifetime/history-cap/ACK or gameplay change.
In the paired unchanged-parent/native-double probe, 600 steady tails retain
42,000 text submissions while measurements fall 46,200 → 0, font selections
46,200 → 4,200 and Color allocations 8,400 → 4,200. Exact installed/mounted
fingerprints extend coherently to ten render/44 population sources. The frozen
integration receipt and source hashes are preserved with the
[finite gate and evidence](validation/STEAM_DECK_20261006_HUD_TEXT.md).
These work counts do not establish a native FPS gain. After verified source
publication, repeat the established fully restarted, deployed three-minute
profile and return the same two files. Check feed/L-history readability and intact
world surfaces; native sustained >=40 FPS and Workshop/VPS acceptance remain open.

---

# Current author direction — ambient audio and core gameplay

Music System 3 is extracted into the separate `ShaelRiley/ms3-music-system`
repository with all original banks, sources, synthesis tooling and a manual
browser/WebView player. Deborah returns to ambient sounds and short event cues.
Keycard/jail-key discovery, unlock, learning, leveling and rescue cues no longer
depend on a music switch. Options exposes saved event-cue volume, Always Run and
Reduced Effects. All adaptive music code, download registration, hooks, banks,
source tooling and executable music-only tests leave this game repository.

This explicit October 4, 2026 author direction supersedes all historical music
requirements and pending music acceptance below. It does not reopen or redesign
combat, progression, enemies, bosses, VR or the ambient-sound lifecycle. Original
music evidence remains in the extracted repository; lightweight historical notes
below retain their historical status. Local native acceptance remains separate
from source checks. No Workshop publication or VPS deployment is part of this
source extraction/removal checkpoint.

Next native action: fully restart the updated local build on gm_flatgrass,
collect a keycard and open its gate. Verify the short discovery/unlock cues,
ambient and combat audio, and the absence of continuous music. Continue core
systems work after this finite audio regression check.

---

# Current repair checkpoint — gate-reveal enemy engagement

Source parent is verified main `2f4c968518ff29cb9ef206b3f9906d797b017ee1`, preserving
all authored modular bosses and the feat/music/VR work. A real generated-gate
regression reproduces an empty opening-pressure reservation: an enemy near the
Hero cannot acquire them under its native home leash, yet forces ready enemies
to withdraw. New reservations now require one current, native-eligible target;
stationary threat geometry, stale-route handoff, warning cancellation and actual
Watcher close-defense dispatch are repaired through existing authorities.

See [repair evidence and finite native procedure](validation/GATE_ENEMY_ENGAGEMENT_20261003.md).
Preserve sanctuary, combined opening quotas, native acquisition cadence/owned
states, full telegraphs, graph/gates and boss ownership. The publication reply
supplies the exact final source digest, complete matrix receipt, remote SHA and
CI result. Native GMod acceptance is still open; no Workshop/VPS operation.

Next: after exact-source restart on gm_flatgrass, open a gate and observe nearby
eligible enemies entering their actual attacks, including Soldier warning and
Watcher close retaliation, then verify reciprocal sanctuary safety. Keep all
previous native acceptance debts open.

---

# Current checkpoint — complete authored modular boss production

Source parent is verified main `96ab02aa78254eed9bfccb5b06dca947b82abd9f`. The original live GDD body was fully corrected and readback-verified before gameplay work. Exact authored order now routes eighteen new primary modules at Dungeons 2–19, retaining Gordon at 1 and Gordon→Hector at 20. Chuck alone owns Dungeon 14; Jane is subordinate. Timer-only automatic failure, retained no-Hero state and safe authored key locations remain authoritative.

The common registry/encounter owner extends canonical RPG damage/status/Push, native death/loot, Motion V2, graph/arena, music and key/jail/rescue. All mature authored routines, special completion, physical arenas, diagnostics and player manual are integrated. Read [production/acceptance](BOSS_PRODUCTION_ACCEPTANCE.md) and [exact implementation tuning](BOSS_IMPLEMENTATION_TUNING.md). The final publication reply supplies the exact child commit and frozen complete-gate receipt; do not substitute a focused pass or prior source count.

Native GMod visual/physics/input/co-op/Steam Deck acceptance remains open. After exact-source restart on gm_flatgrass, use the finite roster procedure in the acceptance record, prioritizing Chuck/Jane authority, Melf frozen identities, Button route/E timing, Joilette three-Cleaner recovery, flight/Strider cover/collision and the retained Gordon→Hector finale. Preserve all earlier feat/music/hit-stun acceptance debts. Source push only; no Workshop/VPS authorization.

---

# Current checkpoint — final feat rebalance

Implements the complete author ledger in `docs/briefs/FEAT_REBALANCE_20261002.md`
from remote-main baseline `b81e8b95c55df2c6f7f5eb8a4ef7292700aef68e` via recovered
validated checkpoint `e2997b15469ff335c2991d4f585770e8f0b4116c`. Existing music
and hit-stun floor repairs remain intact. The catalog now contains 114 ordinary
feats, six fallbacks and nine capstones, with retired ranks/CROSS ownership and
stored drafts repaired through the canonical migration authority.

`docs/FEAT_REBALANCE_ACCEPTANCE.md` records the exact inventory, review repairs
and native procedure. Publication `b5bf93bfc16828ac722113bb358d57b5026d2000` passed
the fresh 305-suite source gate. Separate VR CI then found a stale six-menu test
after removal of the Haste toggle. The repaired test now verifies the five
retained actions and is explicitly included in the final 306-suite frozen-source
matrix. This genuine expanded gate is distinct from the abandoned transfer's
unverified planned count. Verify the final remote commit and its Music/VR CI;
source checks are not native acceptance. No Workshop/VPS operation is authorized.

Primary live GDD rows match the ledger. Two duplicate corrections are applied and
readback-verified in tabs 06/07 (additive life capacity and Russian Asset's
at-least-15 funding/exactly-15 spend). Nine HUMAN duplicates remain blocked by
`FAILED_PRECONDITION` and a cancelled final attempt despite explicit permission.
Do not call GDD duplicate cleanup complete; preserve the successful corrections.

Next native action after verified source publication: fully restart/update GMod,
then run the compact acceptance session, prioritizing Russian Asset input and
vulnerability, movement/collision, ring reversal and stale-refund rejection.
Keep earlier music listening and hit-stun floor-presentation acceptance open.

---

# Current repair — MS3 song-first compositions

Author reports that the sixteen-bar system remains musically disjunct. Parent is `a73cafd2a7678bafe4bf84e8b4132af449546baa`, preserving intervening Gordon/gameplay work. Current direction supersedes randomized excerpt choice and immediate ordinary floor/tension replacement: play source-ordered driving edits through, preserve whole calm songs in staging, and let ordinary requests choose the next song. Boss/victory/Off, staging changes and new dungeon plans remain exceptions.

All 465 sources map to 40 continuous song edits plus eight short fanfares. No selected-window ranking, per-chunk foreground reassignment, competing-melody thinning or added exit fill remains in the active builder. A complete source performance is rendered once before bounded PCM slicing. Internal slices have no synthesis reset or per-chunk normalization; the player retains the 32-MiB ceiling and native compatibility fallback. Exact source windows and retained beat evidence are in `MS3_SONG_AUDIT.json`.

Run complete source/music/integration, real full-bank decode and actual browser song traversal gates before main publication. `validation/MS3_SONG.md` and its final receipt distinguish completed gates from native listening. The video remains inaccessible. Google rejected the live GDD amendment; `validation/MS3_SONG_GDD_AMENDMENT.md` preserves it. No Workshop/VPS action.

Next native action after verified source publication: fully quit/update/install main, enable Options → Music on gm_flatgrass, and remain in ordinary maze play for a complete song while crossing stairs and encountering changing danger. It should keep developing in order rather than switch every sixteen bars. Also check staging/deployment, boss, genuine victory and Off/On. Native perceptual continuity and Steam Deck performance remain unaccepted until heard.

---

# Current author-directed checkpoint — MS3 sixteen-bar source integration

From main `208a1af11c4448a054cc24e81603ed3446c0c55f`, the author authorizes source publication of genuine sixteen-bar arrangements and bounded playback. The canonical mapper now reads all 465 originals into 157 sixty-four-beat passages plus eight short fanfares (121,557 notes); catalog `ms3-s16-e5961c1e5e7bf8cd` matches Surge bank `ms2-surge-1d9386ddd67218a5`, 166 files / 46,853,341 bytes. Seven weak source-mapped exits contain baked percussion replacement fills. The new compact-tail loop avoids duplicate whole buffers and keeps the 32-MiB limit. Ordinary phrases advance after one pass; short-boundary role/stair response and healthy resident holds remain.

The active checkpoint includes source/MIDI/provenance parity, complete music and integration gates, actual decoding and browser-rendered long joins. See `docs/validation/MS3_LONGFORM.md` for exact evidence and outstanding limitations; source publication is not native acceptance. The guide video remains inaccessible/unverified. Google again rejected the live tuning insertion with `FAILED_PRECONDITION`; `MS3_LONGFORM_GDD_AMENDMENT.md` preserves it. This supersedes the earlier source-only candidate and two-bar hold design where they conflict, not their historical evidence.

Next native action: fully quit/update/install the exact published main, enable Options → Music on gm_flatgrass, and listen through at least two complete passages plus danger and a stair crossing/reversal. Confirm evolving sixteen-bar material, useful loudness, uninterrupted joins and clean Off/On. If a defect remains, collect `lod_music_client_status` twice and the normal console/summary logs. No Workshop/VPS action is included; local acceptance → Workshop parity → matching VPS remains the release order.

---

# Current repair checkpoint — MS3 sample-clock phrase continuity

The author reports rhythmic and dynamic segmentation on main 90510057c608f8e2beec9debc6ceec36b35d14f3. The previous frame-start/fast-seek repair is failed continuity evidence. The current authorized checkpoint moves capable clients to scheduled AudioBuffer playback of the same bundled Surge recordings, with the existing native backend retained for compatibility. This is rendered playback, not live synthesis. See docs/validation/MS3_SAMPLE_CLOCK.md for the design, measured gates, constraints and the still-required native audition. Source/automated audio validation never establishes in-game perceptual acceptance. No Workshop or VPS deployment.

---

# Current repair checkpoint — MS2 smooth phrase joins

Verified main `e633cd13fed0908ff424fb2da5190285cbc22407` is the repair parent. The author reports short clips changing too quickly and clearly audible fades at their joins, calls this MS3 and requests a quick fix with resident looping until replacement readiness. Native smoothness is failed evidence, not accepted continuity.

The canonical composer holds each ordinary phrase for four successful passes (14.77 seconds); roles/stairs/once-only victory remain responsive. Routine native joins use constant gain and natural release overlap. Offline full+tail arrangement bounds keep the shared peak guard from ducking at every join. If the same-role successor is not prepared, reuse the resident musical buffer on its eight-beat grid for at most two repeats within eight seconds; reject stale replacement and retry a complete phrase boundary. Preserve master gain 4, saved volume, peak ceiling 0.8 and all resource/lifecycle contracts. The encoded bank remains unchanged. See [focused evidence](validation/MS2_JOINS.md).

Live GDD 00 → 01 → 05/06/07 and the author Surge brief govern. Google rejected the tuning insertion with `FAILED_PRECONDITION`; its exact authorized-but-unapplied request is preserved. Complete music, actual decode and canonical integration gates precede source publication. Next native action: fully quit/update/install exact main, enable Options → Music and listen through several routine joins plus stairs for a steady level and unobtrusive transitions. Native Source smoothness and performance remain pending. No Workshop/VPS deployment.

---

# Previous repair checkpoint — MS2 intermittent phrase continuity

Remote main `174b011a62dd676285435feed2e551e8a3bf26bf` is the repair parent. The author initially reports silence, then hears intermittent music after several minutes or an audio-option toggle (cause uncertain). Their client diagnostic shows enabled/ready rendered playback, two channels, no reported backend error, quality 0 and nine native late skips. This is runtime-observed intermittent audibility and a failed continuity gate, not acceptance of the louder mix. Preserve the exact report in [MS2_CONTINUITY_NATIVE_REPORT.json](validation/MS2_CONTINUITY_NATIVE_REPORT.json).

Production regressions reproduce two causes of whole-phrase gaps: a prepared phrase discarded by a 100 ms frame hitch, and a correct native start treated as failed when its DHTML acknowledgement arrives 300 ms later. The native seam now admits prepared-frame delays up to 150 ms by fast-seeking past elapsed audio and retaining the original musical epoch. The existing 60 ms readiness tolerance still rejects late file opens. Larger frame delays resynchronize at a future bar. The composer separately waits up to one second for the result message; it never starts audio itself. One token per lane, bounded channels/opens/PCM, master gain 4, shared peak ceiling 0.8, saved volume, permissions, role/stair/victory behavior and the complete encoded bank remain constraints. Actual native state/position/volume and phase-join/ack-timeout diagnostics are available in client status.

Live GDD 00 → 01 → 06/07 and the explicit Surge brief govern. The tuning write received `FAILED_PRECONDITION`; [the authorized but unapplied request](validation/MS2_CONTINUITY_GDD_AMENDMENTS.json) is preserved. See [finite evidence](validation/MS2_CONTINUITY.md). Run the complete music gate, actual decode and canonical integration matrix before source publication. Next native action: fully quit/update/install exact main, enable Options → Music and listen for at least two minutes through staging, danger and a stair crossing. No entire missing phrases should occur during ordinary frame pressure. If gaps persist, run `lod_music_client_status` twice a second apart (composer statistics arrive asynchronously) and preserve both lines plus `console_latest.txt` and `rpg_summary_latest.txt`. No Workshop or VPS operation is included.

---

# Previous repair checkpoint — MS2 audible playback level

The author confirms music is audible on recovered main `b0f86dccedae3093355c239cd9608662b80cfd58`, but far too quiet. Median decoded Chill is about −36.81 dBFS, falling to −42.00 dBFS at the saved default 0.55 volume. The canonical native phrase seam now applies gain 4 (+12.04 dB), with one shared estimated score peak ceiling of 0.8. Existing decoded-peak metadata bounds floor lanes, natural tails, the quiet bridge and gains awaiting their 30 Hz writes. Decreases precede increases; each increase uses only remaining headroom. The common reduction preserves square-root stair weights and arrangement dynamics. Saved volume, Off, the catalog/composer, server authority and all encoded audio remain regression constraints.

Live GDD 00 → 01 → 06/07 and the explicit author Surge brief govern. Google rejected the tuning insertion with `FAILED_PRECONDITION`; its exact authorized but unapplied text is in [MS2_LOUDNESS_GDD_AMENDMENTS.json](validation/MS2_LOUDNESS_GDD_AMENDMENTS.json). The metadata-only producer change refreshes renderer provenance without changing synthesis or the bank's 59,993,192 audio bytes. See [focused evidence](validation/MS2_LOUDNESS.md).

Required source gates remain the complete music gate, actual full-bank decode and canonical integration matrix. Prior playback audibility is now runtime observed; louder balance still requires fresh native evidence. Next action: fully quit/update/install exact published main, enable Options → Music, and compare staging, danger and a stair crossing at the current volume setting. Confirm useful loudness, clear musical balance and no distortion; lower the slider to confirm control. Preserve `lod_music_client_status`, `console_latest.txt` and `rpg_summary_latest.txt` only if a defect remains. Workshop and VPS are separate actions.

---

# Previous repair checkpoint — MS2 playback recovery

The author reports silence on Surge main `795001f1fa27dc9c99a5d79ae845ed78a2a7a0da`. Production regressions reproduce an expired HTML startup deadline repeatedly extending the ten-second native-failure retry, and a later gap timeout overwriting the first audio-open error. Startup readiness/teardown now clear that panel's deadline; only a live initializing panel may time out. The first native error survives later open/bridge/gap failures, and status exposes the fixed remaining backoff and pending startup. The unchanged catalog, audio bank, server authority and host Options remain regression constraints. See [focused evidence](validation/MS2_SURGE_RECOVERY.md).

Required source gates remain the complete music gate, actual audio decode and canonical integration matrix. Native silence is reported; its initial engine diagnostic was not recoverable, so audibility after this correction requires fresh evidence. Next action: fully quit/update/install the exact published source, start LoD on gm_flatgrass, enable Options → Music and listen in staging. If silent, run `lod_music_client_status` and preserve its exact output plus `console_latest.txt` and `rpg_summary_latest.txt`. Source publication does not publish Workshop or deploy the VPS.

---

# Previous author-directed checkpoint — MS2 Surge backbone

From verified main `c4fb2c0c497b661f0fa7bb972a5c3fe6683b3517`, the author replaces primary live note synthesis with offline custom Surge XT 1.3.4 rendering and bounded local Ogg phrase playback. The eight-block/48-arrangement/1,402-phrase/170,860-note catalog and server MusicDirector remain authoritative. Bank `ms2-surge-0f7591eb682f3b2b` contains 1,402 phrases plus one bridge at 59,993,192 encoded bytes. Acid has strong held-note filter movement; readable patches, pinned external build glue, complete hashes/levels and a 47.7-second audition are committed. No Surge runtime dependency or soundtrack streaming is required.

The ES5 composer keeps authored successor selection on a fixed 130 BPM clock. Native playback uses absolute deadlines, discards missed musical time, and bounds channels to eight / pending opens to two / estimated PCM admission to 32 MiB. Role bars, reversible stairs, once-only fanfare/Chill, private new-block announcements, default-Off and host Options enablement remain. Old per-note mutations/fills, +6% tempo slew and +22-cent lift are superseded; +8% critical gain remains. See [implementation](MUSIC_SYSTEM.md), [budgets](MUSIC_PERFORMANCE.md) and [finite evidence/native procedure](validation/MS2_SURGE.md). The authorized live GDD write failed with `FAILED_PRECONDITION`; its exact unapplied amendment is preserved.

Required source gates: `python3 tools/test_music_gate.py --output /tmp/ms2-surge-gate`, actual decode via `node tools/test_music_audio.js`, and canonical `python3 tools/test_checkpoint_g_integration.py`. Native acceptance is pending: fully quit/update/install exact main, start LoD on gm_flatgrass, enable Music in Player Menu → Options, then hear staging/deployment/calm/danger/combat/relaxation/stairs/reversal/boss/fanfare/Chill/Off–On and inspect `lod_music_client_status`. Judge coherent dance-synth timbre, Acid movement, musical joins, no catch-up, smooth stairs, immediate Off and Steam Deck performance. Workshop and VPS remain separate, untouched actions.

---

# Previous repair checkpoint — MS2 Options enablement

The author now confirms native music plays with `lod_music_enabled 1; lod_music 1` on main `93e793cfb35bc0dbef81cb2b079a385ff935578d`, but selecting Music in Options does not start it. This isolates the remaining defect to UI enablement: the old checkbox controls only `lod_music` and can appear checked while the server master is Off. Playback itself is now natively observed under explicit permission; broader musical/performance acceptance remains separate.

The existing MusicDirector demand channel now carries an explicit Options-enable intent. Only the listen-server host or a superadmin may use it to turn the master On. Ordinary startup/reconnect demand preserves default-Off; a player's Off remains personal. The host/operator checkbox displays both local preference and master permission, and its read-only refresh cannot alter settings. The new production-Options regression covers the queued client command, server grant, paced plan/state delivery, renderer handoff, per-player Off and denied remote enablement. See [repair evidence](validation/MS2_OPTIONS_REPAIR.md).

Next native action: fully quit/update/install main, start LoD on gm_flatgrass and toggle Options → Music Off/On. Music must resume without console commands. Preserve `console_latest.txt` plus `rpg_summary_latest.txt` if the menu path fails. The prior console-enabled audibility report is positive evidence; this menu repair still requires its own fresh test.

---

# Previous repair checkpoint — MS2 complete-bank JSON admission

The author reports that music remains silent on main `6abd1e2786a075888d27d6f510a3d48226f18353`, while the Options correction is visible. The earlier path repair is insufficient: GMod's default JSON decoder limits the total number of keys to 15,000. The actual bundled catalog contains 41,125 keys and 62 of the 63 note pages exceed that limit (largest 16,988), so both admission stages reject the score. Only trusted, byte-bounded bundled catalog/note decoding now uses the documented `ignoreLimits` argument; schema/note validation, cache budgets and network decoder limits remain in force.

The permanent catalog suite now runs production server/client loading against every real arrangement and note page with that native key boundary. It reproduces catalog rejection before repair and note-delivery rejection with the catalog-only fix, then admits all 48 arrangements, 1,402 phrases and 170,860 notes with both fixes. See [repair evidence](validation/MS2_JSON_REPAIR.md). Run the finite music/audio gate and publish the exact verified source. Fully quit/update/install GMod, load LoD on gm_flatgrass, enable `lod_music_enabled 1; lod_music 1` and listen in staging/gameplay. Native audibility remains pending fresh evidence; preserve `console_latest.txt` plus `rpg_summary_latest.txt` if failure persists.

---

# Previous repair checkpoint — MS2 catalog loading

The author's first native MS2 attempt on main `bc3cf1967ebdc77e98c5fc028ef6337c9e7139fe` reported silence and `Couldn't include file 'lod\\ms2\\catalog.lua' - File not found or is empty` from `sh_music.lua` during `sv_music.lua` startup. The catalog exists in the repository; the nested loader incorrectly assumed include paths always resolve from the gamemode root. Catalog, engine, note pages and client distribution now use the explicit `legend_of_deborah/gamemode/lod/ms2/` virtual path. Missing mounts produce a precise diagnostic before attempting a noisy include. The user also requests removal of the stale server-disabled Music message; Options now retains the location/danger description without a recurring status callback.

The strengthened music fixture models nested and rootless include contexts and a client using server-delivered Lua without loose files. The new production-path regression reproduces the old failure, checks server catalog admission, client engine/note handoff, every actual distributed score file and missing-mount recovery. Run the finite music gate and GitHub CI. After pulling/installing, fully restart GMod, load LoD on gm_flatgrass, enable `lod_music_enabled 1; lod_music 1` and listen in staging/gameplay. Native audibility remains pending fresh evidence; prior offline audio/source results did not establish native acceptance. See [repair evidence](validation/MS2_LOADING_REPAIR.md).

---

# Previous author-directed checkpoint — Music System 2

Repository `ShaelRiley/the-legend-of-deborah`, canonical `main`; implementation parent `b4f9f67e2d837e71da1a194dc655a212fd74ff4c`. The author explicitly replaces the bandwidth-heavy MS1 score with a complete local MIDI/synth system and authorizes source publication and cleanup. This checkpoint supersedes the older streaming-music provisioning sequence below; preserve intervening VR/gameplay work.

Eight authored blocks and all 48 MIDI arrangements are compiled into 1,402 curated phrases, with original-source lineage, D-Dorian cleanup, nine instrument parts, cadence/energy successor graphs and portable MIDI exports. The existing reactive MusicDirector retains permission/default-Off, seeded physical-floor plans, staging/portal continuity, pressure, bosses, victory receipts and Die Logger ownership. MS2 adds local synthesis, procedural performance variation, periodic fills, a shared musical clock, restrained timer BPM/expression and bounded native fallback. MS1's downloader/origin/upload/cue implementation and obsolete tests are retired; historical evidence remains historical.

Read [MUSIC_SYSTEM.md](MUSIC_SYSTEM.md), [MS2_CATALOG.md](MS2_CATALOG.md), [resource budgets](MUSIC_PERFORMANCE.md) and [validation](validation/MS2.md). The finite gate is `python3 tools/test_music_gate.py --output /tmp/ms2-gate`; add `MS2_CHROMIUM` for actual offline Web Audio. GDD navigation 00 → 01 → 05/06/07 was followed. Google Docs rejects the authorized amendment with FAILED_PRECONDITION and its fallback browser session is view-only; [the unapplied amendment](validation/MS2_GDD_AMENDMENTS.json) is preserved. Explicit current author direction governs this design change.

Next native action: fully quit/update/install main, load LoD on gm_flatgrass and enable `lod_music_enabled 1; lod_music 1`. Play staging → portal → danger/stairs/reversal → boss → actual rescue/fanfare → Chill, then toggle Music Off/On and inspect `lod_music_client_status`. Confirm audible instruments, uninterrupted phrasing, restrained urgency, once-only fanfare and clean Off on the intended PC/Steam Deck. Source and offline audio results do not establish Source/DHTML/co-op/FPS acceptance. Preserve existing native/release gates; no Workshop/VPS deployment is included in this checkpoint. Keep console_latest.txt plus rpg_summary_latest.txt for contradictory runtime evidence.

---

# Current user-directed branch checkpoint — VRMod server provisioning repair

The current user explicitly requests VR support published as TheMemeticist on
`master`. The earlier compatibility checkpoint is merged into main
`5b1b29166e03dfbc2faeca3634ddf379d0d84e6b`, but the live server reported its
VRMod addon missing. This repair bundles the complete pinned Lua/content addon,
installs and verifies it before every dedicated-server start, registers client
content, and requires actual VR networking in the deployment health gate.
Native startup also exposed weapon-definition hook return values stopping later
map initialization; those callbacks now allow the lifecycle dispatch to continue.
Controller menus, camera ownership and shared life/Tetris actions remain at
their existing seams. Gameplay authorities and physical-keyboard Special Move
recipes remain the baseline. `lod_vr_start` diagnoses the remaining client
prerequisites and requests the upstream VR startup command.

Finite gate: `python3 tools/test_vr_gate.py`; evidence and remaining headset/
multiplayer gates are in `validation/VR_COMPATIBILITY.md`. Deploy the source and
fully restart the service to load the dependency. This checkpoint does not
deploy the live VPS or publish a Workshop package. The current
music checkpoint and its separate deployment/acceptance work remain below.

# Previous main checkpoint — six-role music folder/ZIP catalog

The author requests Chill = Tension 1, Tensions 2–4, Boss and Fanfare, with the
first block as every missing-role default. From main `79faf3d`, the existing
music ingestion authority now accepts a complete folder/ZIP library, creates
manifests/versions/cues/chunks offline and publishes one validated catalog. Chill
also serves staging/post-fanfare; active/offered plans stay frozen. An explicit
cue rebuild preserves authored overrides; unchanged ordinary imports skip analysis.

Finite evidence: `validation/MUSIC_FOLDER_CATALOG.md`, 41/41 selected suites,
813 Lua syntax checks and 80 new real-audio/import assertions. The Google Docs
amendment failed with FAILED_PRECONDITION; its unapplied text is preserved in
`validation/MUSIC_FOLDER_GDD_AMENDMENTS.json`. Current explicit author direction
governs. No music origin, recordings, native acceptance or deployment is claimed.
Next: use `history/MS1_MUSIC_FOLDER_IMPORT.md` to provision HTTPS, import before a new campaign,
then test the exact source through Chill → tension/stairs → boss → rescue/fanfare
→ Chill. Retain default-Off and local acceptance → Workshop parity → matching VPS.

---

# Prior checkpoint — Options Always Run repair

The author reports that selecting Always Run does not produce running and
expressly authorizes commit/push. From verified main `673590c`, the existing
shared PlayerOptions movement seam now scales horizontal requests as well as
their effective speed cap. Walking-sized/analog requests previously stayed at
walking speed despite the raised ceiling. A zero native client cap is now
resolved from the move cap before publishing matching limits to both realms.

Live GDD 00 → 01 → 06 LOD-UI-OPTIONS-001 governs; no design change. The existing
Options binding, physical sprint modifier, Soldier rules and movement effects
remain authoritative. The failed-parent reproduction and 11/11 passing selected
checks (including 813 Lua syntax checks) are recorded in
`validation/AUTORUN_20260928.md`. Native acceptance remains pending: restart on
the published source, enable Options → Always Run, move normally, then hold the
sprint key to walk and release it to resume running. Preserve the other native
gates and local acceptance → Workshop parity → matching VPS release order.

---

# Prior checkpoint — universal enemy close defense

The author requests visible attacks from rare creatures and retaliation under
sustained crowbar pressure. From verified main `863f7fe`, native behavior now
offers an existing-service physical close defense before specialist wrappers;
committed primary attacks retain their controller. All hostiles share the existing
three-second melee-stagger recovery, and stock attack-sequence resolution covers
models whose NPC activity request falls back to idle. Preserve the recent skeleton
player-animation repair and existing combat/lifecycle/arrival authorities.

Live GDD 00 → 01 → 03/07 was read. Google rejected the design-amendment write;
the proposed text remains in `validation/ENEMY_CLOSE_DEFENSE_GDD_AMENDMENTS.json`
and has not changed the live GDD. Current explicit author direction governs this
correction. The finite source gate passes 47/47 selected suites and 813 Lua syntax
checks; see `validation/ENEMY_CLOSE_DEFENSE_20260928.md` and its checks receipt.

Native acceptance remains pending. Next: fully restart/install and maintain
crowbar pressure on a close rare enemy on gm_flatgrass; observe the warning,
counterattack and evasion, including device/skeleton visuals when encountered.
Preserve remaining native gates and local acceptance → Workshop parity → matching
VPS release order. Source publication only.

---

# Prior checkpoint — skeleton player animations

The author reports T-posing skeletons and expressly authorizes the source push.
From verified main `9d3c202`, the shared hostile resolver now uses stock GMod
player activity families/weapon holds for the skeleton model, with attack gestures
as overlays. Both model-swap constructors select idle immediately; Motion V2
drives player move_x/y from its existing kinematic movement. Preserve complete
player bases across flinches/death and avoid activity-alias cycle restarts.

The finite gate passes 15/15 selected regressions and 811 Lua syntax checks;
see `validation/SKELETON_ANIMATION_20260928.md` and its checks receipt.
Native appearance remains pending. Next: fully restart/install and observe an
event skeleton and fallen-player copy through idle, pursuit, attack and damage
on gm_flatgrass. Preserve existing gameplay, performance work and remaining
native gates; local acceptance → Workshop parity → matching VPS remains in force.

---

# Prior checkpoint — custom-system quantization

Shael reports good Steam Deck performance on renderer main `cdb85e6` and requests
further custom-system simplification. The finite pass replaces event-route text
signatures with a blocked/open mask, caches exact loot budgets by integer depth,
uses squared near-look cone comparisons before visibility traces, and prepares
projectile trails once per visible snapshot. Preserve authored formulas, dice,
movement, collision, enemy population, timing and the accepted renderer.

Live GDD 00 → 01 → 07 LOD-IMPL-001–004 governs; no authored tuning changes.
`validation/SYSTEM_QUANTIZATION_20260928.md` records 38/38 selected checks,
810 Lua syntax checks, exact-value/route/endpoint comparisons and bounded work
counts. Native performance improvement for this candidate is not measured.
Next: fully restart/install the verified source and play ordinary gm_flatgrass
through targeting/loot, projectile combat and Skeleton-blockade resolution.
Retain outstanding native gates and local acceptance → Workshop parity → matching
VPS; source publication only.

---

# Prior checkpoint — low-end renderer follow-up

The repeated Steam Deck slowdown report promotes a renderer follow-up from main
`c55a4a4aea77994e8c80725b621e0ef86f856e81`. Extend the existing bounded TexturedBox
cache with weak per-entity mesh/transform reuse, and extend generated geometry's
rear-plane rejection to known perspective side/top/bottom planes. Preserve live
dimensions/transforms, world-planar UVs, the 256-mesh ceiling, map/full-update
recovery, hidden false floors, materials, all game rules and current startup fixes.

Live GDD 00 -> 01 -> 07 LOD-IMPL-004 governs; no new tuning or design amendment.
`validation/LOW_END_RENDER_20260928.md` freezes scope, paired operation counts and
the finite selected integration gate: 32/32 passed plus 808 Lua syntax checks.
Native FPS/fan behavior remains unmeasured.
Next: install verified main, play ordinary gm_flatgrass through a full camera turn,
stairs and combat, and report smoothness/any missing geometry. Preserve outstanding
native gates and local acceptance -> Workshop parity -> matching VPS. Source only.

---

# Prior checkpoint — immediate staging campaign-failure repair

The author reports two immediate Campaign Failed resets while still in staging.
This repair extends main `b5a829355291fcae11e963d8891dd9441719b0e7`.
The final regression reproduces a matching failure against that parent: campaign
31676 reaches staging on layout 14, but its Skeleton occupies entry-apron cell
1:9:0. Native Initialize schedules removal; IsValid and later positive HP let
construction finish before the next tick reports the required hostile lost.

Skeleton placement now uses the existing EntrySafety spawn-cell authority.
Event construction rejects native entities marked for deletion and rechecks all
tracked resources before committing the complete plan. The same campaign and
event selection now use legal cell 16:16:1 on the same layout. Arrival protection,
real combat rewards and canonical failure on genuinely lost live resources stay
enforced; no new recurring service is added.

The exact-source gate passed 35/35 targeted checks and 807 Lua syntax checks.
Read `validation/STAGING_EVENT_SPAWN.md` for the failed-parent reproduction,
three-class native initialization, prolonged staging, deferred cleanup and
partial-creation evidence. Next: fully quit GMod, install verified main, then
start on `gm_flatgrass`, prepare in staging and deploy normally. The reported
session's full failure reason was not supplied; native acceptance remains open.
Source publication only; preserve music/low-end work and existing release gates.

---

# Prior checkpoint — fatal empty-map bootstrap recovery

The author reports an empty `gm_flatgrass` with
`event placement exhausted: skeleton_blockade: nil`. This repair extends main
`019d445b76573b3b9d5f77a4c3b7a2df8c63be0e`. With production progression safety,
Neil/Black Gate, Warden arena and arrival reservations loaded, campaign seed
31676 reproduces the failure: its first progression-safe layout has no legal
blockade site. Event rejection previously aborted the complete build before
staging could run.

RunManager now continues the existing deterministic layout stream on explicit
event-placement exhaustion, within the original shared 64-layout ceiling.
Event selection stays frozen; cleanup and all graph/native/route proofs remain
mandatory. Failed attempts cannot advance ecology or release players. Reported
callback, integrity and native creation failures do not authorize a retry.
The same failing seed reaches layout 14 with its original two selected events.

Read `validation/BOOTSTRAP_EVENT_RECOVERY.md` for finite startup/lifecycle
coverage and preserved reproduction evidence. Next: fully quit Garry's Mod,
install verified main and start the gamemode on `gm_flatgrass`; confirm staging,
portal deployment and the populated maze. Native acceptance remains open.
Preserve music/low-end work and local acceptance → Workshop → matching VPS.
This checkpoint authorizes source publication only.

---

# Prior checkpoint — Chill staging and gameplay-first music

The author requests staging's Chill/INTERLUDE arrangement and resource priority
for gameplay. This extends verified main `cdfcbb1ab8652109ba141c59b298fb03b68ae676`.
Live GDD 05/06/07 now records Chill staging, explicit opt-out, bounded on-demand
media caching, paced downloads and resource shedding. Existing block assignment,
pressure, pulse/quiet section and one-shot victory authorities remain in charge.

Fixed 16 KiB media objects, one HTTP request, a bounded verified disk cache and
local native playback replace uncontrolled URL streams. Disabled/zero-volume
clients suspend music service. Congestion postpones optional work; severe client
overload releases the score. Read `MUSIC_PERFORMANCE.md` for limits, legacy-host
migration and the finite native gate. Results are in `validation/MUSIC_PERFORMANCE.md`;
source checks do not establish native FPS, latency, memory, audio or router QoS.

Next: prepare hosted chunks offline, install the published source, start a new
campaign and run the compact native music/contention gate. No Workshop or VPS
release belongs to this checkpoint. Preserve prior low-end optimizations and
local acceptance → Workshop parity → matching VPS.

---

# Prior checkpoint — pulse-first music section direction

The author promotes section-aware music direction from main
`67cb7dbf7343d05cd52c3f429e33322a8fc30248`. Rhythmic class has primacy:
T1–T3/BOSS sustain a pulse, falling active pressure uses gentler pulsed material,
and T0/INTERLUDE sustain quiet. Offline import prepares bounded, editable cue
maps. The existing client mixer renews sections before inappropriate endings,
rotates entries, reuses a buffered pair, and preserves four channels/two transfers.
There is no gameplay-time waveform analysis. VICTORY and block-name logging retain
their existing one-shot/logical-block semantics. Server music still defaults Off.

Validation: all 287 registered suites have passing coverage on unchanged source;
the full matrix was 286/287 plus an isolated passing rerun of its one 600-second
campaign timeout. All 802 Lua files passed syntax checking. See
`validation/MUSIC_SECTIONS.md` for exact receipts, retained attempts and native limits.

Live GDD 05/07 pulse-first amendments were written and read back. See
`history/MS1_MUSIC_SECTION_DIRECTION.md` for authoring, compatibility, runtime limits and the
finite native gate. Legacy cue-less media needs a new offline-imported version;
active/offered plans stay frozen. Hosted media and native listening/performance
acceptance remain pending. The full canonical matrix now includes the new offline
classifier and section playback gates, alongside the existing music ingestion
and low-end regressions. Retain local acceptance → Workshop parity → matching VPS.

Next: provision/audition prepared tracks, install the published source, and run
the short native music gate. No Workshop publication or VPS deployment belongs
to this source checkpoint. Preserve the prior Steam Deck optimization and all
outstanding accepted-regression/native gates.

---

# Prior checkpoint — low-end PC / Steam Deck client optimization

The author's slowdown report promotes the planned low-end work. This checkpoint
extends main `3d60d6f730b56abbf3df5de68bb8d71002d44d96` with immutable container
palette/material caches, conservative rear-camera static-geometry rejection,
pass-local floor material reuse and an Options checkbox for the existing saved
Reduced Effects preference. Skeletons, events, loot, enemy population/AI,
geometry/collision, music defaults and all gameplay rules are unchanged.
The full gate also repairs a nil-target guard in the fallen-Hero damage wrapper
and missing native API doubles in an older protected-regression harness.

Read `validation/LOW_END_PC_20260928.md` for paired operation counts, cache/camera
safety cases and the exact-source native procedure. Three new low-end checks and
six retained music/options checks extend the complete canonical gate to 285
suites. Retain the initial 279/285 run (four timeouts and two repaired regressions);
the final complete run uses a 600-second per-suite headless allowance with no
reduced inputs or assertions. The immutable local/independent receipts, not old checkpoint
counts below, establish this candidate's aggregate result and published identity.
Publication requires both gates and an exact-parent non-forced main update.

Next is ordinary Steam Deck play on the installed source: the efficiency changes
are automatic; Reduced Effects is an optional saved choice in Options. Native
FPS/frame time and visual acceptance are not measured by headless tests. Preserve
all previous native gates and local acceptance → Workshop parity → matching VPS.
No Workshop/VPS deployment belongs to this source checkpoint. Historical sections
below remain evidence, not instructions to repeat completed work.

---

# Current checkpoint — live GDD reconciliation complete; native acceptance next

The author's express approval to amend the GDD closes the Big Loot, Big Event,
Music and Big Skeleton synchronization backlog against gameplay main
`2847f416b8d152a24ac4d282cc012e73ddb131d7`. Recent SPOT, audit, cleanup and
equipment/faction repairs are represented; obsolete deferrals and music
implementation-pending/default-On statements are corrected. The newer modular
boss design remains intact and is not claimed implemented by this checkpoint.

Read live GDD 00 → 01 → the relevant normalized rule. Big Loot's active catalog
is now in 05; HUMAN retains all 113 exact authored identity rows. Exact duplicate
passages were consolidated into canonical references to resolve apparent size
pressure, with every retained rule verified. All ten tab texts match the expected
edit, and native date elements and tab topology are preserved.

See `validation/GDD_SYNC_20260928.md` and its JSON receipt. Earlier failed-write
notes below are historical; do not replay their old insertion payloads. This
checkpoint changes documentation only. Gameplay/source-test evidence and all
pending native acceptance remain unchanged. Next: the finite Big Skeleton local
gate below, then existing native gates; retain local acceptance → Workshop parity
→ matching VPS. No Workshop publication or VPS deployment occurred.

---

# Prior checkpoint — Big Skeleton source; native acceptance next

Author-directed design and implementation extends verified main
`f0b7a66d0e87c18ad18b45a6449b613b7f8ee11d`. Skeleton Blockade remains registered
after Bribe removal; a separate 65% priority draw and two-dungeon drought cap
now make it frequent without changing exact 1d4 density or the rare slot.
Accepted Hero and human-Soldier deaths independently create hostile AI copies
of their current builds, using shared combat and lifecycle authorities.

See `BIG_SKELETON_UPDATE.md` for behavior, explicit AI-action scope and the
finite local gate. `validation/BIG_SKELETON_UPDATE.md` records 52/52 targeted
regressions, 798 Lua syntax checks, final lifetime hardening checks, frequency
samples and retained logs. Native appearance/combat/co-op acceptance is pending.
Google again rejected the guarded GDD write; final proposed 05/06/07 amendments
are preserved in `validation/BIG_SKELETON_GDD_AMENDMENTS.json`. Earlier GDD
synchronization debt and native gates remain independent.

Next action on exact local source, `gm_flatgrass`:
`lod_developer_mode 1; lod_event_preview_generate skeleton_blockade`.
Then follow the short fallen-player test in the implementation note. Preserve
local acceptance → Workshop parity → matching VPS; no deployment is claimed.
Evidence: `console_latest.txt` + `rpg_summary_latest.txt`.

---

# Prior checkpoint — Music System source; streaming defaults OFF

The author-promoted Music System extends verified main
`c5ece210be12077c321264ad4abb81821fe8d9a5`. `lod_music_enabled 0`
is the default; only the server may permit streams. Existing player Music Off
also wins. Live GDD 00→01→05/06/07 and the Options anchor govern six roles,
optional interlude, inheritance/universal themes, sets, frozen floor plans,
spatial/pressure mixing, accepted-victory continuity and private Die Logger starts.

See `MUSIC_SYSTEM.md` for implementation, bounded HTTPS ingestion/upload, original
separate default assets, operator commands and the finite native gate. Source
verification results are recorded in `validation/MUSIC_SYSTEM.md`. Native audio,
UI, network and performance acceptance remain pending; no public HTTPS origin,
Workshop update or VPS deployment is claimed. The required default-Off GDD edit
and provisional tuning write failed with HTTP 400 FAILED_PRECONDITION; fresh
readback is unchanged. Exact amendments: `validation/MUSIC_GDD_AMENDMENTS.json`.
Earlier Big Loot/Event synchronization debt remains independent.

Next: provision/audition the default profile on an operator-controlled HTTPS
origin, install the exact source locally, start a new campaign and run the short
native music gate. Maintain local acceptance → Workshop parity → matching VPS.

---

# Current checkpoint — Big Event System source validated; native acceptance next

The author-promoted `briefs/EVENT_SYSTEM_UPDATE.md` extends verified main
`1685774415ea8bbd82abf931999a29ae7ba25f10`. Frozen active baseline8, additions20,
production total28 (3.5×); removed Bribe stays removed. Exact1d4 density, shared
rare fourth slot, existing progression proofs and source-only publication remain.

See `EVENT_SYSTEM_EXPANSION.md` for catalog, shared settlement, family/identity
ecology, successful-build campaign memory, topology preferences and a compact
native procedure. All **274/274 suites and 784 Lua syntax files pass**, including
six new gates; the source remained unchanged throughout the full matrix. See
`validation/BIG_EVENT_UPDATE.md` and its complete receipt/evidence archive.
Native Source physics/input/presentation/network/co-op acceptance remains pending.

Live GDD00→01→05/06/07/90 read successfully. Google rejected the revision-guarded
write with `FAILED_PRECONDITION`; fresh readback confirmed no mutation. Exact
six-tab changes remain in `validation/big_event/gdd_amendments.json`. This is an
explicit synchronization blocker, not a completed GDD update. Prior Big Loot
amendments remain independently outstanding. No Workshop/VPS action.

Next after verified source publication: exact-build local `gm_flatgrass` event
acceptance, retaining earlier accepted behavior and pending gates. Capture
`console_latest.txt` + `rpg_summary_latest.txt`. Apply the pending live GDD changes
when editing is restored; unrelated deferred roadmap work is not included.

---

# Current checkpoint — Big Loot source validated; live GDD synchronization blocked

Author-promoted Big Loot extends verified baseline
`fc166870633db5f277165d9c33ae00d82feaa81a`. Final gameplay/test commit:
`4f9ec7928f4a44107066da3095937655db806941`. This closeout adds documentation/evidence only; the delivery
response supplies the fetched, verified final remote HEAD.

Frozen baseline **45**, added **113**, total **158 (3.5111×)** meaningful identities.
Stable effect packages, campaign motifs/history, contextual/topological rewards,
late optional treasure, inventory pressure and immutable source receipts extend
existing authorities. Native weapon restoration and atomic sell/fuse are repaired.
See `BIG_LOOT_CATALOG.md`, `BIG_LOOT_ECOLOGY.md` and
`validation/BIG_LOOT_UPDATE.md` for architecture, constants and exact evidence.

Complete finite matrix: **268/268**, **774 Lua syntax files**, unchanged source.
32×20 campaigns with two owners expose all 113 additions; mean 106.516 / minimum 100
per owner-campaign, 92.75% fewer immediate repeats and 35.94% less adjacent-level
overlap versus history-disabled control. All 15,422 support nodes preserved.
Sampling uses empty bags/native doubles; native gameplay and balance are unaccepted.

**Outstanding:** Google Docs rejects live GDD edits with HTTP 400
`FAILED_PRECONDITION`; fresh reads confirm no mutation. Exact seven-tab amendments
and 113 authored rows are saved in `validation/big_loot/gdd_amendments.json`.
Apply/read back after editing is restored. No live synchronization or complete
end-to-end closure is claimed. Native `gm_flatgrass` pickup/equipment/economy,
lifecycle and co-op acceptance follows verified publication, preserving all prior
acceptance constraints. No Workshop/VPS action. Earlier Big Loot deferrals are
superseded by this explicit author request; unrelated roadmap work stays deferred.

---

# Current checkpoint — stalled cleanup reconstructed; native acceptance next

September 27 author-requested recovery extends verified main
`aa102cc31951d34937ebaa106314cfcfdb855a2f` without repeating the prior systems audit.
See `validation/CLEANUP_RECOVERY_20260927.md` for repaired loot/campaign/staging,
party scaling, jump/death lifecycle, warp diagnostics and isolated Bribe fixtures.
The complete gate retains all 262 earlier suites and adds two production tests
(264 entries; 767 Lua syntax files). Final pass/tree/publication evidence belongs
to the delivery receipt, not a source-preparation assumption here.

Next after verified publication: exact-build local `gm_flatgrass` acceptance.
Preserve existing regressions and local acceptance -> Workshop parity -> matching
VPS. No deployment or deferred-roadmap work is included. Older headers below are
historical where this checkpoint supersedes them.

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

# Author-reported stair ceiling repair — native acceptance next

### Current author-requested spot repair — Soldier / Hero and Reckless damage (September 27, 2026)

The standing-stair repair remains preserved. The new unnumbered damage repair follows current combat roles rather than engine player class and respects attacker-only Reckless in native damage and real attack geometry. See `docs/validation/FACTION_RECKLESS_DAMAGE.md` and the external publication receipt for exact child/tree and headless results. Native acceptance remains pending; no Workshop/VPS action. This is not a new scheduled SPOT-18 or a restart of the deferred roadmap.


September 27: the rear crossover lip now retracts 16 units, sharing its 48-unit
width with the rail opening. Upright stair-step clearance increases from 80 to
96 units; the existing standing hull, solid floors, treads and no-jump upper
circulation remain. See validation/STAIR_HEADROOM_20260927.md for the failed
baseline, finite regression and native limits. Final aggregate results and exact
publication identity belong to the delivery receipt.

After verified publication, update the local install and walk a fresh stair up,
down and around its upper landing without crouching or jumping. This repair does
not accept SPOT-17 or any earlier native debt, start deferred roadmap work, or
authorize Workshop/VPS deployment. Earlier headers below remain historical.

---

# SPOT-17 source complete — spot queue complete; native acceptance next

Human Soldiers now use the AI Soldier's configured base speed (currently 140),
without ordinary sprint or grounded jump. Existing class/DEX/status/Haste and
directional effects remain; granted airborne movement feats remain off-commitment.
An accepted rifle attack roots voluntary movement through warning, all rounds and
actual cadence-adjusted recovery. Gravity/forced motion remain; current-life,
weapon, role and dungeon cancellation cannot carry a root into another body.
Dodge cannot reuse a pre-commitment motion sample. Heroes and AI retain their rules.

Live GDD 06/07 SPOT-17 delegated movement/tuning supplements were written and read
back before production changes. The existing source/attack/movement/control/Dodge
and client projection seams are reused. No recurring timer or movement owner added.
See validation/SPOT_17_MOVEMENT_GATE.md. The frozen contract retains all 93 earlier
selections plus two focused production tests (95 selected; 756 Lua syntax files).
Final local/independent results and publication identity belong to the external
receipt, not a pre-publication assumption. Native Source prediction/physics,
cooperative enemy readability and earlier acceptance debts remain open.

SPOT01–17 now have source implementations. After verified publication, the next
action is exact-build local gm_flatgrass acceptance, particularly Soldier movement,
rifle commitment and F3-to-Hero recovery. Use console_latest.txt and
rpg_summary_latest.txt plus a short observation; detailed session only for disputed
timing. No dedicated Razor retest. Preserve all previous approved work. No Workshop
or VPS action is authorized; retain local acceptance -> Workshop parity -> matching
VPS. Deferred roadmap work is not automatically authorized by completing this queue.
Earlier headers below are historical where superseded by this one.

---

# SPOT-16 source complete — SPOT-17 next after verified publication

Human Soldiers now receive an incarnation-bound Pulse Rifle with INFINITE ammo,
committed three-round baseline bursts and preserved burst/rate/aim authorities.
Zero clip/reserve works without cartridges, reload or a refill service. Stale
body/role/dungeon/weapon work cancels; Hero finite ammo and SPOT-15 lifecycle remain.
No Soldier movement, jumping or attack-rooting changes are included.

Live GDD 06/07 already contained the recovered SPOT-16 rules; no duplicate amendment.
Focused attempt 07 passes 988 server + 32 client assertions. The final frozen-source
contract is 93 selected suites (all prior 90 plus two focused suites and the existing
burst-cleanup regression), with 753 Lua syntax checks. Final local/independent
results and publication identity are supplied by the external delivery receipt.
See validation/SPOT_16_SOLDIER_RIFLE.md for honest attempt history and native limits.

After verified publication, implement only SPOT-17: Soldier committed-attack rooting
and movement restrictions approximating AI Soldiers. Reconcile the live GDD before
code; preserve readable, consistent enemies for human Heroes. No deferred roadmap,
Workshop publication or VPS restart is authorized. Preserve SPOT01–16, Float On at
1 Magic/s, B28/B29, approved Crate and P1–P4. Earlier sequencing below is historical
where superseded by this header.

---

# SPOT-15 source complete — SPOT-16 next

The author-directed Soldier F3 team menu is implemented. Live/waiting Soldiers can
return to the Hero queue or spectate only; the saved Hero, genuine death delay,
server authority and ordinary Hero choices are preserved. The actual revived Hero
spawn now uses the existing slot authority. Pre-closeout: 90/90 selected suites,
425 focused assertions and 751 Lua syntax checks. Final frozen-source and independent
publication facts belong to the delivery receipt. Native input/co-op/font/timing
acceptance remains open. See validation/SPOT_15_SOLDIER_MENU.md.

Next, implement only SPOT-16: human Soldier pulse rifle, three-round bursts and
infinite ammo in place of the SMG. Reconcile current main and relevant GDD before
code. Do not batch SPOT-17 movement restrictions or deferred roadmap work. Preserve
SPOT01–15, B28/B29, approved Crate, P1–P4 and local acceptance -> Workshop -> VPS.
No Workshop/VPS action authorized. Earlier sequencing below is historical where
superseded by this header.

---

# Active roadmap — author-directed spot updates

## Current checkpoint — SPOT-14 Time Management

Actual gameplay parent: `3b4df50fe001dd0dc7e2d7df9e3339a6bcceff13`.
Time Management is an ordinary, one-rank INT 17 cooperative-Hero feat. Living,
completed deployed holders add their positive effective INT modifier in minutes,
once per identity. The existing deadline gains or loses only the difference in
current party allowance. Death, disconnect and Soldier/spectator transitions remove
allowance; return restores it only before expiry. Hourglass time remains independent.
Same-dungeon internal build holds retain established non-growing allowance without
refunding elapsed time; real lifecycle losses still win. Old expiry precedes gains,
rescue and Hourglass debit. Rescue/new campaign reset to the ordinary paused clock.

[Implementation, raw attempts and limits](validation/SPOT_14_TIME_MANAGEMENT.md):
focused attempt 08 passed **258 production assertions**. The finite final contract is
**87 selected suites**, retaining all 85 SPOT13 selections and adding ordinary-clock
and SPOT14 integration tests. Exact final local/independent receipts and non-forced
child/tree/run belong in the external delivery receipt, not an unrun pre-publication
claim here. Live GDD 04/05/06/07, canonical manual and both generated readers align.
Native timing, co-op/rejoin, appearance/font and balance acceptance remain open.

**Next single bullet after verified publication: SPOT-15 — human Soldiers may open
the team menu with F3 at any time to return to the Hero queue or spectate, with a
visible hint.** Reconcile current role/queue/control/UI authority before code. Do not
implement SPOT16/17 or deferred roadmap in that checkpoint. Preserve SPOT01-14,
Float On at 1 Magic/s, B28/B29, Crate/P1-P4 and local acceptance -> Workshop parity
-> matching VPS. No Workshop/VPS operation is authorized.

## Previous checkpoint — SPOT-13 unread-update markers

Actual gameplay parent: `795dd444144e4e733dea58e56b4302bcb648f1ba`.
Character, Spellbook and Equipment now mark meaningful unseen updates with a
static exclamation above their existing navigation buttons. Inventory is the
bag inside Equipment, not a new page. First sync is quiet; only the exact updated
page's post-child paint acknowledges it. Sibling/loading/blocked/stale pages and
drag-deferred inventory cannot clear unseen content. Ordered snapshot envelopes
reject stale data; ordinary resync/floor changes preserve unread state, while
campaign/profile/life changes retire it. Routine resources remain quiet.

[Implementation, attempts and limits](validation/SPOT_13_UNREAD.md): final focused
production test **317 assertions passed**. The finite aggregate contract is **85
selected suites**, retaining all 83 SPOT-12 selections; final local/independent
results and verified non-forced child/tree/run are in the external delivery
receipt, not assumed from this pre-publication source document. Live GDD 06/07,
canonical manual and both generated readers align. Failed attempts remain raw.
Native rendering/font/network/co-op and full campaign acceptance remain open.

**Next single bullet after verified publication: SPOT-14 — Time Management,
prerequisite INT 17.** Reconcile exact time units, presence, stacking and
join/leave anti-exploit rules in the live GDD before dependent code. No SPOT14
implementation or deferred roadmap work belongs in SPOT13. Preserve SPOT01-12,
Float On at 1 Magic/s, B28/B29, Crate/P1-P4 and local acceptance -> Workshop parity
-> matching VPS. No Workshop/VPS operation is authorized.

## Previous checkpoint — SPOT-12 Spellbook availability surfaces

Actual gameplay parent: `8b2e936f83f9740f40082fd0c3d04dc3feafde01`.
Cards now tint their entire backdrop and border from the existing blue/red/gold/
muted availability state. Dark selection outlines and matching hover accents do
not mask warnings. Literal labels, costs, descriptions, Magic authority and all
configuration/casting rules remain; long descriptions use an existing small-font
fallback. Live GDD 06/07 and both canonical manual readers align.

[Evidence and limits](validation/SPOT_12_SPELLBOOK.md): **83/83 selected pre-closeout
suites, 1441 new focused assertions, 745 Lua syntax checks**, unchanged source;
minimum computed card-text contrast 5.119:1. All 79 SPOT-11 selections retained.
Final frozen local/independent hashes and non-forced main publication are in the
delivery receipt. The first focused width failure and interrupted 57-suite gate
remain honest incomplete/failed evidence. Native appearance/co-op acceptance and
the full campaign matrix are not claimed.

**Next single bullet: SPOT-13 — unread-update markers for Spellbook, Character
Sheet and Inventory, clearing only the corresponding viewed update.** Reconcile
live notification/snapshot ownership before code. Do not start SPOT14 or deferred
roadmap work here. Preserve Float On at 1 Magic/s, SPOT01-11, B28/B29, Crate/P1-P4
and local acceptance -> Workshop parity -> matching VPS. No deployment authorized.

## Previous checkpoint — SPOT-11 four-choice ordinary feat drafts

Actual gameplay parent: `85db2ed5ce287e7dbd96197676af4799922a6bf6`.
New ordinary hands target four distinct eligible offers, legal neutral fallbacks
only. Genuine smaller pools remain smaller; zero eligible choices are an explicit
resolved no-award slot, not a fabricated perk or staging soft-lock. Existing valid
stored hands, including legacy trios, retain their IDs/order/seed/result. Human
heroes choose once; AI/human Soldiers automatically consider the entire hand.
Capstone trios and Magic choices are unchanged. Four-card sheets use responsive
2x2 or single-column layouts. Live rules and both manual readers align.

[Evidence and limits](validation/SPOT_11_DRAFTS.md): pre-closeout **79/79 selected
suites, 1055 new focused assertions, 744 Lua syntax checks**, unchanged source.
All 72 D-J selections are retained. Final frozen local/independent identity and
verified non-forced publication belong in the delivery receipt. Earlier 71/72,
78/79, interrupted launches and focused fixture failures are preserved.
Native acceptance and the full campaign matrix are not claimed.

**Next single bullet: SPOT-12 — Spellbook card/backdrop availability colors.**
Reconcile live UI/accessibility law before code; do not start SPOT14 or deferred
roadmap work inside this checkpoint. Preserve Float On at 1 Magic/s and all
SPOT01-10, B28/B29, accepted Crate appearance, P1-P4 and release gates.
No Workshop or VPS operation is authorized.

## Previous checkpoint — SPOT-10 D–J approved and implemented

From actual main parent `7e2495ccfba3009f8190bd619ea229a8e65da094`.
Shael approved D–J, amending Float On to **1 Magic/second** for up to six seconds.
Arc Recovery 11; Feedback Loop 2/continuation, cap12; Recovery ceilings22/44/66%
at base rates1/1.5/2%MaxHP/s; ammo refill22/44/66%faster at unchanged floors;
Presence22/44/66%; aura fixed3seconds. Existing IDs/prerequisites, rejected A and
prior B/C/Mana Spring remain. Live GDD03/04/exact HUMAN and cards/manual align.

[Implementation and limits](validation/SPOT_10_SECOND_PASS_IMPLEMENTED.md):
**72/72 selected suites, 765 focused D–J assertions, 742 Lua syntax checks**,
unchanged source. All earlier64 selections retained. These are source gates,
not a full campaign matrix or native balance/control/co-op acceptance. Earlier
63/64 and71/72 attempts remain in the provenance record. Final frozen local/
independent identity and verified publication belong in the external receipt.

**Next independent bullet: SPOT-11 — four-choice feat drafts.** Reconcile live
draft law, eligibility/small pools, stored pending hands, authoritative one-choice
commit and UI before implementing. Do not begin SPOT12/SPOT14 or deferred work
inside this checkpoint. Preserve native/release gates; no Workshop/VPS operation.

## Previous checkpoint — SPOT-10 first approved corrections and second-pass review

From actual main parent `0b8321344737d11547f323c993b279de7c400d4f`.
A is rejected; its explosion ladder stays. B (fixed 3-second Mind Over Matter),
C (25% Frugal discount with existing map floor/Haste composition) and the author's
Mana Spring revision (flat 22% faster permitted passive regeneration) are implemented.
Live GDD 04/exact HUMAN rules, cards and both manual readers are aligned.

[Evidence](validation/SPOT_10_APPROVED.md): first local aggregate **64/64 selected
suites, 129 focused assertions, 741 Lua syntax checks**, unchanged source; retained
SPOT09 regressions, not the full campaign matrix. Final frozen local/independent
identity and verified publication belong in the delivery receipt. Native balance,
resource feel and co-op acceptance remain open.

**Next: author decisions on [second-pass proposals D–J](validation/SPOT_10_SECOND_PASS.md).**
These focus low-payoff effects, not relaxed prerequisite ladders; no comprehensive
personal pick-rate telemetry is claimed. D–J are not approved or implemented.
Do not fold SPOT11, SPOT14 or the deferred roadmap into this checkpoint.
Preserve all earlier native/release gates; no Workshop/VPS action.

## Previous checkpoint — SPOT-09 Damsel's Revenge

From actual main parent `9b89fdd2cfb1eed7d4d9cb1e172b5d02f44a2d86`.
One finite consumable arms the stationary jailed Damsel with a frozen procedural
Pistol, SMG or Pulse Rifle. Shared source-bound payment, canonical physical dice,
exact real-Gordon targeting, visible jail firing slit, encounter lifetime and
normal rescue authorize one owner-only at-feet gun pickup during existing victory.
No Hero ability/feat inheritance, Hector fire, new reward authority or free ammo.

The [finite gate](validation/SPOT_09_REVENGE_GATE.md) passes **477 focused numbered
assertions plus 512 seeded reward cases, 59/59 selected suites and 740 Lua syntax
checks**, unchanged source. See [implementation and limits](validation/SPOT_09_REVENGE.md)
and [preserved attempts](validation/SPOT_09_ATTEMPTS.txt). The first aggregate was
58/59 due to escaped-HTML test matching; that failure remains a failure. Final
frozen local/independent hashes and publication identity belong in the delivery
receipt. Native gun/port/animation/audio/pickup/co-op/performance acceptance remains
open; this is not a full campaign matrix. Manual and both renderings match.

Next single bullet: **SPOT-10 — evidence-backed feat proposals only**. Audit current
live design and implementation, identify obsolete/weak/redundant feats and present
specific changes with rationale and tests for Shael's approval. Do not implement
any rebalance without explicit approval by proposal. Do not fold SPOT-11 four-choice
drafts or SPOT-14 Time Management into this audit. Preserve SPOT-01–09, B28/B29,
accepted Crate appearance and P1–P4. No Workshop or VPS actions.

## Previous checkpoint — SPOT-08 Gordon arena turrets

From actual main parent `35c43bc8bac86e5ea108b9f96e9d5ab6a94bf542`.
Cumulative ordinary Sentry corner turrets at D5/10/15/20, capped at four with
ordinary monster progression thereafter. Separately seeded corners, one safe
admission attempt per slot, no delayed fallback/replacement/respawn. Exact-cell
native hull/support and stair/gallery checks preserve arrival and routes. Shared
96-hostile, 64-roamer, 64-projectile and 16-Gordon-hazard ceilings remain.

Production EnemyRoster owns fixed warned physical fire, bounded captured Hero
lives and guarded native damage. Exact owner/run/life retirement prevents stale
shots across wipes, rebuilds, co-op replacement and Gordon-to-Hector handoff.
Native body removal occurs outside the lethal stack, explicitly before Hector's
reveal. No SPOT-06/07, boss progression, reward or feat-balance changes.

The [predefined finite gate](validation/SPOT_08_TURRETS_GATE.md) first passed
**250 focused assertions, 52/52 selected suites and 736 Lua syntax checks** on
unchanged source. See [implementation and limits](validation/SPOT_08_TURRETS.md)
and [preserved failures](validation/SPOT_08_ATTEMPTS.txt). Final frozen local and
independent hashes, published child/parent/tree and run ID are in the delivery
receipt. Manual and renderings match. This is not full campaign-matrix or native
collision/visual/audio/co-op/performance acceptance. No Workshop/VPS actions.

Historical next action at SPOT-08 close-out: **SPOT-09 — Damsel's Revenge consumable**. Read the exact
queue request and reconcile its item grant/use, jailed Damsel gun/combat, Gordon
ownership, co-op, rescue drop and cleanup contract in the live GDD before code.
Do not fold existing-feat rebalances into it. Preserve SPOT-01–08 and B28/B29.

## Previous checkpoint — SPOT-07 Fake Gordon tells

From actual main parent `c9ddf8cb7d1952ce831d2fdb361c4092ebb85f7d`.
Only a living deployed Hero with positive canonical Wisdom receives private,
short-lived fake recognition within half the Wisdom bonus in squares. Fractional
3D distance and clear sight govern wink/tongue/tint and shared-stun-bound recoil.
Global fake-name/ordinal labels are removed; optional fart is omitted. No shared
control/damage/HP change or extension of SPOT-06's fixed follow-up is introduced.

The [predefined finite gate](validation/SPOT_07_TELLS_GATE.md) first passed
**130 focused production assertions, 50/50 selected suites and 734 Lua syntax
checks**, unchanged source. Final frozen-tree local/independent source checks,
publication SHA/parent/tree and run ID belong in the delivery receipt. Canonical
manual and both renderings are synchronized. See [validation](validation/SPOT_07_TELLS.md)
and preserved attempt provenance; this is not full campaign-matrix or native
visual/co-op/performance acceptance. No Workshop/VPS actions.

Next single development bullet: **SPOT-08 — Gordon arena turrets**. Reconcile the
author's every-five-dungeon-level scaling/corner occupancy in the live GDD before
code. Do not begin SPOT-09 or existing-feat rebalances in that checkpoint. Preserve
SPOT-01–07, B28/B29, accepted Crate appearance, P1–P4 and all native/release gates.

## Previous checkpoint — SPOT-06 Gordon phase one

Recovered from the stalled SPOT-06 thread on September 26, 2026, from exact
published parent `664762a55d096c628ed5a2faff6da6c97c16cf03`, tree
`9faba937d888b33079719aa9b20d719fc01fbbd7`. A full tracked-file source snapshot
and original Git commit were verified before editing. The stalled thread's live
GDD 05/07 candidate design was already present and is preserved.

Phase one now owns a fixed 1.2-second first-effective-visible-hit opportunity,
never refreshed and bounded by reveal+4.0 seconds. Released ordnance keeps its
fuse; unreleased shots cancel. The existing Warden service enforces deadlines
outside stunned AI wrappers. Invisible physical travel, fixed .45-second
arrival/departure cues, displacement rewarning and the .65-second ordinary attack
warning replace ambiguous disappearance. Short contextual taunts share a
6-second encounter cooldown and require ordinary attack appearances between them.
Shared controls and all later phases/progression remain authoritative.

The finite [gate](validation/SPOT_06_GORDON_GATE.md) was defined before code.
Local source validation: **116/116 focused production assertions, 47/47 selected
suites and 733 Lua-file syntax checks**; no source mutation during the gate.
The exact frozen candidate is independently gated before publication; published
parent/tree/SHA and the independent run belong in the delivery receipt, not a
self-referential source-file hash. See [validation](validation/SPOT_06_GORDON.md)
for attempts, limits and the native checklist. This is not a full campaign matrix
or native timing, rendering, audio, collision or cooperative acceptance.

Next single development bullet: **SPOT-07 — Fake Gordon tells**. Do not fold
SPOT-08 turrets, SPOT-09 Damsel's Revenge or existing-feat rebalances into it.
No Workshop/VPS operation or native force-spawn test is part of SPOT-06.

## Previous checkpoint — SPOT-05 canonical Die Logger audit

The September 25 author-directed [spot queue](briefs/SPOT_UPDATES.md) precedes the
scheduled roadmap. One bullet equals one independently validated, non-forced
push. High-level design authority is delegated; existing-feat rebalances remain
approval-gated. SPOT-05 changes presentation/event reporting, not gameplay balance.

The canonical server stream now removes routine passive Magic/full-cap noise,
restores omitted defense/status/duration/recovery/Morale/HP-growth dice and
meaningful outcomes, and uses one event serial for the union of combat
participants and eligible nearby listeners. Private progression remains private.
Life observers bind exact Hero/run ownership; human Soldiers do not display the
dormant Hero name. Both client views retain identical semantic records and order,
with bounded history and ordered long-dice parts. The GDD's explicit passive-Magic
exception and the canonical manual are reconciled.

Final local evidence: **76/76 focused assertions, 38/38 selected suites,
732 Lua-file syntax**, including manual content/transport and unchanged source
during the gate. Its frozen-tree independent result and published child SHA
belong to the delivery receipt. See [SPOT-05 validation](validation/SPOT_05_DIE_LOGGER.md), the stored
receipt and preserved initial attempts. This is not a full campaign-matrix pass
or native rendering/multiplayer acceptance. B29 uses its recorded-layout runtime
mode; the extra 20-seed exposure sweep is not claimed.

SPOT-04 audio remains implemented and native-unaccepted. Its historical gate is
227 passing suites, one unchanged-parent Color-fixture failure and two omitted
campaign suites, not a full 230-suite pass. Fresh SPOT-05 regressions pass
SPOT-04 74/74, Razor 55/55 and Climber 44/44; the separate SPOT-01 50-check result
is inherited from SPOT-04. Earlier validation records are not rewritten.

Shael's one controlled Razor proves only that instance's visibility/basic combat.
Its Occupation/60-roamer upload was developer-dense, not natural release exposure.
**No dedicated Razor retest or natural sighting is prerequisite.** Collect natural
sightings opportunistically; keep the documented native limits and provenance.

## Existing release gates — unchanged

Preserve B28 physical-query repairs, B29 safe arrival/graduated opening,
author-approved Crate visuals, and completed P1–P4 optimization/evidence.
B29's historical 42 selected headless passes remain distinct from the fresh
integration results recorded above and from native acceptance. Its safe-arrival,
controlled-departure and inhabited-exploration native checks remain open.

The established sequence remains focused fatal-crash/game-ending-bug repairs,
local playtest/acceptance of the exact candidate, Steam Workshop item 3791535712
publication with package/source parity, then matching VPS deployment with backup,
rollback and service/listing/connectivity checks. This commit does not publish
the Workshop or change/restart the VPS. Obtain local evidence before those gates.

## Scheduled work — unchanged

| Order | Deferred work | Preserved scope |
| --- | --- | --- |
| 1 | Low-End PC Optimization, September 28–October 4, 2026 | Preserve P1–P4; resume measured active-scan profiling. Native dense frame-time/texture-residency acceptance remains pending. |
| 2 | [Big Loot](briefs/BIG_LOOT_UPDATE.md) | Existing meaningful baseline/approximately 3.5× target; preserve inventory, persistence, sell/fuse and wallet transactions. |
| 3 | [Event System](briefs/EVENT_SYSTEM_UPDATE.md) | Existing meaningful baseline/approximately 3.5× target; preserve exactly non-exploding 1d4 count, deterministic ownership, placement and solvability. |
| 4 | Comprehensive systems integration and emergence audit | Generation through encounters, combat/status, equipment/loot, events/rewards, progression/lifecycle/UI; deterministic, transaction and interaction contracts. |

## Checkpoint practice and preserved history

Read AGENTS → this current section → active brief; live GDD 00 → 01 → relevant
subsystem rules only. State the finite scope, implement at the existing authority,
run targeted checks and the available applicable integration gate, and distinguish
fresh, inherited and unavailable validation. Normally the canonical gate is
`python3 tools/test_checkpoint_g_integration.py`. Never substitute a headless pass
for native acceptance. Update player guidance, live GDD, evidence and handoff;
verify pushed source hashes and preserve newer/uncommitted work without force.

The entire previous development plan, including all historical acceptance records,
Crate constraints, detailed roadmap and checkpoint policies, is retained byte for
byte as [the B29 plan archive](history/DEVELOPMENT_PLAN_B29_20f6ecc.md). Only its
old active-queue precedence is superseded by the new author request. Historical
relative paths in that verbatim archive retain their original `docs/` context.

