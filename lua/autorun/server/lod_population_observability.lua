if CLIENT then return end
LOD=LOD or {}
LOD.PopulationObservability=LOD.PopulationObservability or {}
local A=LOD.PopulationObservability
A.Version="b28-native-population"
A.Records=A.Records or {}
local root="gamemodes/legend_of_deborah/gamemode/"
local watched={
    root.."init.lua",root.."lod/sh_config.lua",root.."lod/sv_encounter_director.lua",
    root.."lod/sv_m3_run_integration.lua",root.."lod/sv_wandering_director.lua",
    root.."lod/sv_enemy_roster_placement.lua",root.."lod/sv_encounter_ecology.lua",
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

function A:Capture(reason)
    if game.GetMap()~="gm_flatgrass" or not LOD.RunManager then return end
    local out=self:Snapshot(reason)
    local encoded=util.TableToJSON(out)
    if not encoded then return end
    local line="[LOD:POPULATION] "..encoded
    self.Records[#self.Records+1]=line
    if #self.Records>64 then table.remove(self.Records,1) end
    file.CreateDir("legend_of_deborah")
    file.Write("legend_of_deborah/population_latest.txt",table.concat(self.Records,"\n").."\n")
    print(line)
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
    if changed or gates or CurTime()>=(self.NextReport or 0) then
        self:Capture(changed and "built" or gates and "gate_progress" or "heartbeat")
        self.Plan,self.Graph,self.Gates=plan,s.Graph,gateState
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
