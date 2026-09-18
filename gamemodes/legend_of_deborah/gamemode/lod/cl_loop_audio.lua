-- Strong ownership is intentional: a weak entity key can disappear before its
-- native CSoundPatch is stopped. Every loop has a renewed, finite lease.
if LOD.LoopAudio then LOD.LoopAudio:Reset() end
LOD.LoopAudio={Groups={},Limits={gas=2,watcher=2,fuse=4}}
local A=LOD.LoopAudio
function A:Stop(group,entity)
    local rows=self.Groups[group];local row=rows and rows[entity]
    if row then row.patch:Stop();rows[entity]=nil end
end
function A:StopGroup(group)
    for entity in pairs(self.Groups[group] or {}) do self:Stop(group,entity) end
end
function A:Reset()
    for group in pairs(self.Groups) do self:StopGroup(group) end
end
function A:Muted()
    local state=LOD.ClientState
    if state and (state.failed or state.levelCleared) then return true end
    local ply=LocalPlayer()
    return IsValid(ply) and ply:GetNW2Bool('LOD_Staged',false)
end
function A:Touch(group,entity,path,volume,pitch,level,lease)
    if not IsValid(entity) or not self.Limits[group] then return end
    if self:Muted() then self:Reset();return end
    local rows=self.Groups[group] or {};self.Groups[group]=rows
    local row=rows[entity]
    if row and row.path~=path then self:Stop(group,entity);row=nil end
    if not row then
        local count,farthest,distance=0,nil,-1
        for owner in pairs(rows) do
            if not IsValid(owner) then self:Stop(group,owner)
            else
                count=count+1;local d=owner:GetPos():DistToSqr(EyePos())
                if d>distance then farthest,distance=owner,d end
            end
        end
        if count>=self.Limits[group] then
            if entity:GetPos():DistToSqr(EyePos())>=distance then return end
            self:Stop(group,farthest)
        end
        local patch=CreateSound(entity,path);if not patch then return end
        patch:SetSoundLevel(level);patch:PlayEx(volume,pitch)
        row={patch=patch,path=path};rows[entity]=row
    end
    row.expires=CurTime()+math.min(2,math.max(.1,lease or .5))
    return row.patch
end
hook.Add('Think','LOD_LoopAudioLeases',function()
    if A:Muted() then A:Reset();return end
    for group,rows in pairs(A.Groups) do
        for entity,row in pairs(rows) do
            if not IsValid(entity) or CurTime()>=row.expires then A:Stop(group,entity) end
        end
    end
end)
hook.Add('EntityRemoved','LOD_LoopAudioEntityRemoved',function(entity)
    for group in pairs(A.Groups) do A:Stop(group,entity) end
end)
hook.Add('PreCleanupMap','LOD_LoopAudioCleanup',function() A:Reset() end)
hook.Add('ShutDown','LOD_LoopAudioShutdown',function() A:Reset() end)
