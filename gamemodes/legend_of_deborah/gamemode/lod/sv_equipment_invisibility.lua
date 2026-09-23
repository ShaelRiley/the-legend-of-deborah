-- LOD-INVISIBILITY-RING-001: one source in the canonical perception state.
local E,Run,P=assert(LOD.Equipment),assert(LOD.RunManager),assert(LOD.RPGPerceptionState)
E.Cloaks=setmetatable({}, {__mode="k"})

function E:CloakValid(ply,record)
    if not IsValid(ply) or not self:CanAct(ply) then return false end
    local ps=Run:GetPlayerState(ply)
    return self.Cloaks[ply]==record and ps==record.ps and ps.identity==record.identity
        and ps.equipmentLifeSerial==record.life and Run.State==record.run
        and Run.State.LevelSeed==record.seed and Run.State.Graph==record.graph
        and ps.equipment==record.state and record.state.items[record.source.id]==record.source
        and self:Equipped(record.state,record.slot)==record.source
end

function E:EndCloak(ply,reason,expected)
    local record=self.Cloaks[ply]
    if not record or expected and record~=expected then return false end
    self.Cloaks[ply]=nil
    P:ClearInvisibleSource(ply,"equipment_veil",record)
    if IsValid(ply) then
        ply:SetNW2Float("LOD_VeilUntil",0)
        self:Report(ply,"Veil ended — "..reason,"invisibility_end")
    end
    return true
end

function E:PrepareCloak(ply,move)
    P:IsInvisible(ply) -- retire an expired/stale record before checking refresh
    if self.Cloaks[ply] or not Run.State.Graph then return nil end
    local ps=Run:GetPlayerState(ply)
    local state=ps and ps.equipment
    for _,slot in ipairs({"left_hand","right_hand"}) do
        local item=self:Equipped(state,slot)
        if item and item.definitionId==move.family and state.items[item.id]==item then
            return {ps=ps,identity=ps.identity,life=ps.equipmentLifeSerial,run=Run.State,
                seed=Run.State.LevelSeed,graph=Run.State.Graph,state=state,source=item,slot=slot,
                ends=CurTime()+move.duration,
                valid=function(actor,record) return E:CloakValid(actor,record) end,
                ended=function(actor,record,reason) E:EndCloak(actor,reason,record) end}
        end
    end
end

function E:BeginCloak(ply,record)
    self.Cloaks[ply]=record
    P:SetInvisibleSource(ply,"equipment_veil",record)
    ply:SetNW2Float("LOD_VeilUntil",record.ends)
    -- Bounded existing registry; discard knowledge, not already released shots.
    for _,enemy in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(enemy) then
            if enemy.LODTarget==ply then
                enemy.LODTarget=nil;enemy.LODNextTargetRefresh=0
                enemy.LODWatcherAlertedAt=nil;enemy.LODWatcherAlertSource=nil
                enemy.LODWaypoints={};enemy.LODWaypointIndex=1;enemy.LODNextRouteRefresh=0
            end
        end
    end
end

E.MoveHandlers.cloak={
    prepare=function(ply,move) return E:PrepareCloak(ply,move) end,
    resolve=function(ply,_,record) E:BeginCloak(ply,record) end
}

local refresh=E.RefreshDerived
function E:RefreshDerived(ply,...)
    local record=self.Cloaks[ply]
    if record and not self:CloakValid(ply,record) then self:EndCloak(ply,"equipment/lifecycle changed",record) end
    return refresh(self,ply,...)
end

-- Inventory mutations invalidate at the mutation, so remove/re-equip in one
-- server tick cannot retain the old activation.
for _,method in ipairs({"Unequip","UnequipItem"}) do
    local base=E[method]
    E[method]=function(self,state,...)
        local result=base(self,state,...)
        for ply,record in pairs(self.Cloaks) do
            if record.state==state and self:Equipped(state,record.slot)~=record.source then
                self:EndCloak(ply,"ring removed",record)
            end
        end
        return result
    end
end

-- Every Magic binding converges here, including auxiliary mouse buttons.
local cast=LOD.MagicForms.CastSelected
function LOD.MagicForms:CastSelected(ply,...)
    E:EndCloak(ply,"Magic attempt")
    return cast(self,ply,...)
end
local use=E.Use
function E:Use(ply,mode,...)
    if mode=="throw" then self:EndCloak(ply,"throw attempt") end
    return use(self,ply,mode,...)
end

hook.Add("StartCommand","LOD_VeilAttackInput",function(ply,cmd)
    local record=E.Cloaks[ply]
    if not record then return end
    P:MaintainInvisibleSources(ply,CurTime())
    -- RMB drinks a held potion; that action alone is explicitly non-revealing.
    local item=E:Equipped(record.state,"throwable")
    local def=item and E:Definition(item)
    local drinking=E:IsActive(ply) and def and def.drinkable
    if cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2) and not drinking then
        E:EndCloak(ply,"attack input",record)
    end
end)
hook.Add("PostEntityTakeDamage","LOD_VeilDamage",function(victim,info,took)
    if not took or info:GetDamage()<=0 then return end
    E:EndCloak(victim,"HP damage received")
    E:EndCloak(info:GetAttacker(),"HP damage dealt")
end)
hook.Add("PreCleanupMap","LOD_VeilCleanup",function()
    for ply,record in pairs(E.Cloaks) do E:EndCloak(ply,"map cleanup",record) end
end)
