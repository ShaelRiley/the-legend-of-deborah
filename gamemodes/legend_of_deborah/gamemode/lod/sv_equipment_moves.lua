local E, Run = assert(LOD.Equipment), assert(LOD.RunManager)
local Rules, Forms, Magic = assert(LOD.RPGAbilityRules), assert(LOD.MagicForms), assert(LOD.Magic)
E.MoveSessions = setmetatable({}, {__mode="k"})
Rules.VoluntaryDashes = setmetatable({}, {__mode="k"})
util.AddNetworkString("LOD_SpecialMoveToken")
util.AddNetworkString("LOD_SpecialMoveFX")

function E:ClearTransient(ply)
    self.MoveSessions[ply] = nil
    Rules.VoluntaryDashes[ply] = nil
    if Rules.ClearDodge then Rules:ClearDodge(ply) end
    for _, targets in pairs(Rules.BlockEvents or {}) do targets[ply]=nil end
    if IsValid(self.Projectiles[ply]) then self.Projectiles[ply]:Remove() end
end

function E:MoveSession(ply)
    local ps = Run:GetPlayerState(ply)
    local session = self.MoveSessions[ply]
    if not session or session.ps ~= ps or session.run ~= Run.State or session.levelSeed ~= Run.State.LevelSeed then
        session={ps=ps,run=Run.State,levelSeed=Run.State.LevelSeed,tokens={},cooldowns={}}
        self.MoveSessions[ply]=session
    end
    return session
end

function Rules:BeginVoluntaryDash(ply, move)
    if ply:GetMoveType() ~= MOVETYPE_WALK or not LOD.RPGStatusElements:CanMoveVoluntarily(ply)
        or ply.LODForcedMovementUntil and CurTime() < ply.LODForcedMovementUntil then return false end
    local aim = ply:GetAimVector()
    local direction = Vector(aim.x,aim.y,0)
    if direction:Length2D() < 0.001 then return false end
    direction:Normalize()
    local mins,maxs = ply:GetHull()
    if ply:Crouching() then mins,maxs=ply:GetHullDuck() end
    local start=ply:GetPos()
    local trace=util.TraceHull({start=start,endpos=start+direction*move.distance,
        mins=mins,maxs=maxs,mask=MASK_PLAYERSOLID,filter=ply})
    if trace.StartSolid or trace.AllSolid or (trace.Fraction or 1) <= 0 then return false end
    self.VoluntaryDashes[ply]={direction=direction,ends=CurTime()+move.duration,
        remaining=move.distance, speed=move.distance/move.duration, previous=start,
        ps=Run:GetPlayerState(ply),run=Run.State,levelSeed=Run.State.LevelSeed}
    return true
end

-- Called inside the ordinary SetupMove authority. Source performs collision and
-- gravity; no teleport, SetPos, extra Dodge roll or forced-motion exemption.
function Rules:ApplyVoluntaryDash(ply, data)
    local dash=self.VoluntaryDashes[ply]
    if not dash then return end
    local velocity=data:GetVelocity()
    if not dash.prior then dash.prior=Vector(velocity.x,velocity.y,0) end
    dash.remaining=math.max(0,dash.remaining-ply:GetPos():Distance(dash.previous))
    dash.previous=ply:GetPos()
    if CurTime() >= dash.ends or dash.remaining <= 0 or not E:CanAct(ply)
        or Run.State ~= dash.run or Run.State.LevelSeed ~= dash.levelSeed
        or Run:GetPlayerState(ply) ~= dash.ps or E:IsActive(ply)
        or not LOD.RPGStatusElements:CanMoveVoluntarily(ply)
        or ply:GetMoveType() ~= MOVETYPE_WALK
        or ply.LODForcedMovementUntil and CurTime() < ply.LODForcedMovementUntil then
        -- Do not overwrite a newly imposed Push; it remains the displacement authority.
        if not (ply.LODForcedMovementUntil and CurTime() < ply.LODForcedMovementUntil) then
            data:SetVelocity(Vector(dash.prior.x,dash.prior.y,velocity.z))
        end
        self.VoluntaryDashes[ply]=nil
        return
    end
    local speed=math.min(dash.speed,dash.remaining/math.max(engine.TickInterval(),0.001))
    data:SetMaxSpeed(math.max(data:GetMaxSpeed(),speed))
    data:SetMaxClientSpeed(math.max(data:GetMaxClientSpeed(),speed))
    data:SetForwardSpeed(0); data:SetSideSpeed(0)
    data:SetVelocity(dash.direction*speed+Vector(0,0,velocity.z))
