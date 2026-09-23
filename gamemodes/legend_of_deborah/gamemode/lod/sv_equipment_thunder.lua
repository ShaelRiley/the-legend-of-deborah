-- LOD-THUNDER-HAT-001. Equipment dispatch, safe travel, ordinary SetupMove and
-- shared Magic damage remain the authorities; no teleport or charge timer.
local E,R,T,F,Run=LOD.Equipment,LOD.RPGAbilityRules,LOD.SafeTeleport,LOD.MagicForms,LOD.RunManager
util.AddNetworkString("LOD_ThunderChargeFX")

local function valid(ply,dash)
    return E:MoveAttackValid(ply,dash.context) and T:Matches(dash.binding)
        and ply:OnGround() and LOD.RPGStatusElements:CanInitiateMagic(ply)
        and ply:GetPos():DistToSqr(dash.lastPosition)<=34^2
end
local function ended(ply)
    if IsValid(ply) then
        ply:SetNW2Float("LOD_ThunderUntil",0)
        if not (ply.LODForcedMovementUntil and CurTime()<ply.LODForcedMovementUntil) then
            ply:SetLocalVelocity(Vector(0,0,ply:GetVelocity().z))
        end
    end
end
local function step(ply,dash,speed)
    local pos=ply:GetPos()
    dash.lastPosition=pos
    local elapsed=CurTime()-dash.starts
    if elapsed<0 then
        if not T:ChargeSupport(ply,dash.binding.graph,pos) then R:StopVoluntaryDash(ply,dash) end
        return 0
    end
    local dt=math.max(engine.TickInterval(),.001)
    local distance=math.min(32,speed*dt)
    local safe,target=T:ChargePath(ply,dash.binding.graph,pos,dash.direction,distance)
    if safe<distance then
        -- Finish before calling damage: re-entry/duplicate movement cannot hit twice.
        R:StopVoluntaryDash(ply,dash)
        if IsValid(target) and LOD.FactionManager:IsOpponent(ply,target) and target:Health()>0 then
            F:_ApplyDamage(ply,ply,target,dash.move,dash.context.deliveryContent,dash.context,dash.direction)
        end
        return 0
    end
    return safe/dt
end

E.MoveHandlers.charge={
    prepare=function(ply,move)
        if R.VoluntaryDashes[ply] or not ply:OnGround()
            or not LOD.RPGStatusElements:CanMoveVoluntarily(ply)
            or ply.LODForcedMovementUntil and CurTime()<ply.LODForcedMovementUntil then return nil end
        local binding=T:Bind(ply)
        local context=E:PrepareMoveAttack(ply,move)
        if not binding or not context then return nil end
        local aim=ply:GetAimVector()
        local direction=Vector(aim.x,aim.y,0)
        if direction:Length2D()<.001 then return nil end
        direction:Normalize()
        local start=ply:GetPos()
        local distance=T:ChargePath(ply,binding.graph,start,direction,move.distance)
        if distance<32 then return nil end
        context.charge={binding=binding,move=move,direction=direction,
            starts=CurTime()+move.warning,ends=CurTime()+move.warning+move.duration,
            -- Sweep slightly into the first obstruction on the last step. An
            -- exact endpoint tangent can otherwise finish without a native Hit.
            remaining=math.min(move.distance,distance+4),speed=move.distance/move.duration,
            previous=start,lastPosition=start,ps=binding.ps,run=binding.run,levelSeed=binding.seed,
            valid=valid,step=step,ended=ended,stopAtRest=true,origin=start,endpoint=start+direction*distance}
        return context
    end,
    resolve=function(ply,_,context)
        local dash=context.charge
        context.charge=nil
        dash.context=context
        R.VoluntaryDashes[ply]=dash
        ply:SetNW2Float("LOD_ThunderUntil",dash.ends)
        net.Start("LOD_ThunderChargeFX");net.WriteEntity(ply);net.WriteVector(dash.origin)
        net.WriteVector(dash.endpoint);net.WriteFloat(dash.starts);net.WriteFloat(dash.ends);net.Broadcast()
        ply:EmitSound("ambient/energy/weld1.wav",75,90,.7)
    end
}

-- Invalidate at mutation, including remove/re-equip within the same server tick.
for _,method in ipairs({"Unequip","UnequipItem"}) do
    local base=E[method]
    E[method]=function(self,state,...)
        local result=base(self,state,...)
        for ply,dash in pairs(R.VoluntaryDashes) do
            if dash.context and dash.context.moveBinding.state==state and not E:MoveAttackValid(ply,dash.context) then
                R:StopVoluntaryDash(ply,dash)
            end
        end
        return result
    end
end
hook.Add("PreCleanupMap","LOD_ThunderCleanup",function()
    for ply,dash in pairs(R.VoluntaryDashes) do R:StopVoluntaryDash(ply,dash) end
end)
