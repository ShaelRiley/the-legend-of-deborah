-- LOD-HEAVY-PLUMBER-001: observe native movement, commit at actual top contact.
local E,T,Rules=LOD.Equipment,LOD.SafeTeleport,LOD.RPGAbilityRules
local move=E.SpecialMoves.heavy_stomp
E.StompFlights=setmetatable({}, {__mode="k"})

function E:StompValid(ply,flight)
    return flight and not flight.invalid and self.StompFlights[ply]==flight
        and T:Matches(flight.hero) and self:MoveAttackValid(ply,flight.context)
        and LOD.RPGStatusElements:CanMoveVoluntarily(ply)
        and not Rules.VoluntaryDashes[ply]
        and not (ply.LODForcedMovementUntil and CurTime()<ply.LODForcedMovementUntil)
end

function E:ObserveStomp(ply,data)
    local flight=self.StompFlights[ply]
    if flight and not self:StompValid(ply,flight) then flight.invalid=true;flight.sample=nil end
    if not T:Hero(ply) or not LOD.RPGStatusElements:CanMoveVoluntarily(ply)
        or Rules.VoluntaryDashes[ply]
        or ply.LODForcedMovementUntil and CurTime()<ply.LODForcedMovementUntil then return end
    local ground=ply:GetGroundEntity()
    local solidGround=ply:OnGround() and IsValid(ground) and not ground:IsPlayer()
        and not ground:IsNPC() and not ground.LODHostile
    -- The bounce stays in the same excursion. An actor cannot rearm it, and
    -- swapping boots in midair cannot manufacture a fresh ground observation.
    if solidGround and (not flight or flight.airborne or flight.invalid or flight.spent) then
        local binding=self:BindMoveSource(ply,move)
        if not binding then self.StompFlights[ply]=nil;return end
        flight={hero=T:Bind(ply),context={moveBinding=binding}}
        self.StompFlights[ply]=flight
    end
    if not self:StompValid(ply,flight) or flight.spent then return end
    if not ply:OnGround() then flight.airborne=true end
    local mins,maxs=ply:GetHull()
    if ply:Crouching() then mins,maxs=ply:GetHullDuck() end
    local pos,velocity=data:GetOrigin(),data:GetVelocity()
    flight.sample={origin=Vector(pos.x,pos.y,pos.z),velocity=Vector(velocity.x,velocity.y,velocity.z),
        mins=mins,maxs=maxs,at=CurTime(),airborne=not ply:OnGround()}
end

function E:ResolveStomp(ply,data)
    local flight=self.StompFlights[ply]
    local sample=flight and flight.sample
    if flight then flight.sample=nil end -- one FinishMove per observed command
    if not sample or not self:StompValid(ply,flight) or flight.spent then return false end
    local pos=data:GetOrigin()
    if CurTime()-sample.at>.1 or pos:DistToSqr(sample.origin)>128^2 then
        flight.invalid=true;return false
    end
    if not sample.airborne or sample.velocity.z>-move.descentSpeed or pos.z>sample.origin.z then return false end
    local tr=util.TraceHull({start=sample.origin,endpos=pos-Vector(0,0,2),mins=sample.mins,maxs=sample.maxs,
        mask=MASK_PLAYERSOLID,filter=ply})
    local target=tr.Entity
    if not tr.Hit or tr.StartSolid or tr.AllSolid or not tr.HitNormal or tr.HitNormal.z<.7
        or not IsValid(target) or not LOD.FactionManager:IsOpponent(ply,target)
        or target.LODDead or target:Health()<=0 then return false end
    local _,top=target:WorldSpaceAABB()
    if sample.origin.z+sample.mins.z<top.z-2 or math.abs(pos.z+sample.mins.z-top.z)>3 then return false end
    flight.spent=true
    local session=flight.context.moveBinding.session
    if CurTime()<(session.cooldowns.heavy_stomp or 0) then return false end
    local vertical=T:ContactBounce(ply,target,flight.hero.graph,pos,move.bounceHeight,sample.origin)
    if not vertical then return false end
    session.cooldowns.heavy_stomp=CurTime()+move.cooldown
    local context={equipmentSnapshot=self:CaptureAttack(ply,nil)}
    if self.EndCloak then self:EndCloak(ply,"stomp contact") end
    LOD.CombatRolls:ApplyEquipmentContact(ply,target,move,context)
    -- Damage reactions may kill, move, silence movement or replace the actor.
    if self:StompValid(ply,flight) and data:GetOrigin():DistToSqr(pos)<1 then
        local velocity=data:GetVelocity()
        ply:SetGroundEntity(NULL)
        data:SetVelocity(Vector(velocity.x,velocity.y,vertical))
    end
    if IsValid(ply) then
        ply:EmitSound("physics/body/body_medium_impact_soft2.wav",65,110,.5)
        net.Start("LOD_SpecialMoveFX");net.WriteEntity(ply);net.WriteString(move.id)
        net.WriteEntity(IsValid(target) and target or NULL);net.Broadcast()
        self:Report(ply,"Heavy Stomp — land on solid ground to rearm","heavy_stomp")
    end
    return true
end

hook.Add("FinishMove","LOD_EquipmentStompContact",function(ply,data) E:ResolveStomp(ply,data) end)
for _,method in ipairs({"Unequip","UnequipItem"}) do
    local base=E[method]
    E[method]=function(self,state,...)
        local result=base(self,state,...)
        for ply,flight in pairs(self.StompFlights) do
            if flight.context.moveBinding.state==state and not self:MoveAttackValid(ply,flight.context) then
                flight.invalid=true;flight.sample=nil
            end
        end
        return result
    end
end
hook.Add("PreCleanupMap","LOD_StompCleanup",function() E.StompFlights=setmetatable({}, {__mode="k"}) end)
