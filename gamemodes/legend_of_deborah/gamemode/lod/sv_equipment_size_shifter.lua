-- Ring of the Size Shifter: an innate single-hand equipment grant. Reuses the
-- shared equipped-record/lifecycle authority and ordinary scale/collision rules.
local E,Rules=assert(LOD.Equipment),assert(LOD.RPGAbilityRules)
if E.EndSizeShifter then
    for actor in pairs(E.SizeShifterActors or {}) do E:EndSizeShifter(actor,true) end
end
E.SizeShifterActors=setmetatable({}, {__mode="k"})

function E:SizeShifterScale(baseScale,progress)
    local base=math.max(.01,tonumber(baseScale) or 1)
    return base+(.33-base)*math.Clamp(tonumber(progress) or 0,0,1)
end
function E:ApplySizeShifterPresentation(ply,scale,lifecycleReset)
    if not IsValid(ply) then return false end
    local collision=LOD.PlayerScaleCollision
    local current=ply.GetModelScale and ply:GetModelScale() or scale
    if collision then
        collision:Preserve(ply)
        if not lifecycleReset and scale>current and not collision:CanScale(ply,scale) then return false end
    end
    ply:SetNW2Float("LOD_PlayerTargetScale",scale)
    ply:SetNW2Float("LOD_SizeScale",scale)
    if current~=scale then ply:SetModelScale(scale,0) end
    if collision then collision:Preserve(ply) end
    return true
end
function Rules:PlayerTargetScale(ply)
    local record=E.SizeShifterActors[ply]
    if record then return record.scale end
    local derived=self:Derived(ply)
    return math.max(.01,tonumber(derived and derived.playerTargetScale) or 1)
end
function Rules:PushSizeScale(ply) return self:PlayerTargetScale(ply) end
function Rules:ApplySizeShifterScale(ply)
    local target=self:PlayerTargetScale(ply)
    local applied=E:ApplySizeShifterPresentation(ply,target)
    if not applied and not E.SizeShifterActors[ply] then
        -- Ordinary Big Guy growth may also be temporarily obstructed. Retry
        -- only that actor, without granting shrinking or scanning the world.
        E.SizeShifterActors[ply]={retiring=true,progress=0,baseScale=target,
            scale=ply:GetModelScale(),at=CurTime()}
    end
    return applied
end

function E:EndSizeShifter(ply,lifecycleReset)
    local record=self.SizeShifterActors[ply]
    if not record then return false end
    record.retiring=true -- no access to shrink, even if crouch remains held
    record.moveBinding=nil
    if lifecycleReset or not IsValid(ply) then
        self.SizeShifterActors[ply]=nil
        -- Reset presentation only, never teleport or change the legal hull. A
        -- new incarnation's ordinary scale is applied by the usual RPG sync.
        self:ApplySizeShifterPresentation(ply,record.baseScale,true)
    end
    return true
end
function E:RefreshSizeShifter(ply)
    local record=self.SizeShifterActors[ply]
    if not IsValid(ply) or not ply:Alive() then self:EndSizeShifter(ply,true);return end
    local eligible=self:CanAct(ply) or self:CanManageInventory(ply)
    if record and not record.retiring and not self:MoveAttackValid(ply,record,true) then
        self:EndSizeShifter(ply,false)
    end
    if eligible then
        local binding=self:BindMoveSource(ply,self.SpecialMoves.size_shift)
        if binding and self:MoveAttackValid(ply,{moveBinding=binding},true) then
            local derived=Rules:Derived(ply) or {}
            if not record then
                record={progress=0,baseScale=tonumber(derived.playerTargetScale) or 1,
                    scale=Rules:PlayerTargetScale(ply),at=CurTime()}
                self.SizeShifterActors[ply]=record
            end
            record.moveBinding=binding
            record.retiring=false
        end
    end
end
function E:TickSizeShifter(ply,now)
    local record=self.SizeShifterActors[ply]
    if not record then return false end
    if not IsValid(ply) or not ply:Alive() then self:EndSizeShifter(ply,true);return false end
    if not record.retiring and not self:MoveAttackValid(ply,record,true) then self:EndSizeShifter(ply,false) end
    local derived=Rules:Derived(ply) or {}
    -- Derivation may have retired this life. Never write a retained old record.
    if self.SizeShifterActors[ply]~=record then return false end
    record.baseScale=math.max(.01,tonumber(derived.playerTargetScale) or 1)
    local dt=math.max(0,now-(record.at or now));record.at=now
    local crouching=not record.retiring and ply:Crouching()
    local progress=math.Clamp(record.progress+(crouching and dt or -dt)/3,0,1)
    local scale=self:SizeShifterScale(record.baseScale,progress)
    local applied=self:ApplySizeShifterPresentation(ply,scale)
    if applied then record.progress,record.scale=progress,scale end
    if applied and record.retiring and record.progress==0 then self.SizeShifterActors[ply]=nil end
    return true
end
if not E.SizeShifterEquipmentWrapped then
    E.SizeShifterEquipmentWrapped=true
local refresh=E.RefreshDerived
function E:RefreshDerived(ply,...)
    local result=refresh(self,ply,...)
    self:RefreshSizeShifter(ply)
    return result
end
-- Immediate grant removal; any remaining record is only a safe return animation.
for _,method in ipairs({"Unequip","UnequipItem"}) do
    local base=E[method]
    E[method]=function(self,state,...)
        local result=base(self,state,...)
        for ply,record in pairs(self.SizeShifterActors) do
            local binding=record.moveBinding
            if binding and binding.state==state and self:Equipped(state,binding.slot)~=binding.source then
                self:EndSizeShifter(ply,false)
            end
        end
        return result
    end
end
end
hook.Add("Think","LOD_EquipmentSizeShifter",function()
    local now=CurTime()
    for ply in pairs(E.SizeShifterActors) do E:TickSizeShifter(ply,now) end
end)
hook.Add("PreCleanupMap","LOD_EquipmentSizeShifterCleanup",function()
    for ply in pairs(E.SizeShifterActors) do E:EndSizeShifter(ply,true) end
end)