end

function E:ExecuteMove(ply, id, session)
    local move=self.SpecialMoves[id]
    if not move or not self:CanAct(ply) or self:IsActive(ply) then return false end
    local status=LOD.RPGStatusElements
    if not status:CanInitiateMagic(ply) then return false end
    local _,grants=self:Contributions(session.ps.equipment)
    if not grants[id] or CurTime() < (session.cooldowns[id] or 0) then return false end
    local cost=move.effect == "burst" and Rules.OffensiveMagicCost
        and Rules:OffensiveMagicCost(ply,move.magicCost) or move.magicCost
    local resource=Magic:_EnsureState(ply)
    if not resource or resource.magic < cost then
        self:Report(ply,move.name.." — insufficient Magic", "special_move_rejected"); return false
    end
    local context
    if move.effect == "dash" then
        if not Rules:BeginVoluntaryDash(ply,move) then return false end
    elseif move.effect == "burst" then
        context=Forms:_NewContext(ply,move,nil)
        context.castSerial=Forms:_NextCastSerial(ply)
    else return false end
    context=context or {}
    if LOD.RPG.PrepareCheckpointDAuraBurst then context.auraBurst=LOD.RPG:PrepareCheckpointDAuraBurst(ply) end
    resource.magic=resource.magic-cost
    session.cooldowns[id]=CurTime()+move.cooldown
    Magic:_Sync(ply,resource)
    if move.effect == "burst" then
        local targets=Forms:_BlastTargets(ply,move.cells)
        for _, target in ipairs(targets) do
            local before=target:Health()
            local direction=(target:GetPos()-ply:GetPos()):GetNormalized()
            Forms:_ApplyDamage(ply,ply,target,move,nil,context,direction)
            if IsValid(target) and not target.LODDead and target:Health()>0 and target:Health()<before then
                LOD.Pushback:Apply(target,{attacker=ply,origin=ply:GetPos(),direction=direction,
                    distance=move.push,source="Rebuff",magicPush=true})
            end
        end
    end
    local effects=LOD.RPG.FeatEffectSystem
    if move.effect == "burst" and effects and effects.RecordQuantumSpend then effects:RecordQuantumSpend(ply,move.magicCost,cost) end
    hook.Run("LODDiscreteMagicSpent",ply,cost,context)
    ply:EmitSound(move.effect == "dash" and "weapons/iceaxe/iceaxe_swing1.wav" or "weapons/physcannon/energy_sing_explosion2.wav",60,115,0.4)
    net.Start("LOD_SpecialMoveFX"); net.WriteEntity(ply); net.WriteString(id); net.Broadcast()
    self:Report(ply,string.format("%s — %g Magic spent / %.1f remaining",move.name,cost,resource.magic),"special_move_"..id)
    return true
end

function E:DirectionToken(ply, token)
    if not self:CanAct(ply) or self:IsActive(ply) then
        local old=self.MoveSessions[ply]; if old then old.tokens={} end
        return false
    end
    local session=self:MoveSession(ply)
    if token == "RESET" then session.tokens={}; return false end
    if token ~= "UP" and token ~= "DOWN" and token ~= "LEFT" and token ~= "RIGHT" then return false end
    local now=CurTime()
    if now-(session.lastToken or -math.huge)>self.InputTimeout then session.tokens={} end
    session.lastToken=now
    session.tokens[#session.tokens+1]=token
    while #session.tokens>3 do table.remove(session.tokens,1) end
    for _, id in ipairs(self.MoveOrder) do
        local recipe=self.SpecialMoves[id].recipe
        local match=#session.tokens==#recipe
        for i,value in ipairs(recipe) do if session.tokens[i]~=value then match=false end end
        if match then
            session.tokens={}
            return self:ExecuteMove(ply,id,session)
        end
    end
    return false
end

local rate=setmetatable({}, {__mode="k"})
net.Receive("LOD_SpecialMoveToken",function(bits,ply)
    if bits ~= 3 or not IsValid(ply) then return end
    local token=net.ReadUInt(3)
    if token == 0 then E:DirectionToken(ply,"RESET"); return end
    if CurTime() < (rate[ply] or 0) then return end
    rate[ply]=CurTime()+0.025 -- network abuse bound, below physical recipe cadence
    local values={"UP","DOWN","LEFT","RIGHT"}
    if values[token] then E:DirectionToken(ply,values[token]) end
end)
