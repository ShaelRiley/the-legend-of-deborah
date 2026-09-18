-- Owner-only placement telemetry. No client-proposed geometry or preview casts.
local F=LOD.MagicForms
util.AddNetworkString('LOD_WallPreview')
F.WallPreviews=F.WallPreviews or setmetatable({}, {__mode='k'})
function F:WallPreviewState(ply)
    local run=LOD.RunManager
    if not IsValid(ply) or not ply:Alive() or not run or not run.State
        or run.State.Failed or run.State.LevelCleared or run.State.SimulationFrozen then return nil end
    local state,form,content=self:SelectedCastState(ply)
    if not state then return nil end
    if not form or form.id~='wall' then
        for button=3,5 do
            if state.magicBindings[tostring(button)]=='wall' then state,form,content=self:SelectedCastState(ply,button);break end
        end
    end
    if not form or form.id~='wall' then return nil end
    local p,reason,ghost=self:WallPlacement(ply,{spatialBonusCells=self:SpatialBonusCells(ply,state)})
    local canPlace=p~=nil
    local status=LOD.RPGStatusElements
    if not run:IsActivePlayer(ply) then reason='staging'
    elseif LOD.Equipment:IsActive(ply) then reason='throwable'
    elseif status and not status:CanInitiateMagic(ply) then reason='status'
    elseif CurTime()<(LOD.Magic.NextCast[ply] or 0) then reason='cooldown'
    elseif not self:WallCapacityAvailable(ply) then reason='cap'
    else
        local ps=run:GetPlayerState(ply)
        local cost=LOD.RPGAbilityRules:OffensiveMagicCost(ply,self:TotalBaseCost(form,content))
        if not ps or (ps.magic or 0)<cost then reason='magic' end
    end
    return {shape=p or ghost,ready=canPlace and not reason,reason=reason or 'ready'}
end
local function keyOf(record)
    local p=record.shape
    if not p then return record.reason end
    return string.format('%s:%.0f:%.0f:%.0f:%.0f:%.0f:%.0f:%.0f:%.0f:%.0f',record.reason,
        p.origin.x,p.origin.y,p.origin.z,p.mins.x,p.mins.y,p.mins.z,p.maxs.x,p.maxs.y,p.maxs.z)
end
function F:SendWallPreview(ply,record)
    net.Start('LOD_WallPreview');net.WriteBool(record~=nil)
    if record then
        net.WriteBool(record.ready==true);net.WriteString(record.reason)
        net.WriteBool(record.shape~=nil)
        if record.shape then
            net.WriteVector(record.shape.origin);net.WriteVector(record.shape.mins);net.WriteVector(record.shape.maxs)
        end
    end
    net.Send(ply)
end
local nextService=0
hook.Add('Think','LOD_WallPreview',function()
    if CurTime()<nextService then return end
    nextService=CurTime()+F.Tuning.Wall.previewInterval
    for _,ply in ipairs(player.GetAll()) do
        local record=F:WallPreviewState(ply)
        local previous=F.WallPreviews[ply]
        if record then
            local key=keyOf(record)
            if not previous or previous.key~=key or CurTime()>=previous.nextSend then
                F:SendWallPreview(ply,record)
                F.WallPreviews[ply]={key=key,nextSend=CurTime()+F.Tuning.Wall.previewHeartbeat}
            end
        elseif previous then F:SendWallPreview(ply,nil);F.WallPreviews[ply]=nil end
    end
end)
hook.Add('PlayerDisconnected','LOD_WallPreviewDisconnect',function(ply) F.WallPreviews[ply]=nil end)
hook.Add('PreCleanupMap','LOD_WallPreviewCleanup',function()
    for ply in pairs(F.WallPreviews) do if IsValid(ply) then F:SendWallPreview(ply,nil) end end
    F.WallPreviews=setmetatable({}, {__mode='k'})
end)
