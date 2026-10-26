assert(SERVER)
local D='legend_of_deborah/'
local spec=assert(util.JSONToTable(file.Read(D..'bench_advance_query_arm.json','DATA')))
local E=assert(LOD.EnemyRoster);local q=assert(E.CanTargetFromHere);local tick=assert(E.Tick)
local qi,ti=debug.getinfo(q,'S'),debug.getinfo(tick,'S')
assert(qi.linedefined==spec.query_line and ti.linedefined==spec.tick_line)
assert(string.find(qi.source,'sv_enemy_roster.lua',1,true) and string.find(ti.source,'sv_enemy_roster.lua',1,true))
local source=assert(file.Read(spec.path,'GAME')or file.Read(qi.source:sub(2),'GAME'));assert(util.SHA256(source)==spec.sha256)
local function up(fn,name)
 for i=1,40 do local n,v=debug.getupvalue(fn,i);if not n then return nil end;if n==name then return v end end
end
local fast=up(q,'queryTraceNative')==true and type(up(q,'tickGeometryQueryToken'))=='table' and up(tick,'tickCanTargetFromHere')==q
if spec.variant=='candidate' then assert(fast,'Native trace/provider guard not active')end
local A=LOD.RuntimeAudit;assert(not(A and A.CPUProfile) and not LOD.BenchQueryProfile and not LOD.BenchBeforeAI)
local ids={};local active,advancing=0,0;local now=CurTime()
for e in pairs(E.Active)do
 if IsValid(e)and not e.LODDead then
  active=active+1;local id=e.LODArchetypeId;ids[id]=(ids[id]or 0)+1;local d=E.Definitions[id]
  if d and not d.stationary and d.kind~='beam' then
   local flags={{'link','LODLinkAdvanceUntil'},{'edict','LODEdictAdvanceUntil'},{'companion','LODCompanionAdvanceUntil'},{'discipline','LODDisciplineAdvanceUntil'},{'crossfire','LODCrossfireAdvanceUntil'},{'resource','LODResourceAdvanceUntil'},{'spacing','LODSpacingAdvanceUntil'},{'condition','LODConditionAdvanceUntil'},{'mobile','LODMobileAdvanceUntil'},{'tactical','LODTacticalAdvanceUntil'},{'melee','LODMeleeAdvanceUntil'},{'trap','LODTrapAdvanceUntil'}}
   local yes=id=='razor'and now<(e.LODRazorApproachUntil or 0)
   for _,v in ipairs(flags)do if d[v[1]]and now<(e[v[2]]or 0)then yes=true end end
   if yes then advancing=advancing+1 end
  end
 end
end
file.Write(D..'bench_advance_query_'..spec.phase..'.json',util.TableToJSON({passed=true,phase=spec.phase,variant=spec.variant,sha=spec.sha,actual_sha256=util.SHA256(source),query_line=qi.linedefined,tick_line=ti.linedefined,native_guard_active=fast,profiler_absent=true,roster_alive=active,archetypes=ids,advancing_snapshot=advancing,scope='Read-only source/function/upvalue-provider proof and boundary state snapshot. No query/body wrappers, timers, per-call counters or gameplay mutation. Snapshot is not frequency/cost evidence.'},true))
