-- Strong ownership is intentional: a weak entity key can disappear before its
-- native CSoundPatch is stopped. Every loop has a renewed, finite lease.
if LOD.LoopAudio then LOD.LoopAudio.Closed=true;LOD.LoopAudio:Reset() end
LOD.LoopAudio={Groups={},Limits={gas=2,watcher=2,fuse=4},Retired=setmetatable({}, {__mode='k'})}
local A=LOD.LoopAudio
local function generation()
    local identity=LOD.ClientTopologyIdentity
    if identity and identity.key then return identity.key end
    local campaign=LOD.Damsels and LOD.Damsels.Campaign
    return campaign and (tostring(campaign.seed)..':'..tostring(campaign.level))
end
A.Generation=generation()
function A:Stop(group,entity)
    local rows=self.Groups[group];local row=rows and rows[entity]
    if row then
        rows[entity]=nil -- detach before native/reentrant cleanup
        local ok,err=pcall(row.patch.Stop,row.patch)
        if not ok and ErrorNoHalt then ErrorNoHalt('[LOD:AUDIO] '..tostring(err)..'\n') end
    end
end
function A:StopOwner(entity,retire)
    if retire then self.Retired[entity]=true end
    for group in pairs(self.Groups) do self:Stop(group,entity) end
end
function A:StopGroup(group)
    for entity in pairs(self.Groups[group] or {}) do self:Stop(group,entity) end
end
function A:Reset(retire)
    self.Resetting=true
    for group,rows in pairs(self.Groups) do
        for entity in pairs(rows) do
            if retire then self.Retired[entity]=true end
            self:Stop(group,entity)
        end
    end
    self.Resetting=false
end
function A:Muted()
    if LOD.Audio and LOD.Audio:Muted() then return true end
    local state=LOD.ClientState
    if state and (state.failed or state.levelCleared) then return true end
    local ply=LocalPlayer()
    return IsValid(ply) and ply:GetNW2Bool('LOD_Staged',false)
end
function A:OwnerLive(group,entity)
    if not IsValid(entity) or self.Retired[entity] then return false end
    if entity.IsDormant and entity:IsDormant() then return false end
    local identity=LOD.ClientTopologyIdentity
    if identity and identity.buildSerial~=nil
        and entity:GetNW2Int('LOD_AudioBuild',-1)~=identity.buildSerial then return false end
    if group=='gas' or group=='watcher' then
        -- Client Health() is not the custom hostile's authoritative death state.
        if entity:GetNW2Bool('LOD_AudioRetired',false)
            or entity:GetNW2Float('LOD_DeathPulseStart',-1)>=0 then return false end
        if group=='gas' and not entity:GetNW2Bool('LOD_RosterAlive',false) then return false end
    end
    -- Fuses belong to their projectile, not the life of the caster who fired it.
    return true
end
function A:Touch(group,entity,path,volume,pitch,level,lease)
    if self~=LOD.LoopAudio or self.Closed or self.Resetting or not self.Limits[group] then return end
    local current=generation()
    if current~=self.Generation then self:Reset();self.Generation=current end
    if self:Muted() then self:Reset();return end
    if not self:OwnerLive(group,entity) then self:Stop(group,entity);return end
    local rows=self.Groups[group] or {};self.Groups[group]=rows
    local row=rows[entity]
    if row and row.path~=path then self:Stop(group,entity);row=nil end
    if not row then
        local count,farthest,distance=0,nil,-1
        for owner in pairs(rows) do
            if not self:OwnerLive(group,owner) then self:Stop(group,owner)
            else
                count=count+1;local d=owner:GetPos():DistToSqr(EyePos())
                if d>distance then farthest,distance=owner,d end
            end
        end
        if count>=self.Limits[group] then
            if entity:GetPos():DistToSqr(EyePos())>=distance*.64 then return end
            self:Stop(group,farthest)
        end
        local patch=CreateSound(entity,path);if not patch then return end
        row={patch=patch,path=path,expires=CurTime()+math.min(2,math.max(.1,lease or .5))};rows[entity]=row
        local ok,err=pcall(function()
            patch:SetSoundLevel(level)
            if rows[entity]==row and not self.Closed then patch:PlayEx(volume/self.Limits[group],pitch) end
        end)
        if not ok then
            self:Stop(group,entity)
            if ErrorNoHalt then ErrorNoHalt('[LOD:AUDIO] '..tostring(err)..'\n') end
            return
        end
        -- Native calls may reenter cleanup; never return/renew an orphan handle.
        if self.Closed or rows[entity]~=row or not self:OwnerLive(group,entity) then
            self:Stop(group,entity);return
        end
    end
    row.expires=CurTime()+math.min(2,math.max(.1,lease or .5))
    return row.patch
end
hook.Add('Think','LOD_LoopAudioLeases',function()
    local current=generation()
    if current~=A.Generation then A:Reset();A.Generation=current end
    if A:Muted() then A:Reset();return end
    for group,rows in pairs(A.Groups) do
        for entity,row in pairs(rows) do
            if not A:OwnerLive(group,entity) or CurTime()>=row.expires then A:Stop(group,entity) end
        end
    end
end)
hook.Add('EntityRemoved','LOD_LoopAudioEntityRemoved',function(entity,fullUpdate)
    -- Full updates/PVS loss are temporary; returning living actors may renew.
    A:StopOwner(entity,not fullUpdate)
end)
hook.Add('NotifyShouldTransmit','LOD_LoopAudioTransmit',function(entity,transmit)
    if not transmit then A:StopOwner(entity) end
end)
hook.Add('PreCleanupMap','LOD_LoopAudioCleanup',function() A:Reset(true) end)
hook.Add('ShutDown','LOD_LoopAudioShutdown',function() A.Closed=true;A:Reset(true) end)
