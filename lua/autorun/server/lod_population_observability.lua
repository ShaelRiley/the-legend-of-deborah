if CLIENT then return end
LOD=LOD or {}
LOD.PopulationObservability=LOD.PopulationObservability or {}
local A=LOD.PopulationObservability
A.Version="b29-entry-safety"
A.Records=A.Records or {}
local watched={
    "gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua",
    "gamemodes/legend_of_deborah/entities/entities/lod_hostile/cl_init.lua",
    "gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua",
    "gamemodes/legend_of_deborah/entities/entities/lod_static_box/shared.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_textured_box.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_batch.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_ui_theme.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_combat_roll_feed_semantics.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sh_runtime_audit.lua",
    "gamemodes/legend_of_deborah/gamemode/cl_init.lua",
    "gamemodes/legend_of_deborah/gamemode/init.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/cl_entry_safety.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sh_config.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_climber.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_deadcrab.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_deadcrab_latch_parent_safety.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_device_motion_safety.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_encounter_director.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_encounter_ecology.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_encounter_spawn_variance.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_roster.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_melee.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_variance.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_roster_placement.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_entry_safety.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_faction_manager.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_hostile_motion_v2.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_hostile_no_progress_recovery.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_hostile_stair_recovery.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_m3_run_integration.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_maze_navigator.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_neil_brute.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_phase_zero_runtime_optimization.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_pushback.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_status_elements.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_run_manager.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_seeker.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_seeker_personality.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_staging_deployment.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_ungrounded_stall_recovery.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_wandering_director.lua",
    "gamemodes/legend_of_deborah/gamemode/lod/sv_watcher_instance_dispatch.lua",
    "lua/autorun/server/lod_population_observability.lua"
}
-- DATA's installer label is not proof of loaded gameplay. Compare the mounted
-- GAME bytes with the exact checkout manifest once per Lua session, separately
-- from current method bindings and the actual plan revision below.
function A:SourceIdentity()
    if self.Source then return self.Source end
    local expected={}
    local manifest=file.Read("legend_of_deborah/dev_population_sources.txt","DATA") or ""
    for line in string.gmatch(manifest,"[^\r\n]+") do
        local hash,path=string.match(line,"^(%x+)%s+(.+)$")
        if hash and #hash==64 then expected[path]=hash end
    end
    local out={verified=false,checked=0,mismatches=0,missing=0,modules={}}
    for _,path in ipairs(watched) do
        local bytes=file.Read(path,"GAME")
        local hash=bytes and util.SHA256 and util.SHA256(bytes) or nil
        local want=expected[path]
        local row={path=path,installed=want,mounted=hash}
        if not want or not hash then out.missing=out.missing+1
        else out.checked=out.checked+1;if want~=hash then out.mismatches=out.mismatches+1 end end
        out.modules[#out.modules+1]=row
    end
    out.verified=out.checked==#watched and out.mismatches==0 and out.missing==0
    out.installLabel=string.sub(string.gsub(file.Read("legend_of_deborah/dev_build.txt","DATA") or "unrecorded","[\r\n]"," "),1,160)
    self.Source=out
    return out
end

function A:Snapshot(reason)
    local state=LOD.RunManager and LOD.RunManager.State
    local D,W=LOD.EncounterDirector,LOD.WanderingDirector
    local graph=state and state.Graph
    local out=D and D.PopulationSnapshot and D:PopulationSnapshot() or {ready=false}
    out.entry=LOD.EntrySafety and LOD.EntrySafety:Snapshot() or {ready=false,version="missing"}
    out.observer=self.Version;out.reason=reason;out.seconds=CurTime()
    out.source=self:SourceIdentity()
    out.nativeProbes={support=W and W.NativeSupportRevision or "missing",
        supportBound=W~=nil and W.NativeSupportFunction~=nil and W.NativeSupportFunction==W._SupportedSpawn,
        visibility=D and D.NativeVisibilityRevision or "missing",
        visibilityBound=D~=nil and D.NativeVisibilityFunction~=nil and D.NativeVisibilityFunction==D._VisibleFromStart}
    out.campaign=state and state.CampaignSeed
    out.layoutSeed=graph and graph.LevelSeed
    out.layoutAttempt=graph and graph.ProgressionLayoutAttempt
    out.mazeAttempt=graph and graph.Attempt
    out.gates={}
    for i=1,4 do out.gates[i]=state and state.GatesOpen and state.GatesOpen[i]==true or false end
    local cv=GetConVar("lod_developer_mode")
    out.developerMode=cv and cv:GetBool() or false
    out.frozen=state and state.SimulationFrozen==true or false
    return out
end

-- Native console lines have a smaller ceiling than the full source manifest.
-- Keep complete, valid JSON in the console and the full snapshot in DATA/net.
function A:ConsoleSummary(out)
    local summary={}
    for key,value in pairs(out) do summary[key]=value end
    local source=out.source or {}
    summary.source={verified=source.verified,checked=source.checked,missing=source.missing,
        mismatches=source.mismatches,installLabel=source.installLabel}
    local entry=out.entry or {}
    summary.entry={version=entry.version,ready=entry.ready,eventSerial=entry.eventSerial,
        bindings=entry.bindings,stats=entry.stats,cells=#(entry.cells or {}),heroes={},
        hero_count=#(entry.heroes or {})}
    -- Per-Hero counters survive; unbounded locality/source detail stays in the
    -- full record. The fallback below also bounds unusually large co-op records.
    for i=1,math.min(4,#(entry.heroes or {})) do
        local row={}
        for key,value in pairs(entry.heroes[i]) do
            if type(value)=="number" or type(value)=="boolean" then row[key]=value end
        end
        summary.entry.heroes[i]=row
    end
    local encoded=util.TableToJSON(summary)
    if encoded and #encoded<=3800 then return encoded end
    local compact={source=summary.source,gates=out.gates,entry={version=entry.version,
        ready=entry.ready,eventSerial=entry.eventSerial,stats=entry.stats},
        console_detail_omitted=true}
    for key,value in pairs(out) do
        if type(value)=="number" or type(value)=="boolean" or type(value)=="string" then compact[key]=value end
    end
    encoded=util.TableToJSON(compact)
    if encoded and #encoded<=3800 then return encoded end
    return util.TableToJSON({observer=out.observer,reason=out.reason,seconds=out.seconds,
        source=summary.source,gates=out.gates,console_detail_omitted=true}) or "{}"
end

function A:Capture(reason)
    if game.GetMap()~="gm_flatgrass" or not LOD.RunManager then return end
    local out=self:Snapshot(reason)
    local encoded=util.TableToJSON(out)
    if not encoded then return end
    local line="[LOD:POPULATION] "..encoded
    self.Records[#self.Records+1]=line
    if #self.Records>64 then table.remove(self.Records,1) end
    local text=table.concat(self.Records,"\n").."\n"
    local ok,err=pcall(function()
        file.CreateDir("legend_of_deborah")
        file.Write("legend_of_deborah/population_latest.txt",text)
        assert(file.Read("legend_of_deborah/population_latest.txt","DATA")==text,"DATA write did not persist")
    end)
    self.LastWrite={ok=ok,path="legend_of_deborah/population_latest.txt",error=not ok and tostring(err) or nil}
    if not ok and self.LastWriteError~=tostring(err) then
        print("[LOD:POPULATION] Save failed: "..tostring(err))
    end
    self.LastWriteError=not ok and tostring(err) or nil
    print("[LOD:POPULATION] "..self:ConsoleSummary(out))
    return out
end

function A:Poll()
    local s=LOD.RunManager and LOD.RunManager.State
    if not s or not s.BuildReady or not s.Graph then return end
    local plan=s.Graph.EncounterPlan
    local gateState=""
    for i=1,4 do gateState=gateState..(s.GatesOpen and s.GatesOpen[i] and "1" or "0") end
    local changed=plan~=self.Plan or s.Graph~=self.Graph
    local gates=gateState~=self.Gates
    local entry=LOD.EntrySafety and LOD.EntrySafety.EventSerial
    local entryChanged=entry~=self.EntrySerial
    if changed or gates or entryChanged or CurTime()>=(self.NextReport or 0) then
        self:Capture(changed and "built" or gates and "gate_progress" or entryChanged and "entry_progress" or "heartbeat")
        self.Plan,self.Graph,self.Gates,self.EntrySerial=plan,s.Graph,gateState,entry
        self.NextReport=CurTime()+30
    end
end
-- Deliberately independent of developer mode: release-mode acceptance used to
-- disable the RPG logger before ingress. No spawning, RNG, convar or AI changes.
timer.Create("LOD_PopulationEvidence",10,0,function() A:Poll() end)
hook.Add("ShutDown","LOD_PopulationEvidence",function() A:Capture("shutdown") end)
concommand.Add("lod_population_evidence",function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    A:Capture("requested")
end)

-- One opt-in client request mirrors this server-owned census into the same
-- client DATA directory as the performance file. No second census or timer.
-- Source hashes remain session-cached; requests are admin-only and rate-limited.
if util.AddNetworkString and net and net.Receive and net.Start and net.WriteUInt
    and net.WriteData and net.Send then
    local channel="LOD_PopulationSnapshot"
    util.AddNetworkString(channel)
    local nextRequest=setmetatable({},{__mode="k"})
    net.Receive(channel,function(_,ply)
        if not IsValid(ply) or not ply:IsAdmin() or game.GetMap()~="gm_flatgrass" then return end
        if CurTime()<(nextRequest[ply] or 0) then return end
        nextRequest[ply]=CurTime()+2
        local out=A:Capture("performance_requested")
        if not out then return end
        out.server_write=A.LastWrite
        local encoded=util.TableToJSON(out)
        if not encoded or #encoded>60000 then
            print("[LOD:POPULATION] Client snapshot exceeds the 60000-byte transport limit")
            return
        end
        net.Start(channel);net.WriteUInt(#encoded,16);net.WriteData(encoded,#encoded);net.Send(ply)
    end)
end
