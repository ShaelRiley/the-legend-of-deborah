-- LOD-TANUKI-RING-001. Passive equipment feeds canonical status and perception.
local E,P,S=assert(LOD.Equipment),assert(LOD.RPGPerceptionState),assert(LOD.RPGStatusElements)
local Rules=assert(LOD.RPGAbilityRules)
E.StatueWaits=setmetatable({}, {__mode="k"})
E.StatueInputAt=setmetatable({}, {__mode="k"})
local stone="models/props_wasteland/rockgranite02a"
local function stillVector(v) return v:LengthSqr()<=1 end

function E:StatueStill(ply,record,position,velocity)
    if not self:CanAct(ply) or not LOD.RunManager.State.BuildReady or not LOD.RunManager.State.Graph
        or ply:GetMoveType()~=MOVETYPE_WALK or ply:InVehicle() or not ply:OnGround()
        or Rules.VoluntaryDashes[ply]
        or ply.LODForcedMovementUntil and CurTime()<ply.LODForcedMovementUntil
        or not stillVector(velocity or ply:GetVelocity()) or not stillVector(ply:GetBaseVelocity()) then return false end
    local ground=ply:GetGroundEntity()
    if IsValid(ground) and (ground:IsPlayer() or ground:IsNPC() or ground:IsNextBot()
        or not stillVector(ground:GetVelocity())) then return false end
    return not record or (position or ply:GetPos()):DistToSqr(record.anchor)<=1
end

function E:StatueValid(ply,record)
    return self.StatueWaits[ply]==record and (not record.active or S.Statues[ply]==record)
        and CurTime()-record.last<=.25
        and self:MoveAttackValid(ply,record) and self:StatueStill(ply,record)
end

function E:EndStatue(ply,reason,expected)
    local record=self.StatueWaits[ply]
    if not record or expected and record~=expected then return false end
    self.StatueWaits[ply]=nil
    S:ClearStatue(ply,record)
    P:ClearInvisibleSource(ply,"equipment_statue",record)
    if record.active and IsValid(ply) then
        if ply:GetMaterial()==stone then ply:SetMaterial(record.material) end
        self:Report(ply,"Statue ended — "..reason,"statue_end")
    end
    return true
end

-- Also called before shared input suppressors remove Held/weapon/Magic keys.
function E:ObserveStatueInput(ply,cmd)
    for _,key in ipairs({IN_FORWARD,IN_BACK,IN_MOVELEFT,IN_MOVERIGHT,IN_JUMP,IN_DUCK,IN_ATTACK,IN_ATTACK2,IN_USE}) do
        if cmd:KeyDown(key) then
            self.StatueInputAt[ply]=CurTime();self:EndStatue(ply,"movement or action input");return
        end
    end
    if cmd.GetForwardMove and (cmd:GetForwardMove()~=0 or cmd:GetSideMove()~=0 or cmd:GetUpMove()~=0) then
        self.StatueInputAt[ply]=CurTime();self:EndStatue(ply,"movement input")
    end
end

-- Ordinary SetupMove observes the wait; FinishMove confirms the actual result.
function E:ObserveStatue(ply,data)
    local record=self.StatueWaits[ply]
    if self.StatueInputAt[ply]==CurTime() or data:GetForwardSpeed()~=0 or data:GetSideSpeed()~=0
        or data:GetUpSpeed()~=0 or not self:StatueStill(ply,record,data:GetOrigin(),data:GetVelocity()) then
        self:EndStatue(ply,"movement");return
    end
    if record and not self:StatueValid(ply,record) then self:EndStatue(ply,"source/lifecycle changed",record);record=nil end
    if not record then
        local binding=self:BindMoveSource(ply,self.SpecialMoves.statue)
        if not binding then return end
        record={moveBinding=binding,anchor=ply:GetPos(),started=CurTime(),last=CurTime(),ends=math.huge,
            valid=function(actor,row) return E:StatueValid(actor,row) end,
            ended=function(actor,row,reason) E:EndStatue(actor,reason,row) end}
        self.StatueWaits[ply]=record
    end
    record.last=CurTime()
end

function E:ResolveStatue(ply,data)
    local record=self.StatueWaits[ply]
    if not record then return end
    if not self:StatueValid(ply,record) or not self:StatueStill(ply,record,data:GetOrigin(),data:GetVelocity()) then
        self:EndStatue(ply,"movement",record);return
    end
    if record.active or CurTime()-record.started<2 then return end
    record.material=ply:GetMaterial()
    if not S:SetStatue(ply,record) then self:EndStatue(ply,"status unavailable",record);return end
    record.active=true
    P:SetInvisibleSource(ply,"equipment_statue",record)
    P:ForgetHostileTarget(ply)
    ply:SetMaterial(stone)
    if LOD.Audio then LOD.Audio:At(ply:GetPos(),"statue_transform",700) end
    local fx=EffectData();fx:SetOrigin(ply:GetPos());util.Effect("lod_statue_transform",fx,true,true)
    self:Report(ply,"Statue — concealed and invulnerable while still. Movement or actions end it.","statue_begin")
end
hook.Add("FinishMove","LOD_EquipmentStatue",function(ply,data) E:ResolveStatue(ply,data) end)

local refresh=E.RefreshDerived
function E:RefreshDerived(ply,...)
    local record=self.StatueWaits[ply]
    if record and not self:StatueValid(ply,record) then self:EndStatue(ply,"equipment/lifecycle changed",record) end
    return refresh(self,ply,...)
end
for _,method in ipairs({"Unequip","UnequipItem"}) do
    local base=E[method]
    E[method]=function(self,state,...)
        local result=base(self,state,...)
        for ply,record in pairs(self.StatueWaits) do
            local binding=record.moveBinding
            if binding.state==state and self:Equipped(state,binding.slot)~=binding.source then
                self:EndStatue(ply,"ring removed",record)
            end
        end
        return result
    end
end
local cast=LOD.MagicForms.CastSelected
function LOD.MagicForms:CastSelected(ply,...)
    E.StatueInputAt[ply]=CurTime();E:EndStatue(ply,"Magic attempt")
    return cast(self,ply,...)
end
local use=E.Use
function E:Use(ply,...)
    self.StatueInputAt[ply]=CurTime();self:EndStatue(ply,"item-use attempt")
    return use(self,ply,...)
end
hook.Add("PostEntityTakeDamage","LOD_StatueOutgoingDamage",function(_,info,took)
    if took and info:GetDamage()>0 then
        local actor=info:GetAttacker()
        if IsValid(actor) then E.StatueInputAt[actor]=CurTime();E:EndStatue(actor,"HP damage dealt") end
    end
end)
hook.Add("PreCleanupMap","LOD_StatueCleanup",function()
    for ply,record in pairs(E.StatueWaits) do E:EndStatue(ply,"map cleanup",record) end
    E.StatueInputAt=setmetatable({}, {__mode="k"})
end)
