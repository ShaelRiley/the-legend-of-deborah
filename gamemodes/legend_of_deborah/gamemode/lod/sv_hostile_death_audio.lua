-- Enemy audio retirement shares the native hostile death/build lifecycle. Sound
-- resources are strong-owned; the weak owner set contains no native handles.
LOD.HostileDeathAudio=LOD.HostileDeathAudio or {Loops={},Owners=setmetatable({}, {__mode='k'})}
local A=LOD.HostileDeathAudio
local BEAM='npc/stalker/laser_burn.wav'
local LEGACY={'npc/roller/mine/rmine_seek_loop1.wav','npc/roller/mine/rmine_seek_loop2.wav'}
local function state() return LOD.RunManager and LOD.RunManager.State end
local function stopEvent(data)
    local flag=SND_STOP or 4
    return (tonumber(data.Flags) or 0) % (flag*2)>=flag
end
local function pathOf(data)
    return string.lower(data.SoundName or data.OriginalSoundName or ''):gsub('\\','/'):gsub('^[%*#@<>%^%)}!?]+','')
end
local function report(ok,err)
    if not ok and ErrorNoHalt then ErrorNoHalt('[LOD:AUDIO] '..tostring(err)..'\n') end
end
function A:Bind(ent)
    -- Called once at actual native initialization, never from a late sound call.
    if ent.LODAudioContext or ent.LODAudioRetired then return end
    local s=state();if not s then return end
    local build=LOD.TopologySyncSafety and LOD.TopologySyncSafety.BuildSerial or 0
    ent.LODAudioContext={run=s,graph=s.BuildReady and s.Graph or nil,seed=s.LevelSeed,epoch=s.CampaignEpoch,runId=s.RunId,build=build}
    self.Owners[ent]=true
    ent:SetNW2Int('LOD_AudioBuild',build)
end
function A:Live(ent)
    if not IsValid(ent) then return false end
    local s=state();local c=ent.LODAudioContext
    return not self.Closed and IsValid(ent) and not ent.LODDead and not ent.LODAudioRetired
        and ent:Health()>0 and c and s and c.run==s and (not c.graph or c.graph==s.Graph) and c.seed==s.LevelSeed
        and c.epoch==s.CampaignEpoch and c.runId==s.RunId
        and c.build==(LOD.TopologySyncSafety and LOD.TopologySyncSafety.BuildSerial or 0)
        and s.BuildReady and not s.Failed and not s.LevelCleared
end
function A:Stop(ent)
    -- Roster Cancel also runs synchronously from kill hooks. Preserve the native
    -- death safety boundary; the shared presentation/Think retires this row.
    if IsValid(ent) and ent.LODDead and not ent.LODAudioRetirementSent then return end
    local row=self.Loops[ent];if not row then return end
    -- Detach BEFORE native calls: stop events/reentrant cleanup cannot stop twice.
    self.Loops[ent]=nil
    if IsValid(ent) then report(pcall(ent.StopSound,ent,row.path)) end
end
function A:Retire(ent)
    if not IsValid(ent) then self:Stop(ent);self.Owners[ent]=nil;return end
    ent.LODAudioRetired=true
    local first=not ent.LODAudioRetirementSent
    ent.LODAudioRetirementSent=true
    self.Owners[ent]=nil
    local owned=self.Loops[ent]
    self:Stop(ent)
    if first then
        report(pcall(ent.SetNW2Bool,ent,'LOD_AudioRetired',true))
        -- Also clean an already-running pre-refresh Beam/legacy Seeker loop.
        if not owned then report(pcall(ent.StopSound,ent,BEAM)) end
        if ent.LODArchetypeId=='seeker' then
            for _,path in ipairs(LEGACY) do report(pcall(ent.StopSound,ent,path)) end
        end
    end
end
function A:Reset()
    -- Only old owned actors, never a world-wide stopsound or new-dungeon owner.
    for ent in pairs(self.Owners) do self:Retire(ent) end
    for ent in pairs(self.Loops) do self:Retire(ent) end
end
hook.Add('EntityEmitSound','LOD_HostileDeathAudio_SuppressLegacy',function(data)
    -- Native stop events must pass every filter, even during generation/death.
    if stopEvent(data) then return end
    local ent=data.Entity;if not IsValid(ent) then return end
    local path=pathOf(data)
    if ent.LODDead and (path=='buttons/blip1.wav' or path=='buttons/button15.wav') then return false end
    if ent.LODPlaceholderLoot and path=='items/itempickup.wav' then return false end
    if not ent.LODHostile then return end
    if path==BEAM then
        local attack=ent.LODRosterAttack
        if not A:Live(ent) or not ent.LODActivated or not attack or attack.kind~='beam'
            or attack.run~=state() or (attack.finish and CurTime()>=attack.finish)
            or (tonumber(data.SoundTime) or 0)>CurTime() then return false end
        -- The production warning and sweep are one finite existing commitment.
        -- Record the original emitted identifier so StopSound matches scripts too.
        local row=A.Loops[ent]
        if row and row.attack~=attack then A:Stop(ent) end
        A.Loops[ent]={path=data.OriginalSoundName or data.SoundName,attack=attack}
    elseif path==LEGACY[1] or path==LEGACY[2] then
        -- Current Seeker is intentionally one-shot-only; no living loop is added.
        if not A:Live(ent) then return false end
    end
end)
hook.Add('Think','LOD_HostileAudioOwners',function()
    -- Bounded by actual sounding actors, not a per-frame world/registry scan.
    for ent,row in pairs(A.Loops) do
        if not A:Live(ent) then A:Retire(ent)
        elseif ent.LODRosterAttack~=row.attack or not ent.LODActivated
            or (row.attack.finish and CurTime()>=row.attack.finish)
            or state().SimulationFrozen or (LOD.Audio and LOD.Audio:Muted()) then A:Stop(ent) end
    end
end)
hook.Add('EntityRemoved','LOD_HostileAudioRemoved',function(ent)
    if A.Owners[ent] or A.Loops[ent] then A:Retire(ent) end
end)
hook.Add('ShutDown','LOD_HostileAudioShutdown',function() A.Closed=true;A:Reset() end)
