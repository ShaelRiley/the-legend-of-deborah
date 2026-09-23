local E, Run = assert(LOD.Equipment), assert(LOD.RunManager)
local Rules, Forms, Magic = assert(LOD.RPGAbilityRules), assert(LOD.MagicForms), assert(LOD.Magic)
E.MoveSessions = setmetatable({}, {__mode="k"})
E.MoveProjectiles = setmetatable({}, {__mode="k"})
Rules.VoluntaryDashes = setmetatable({}, {__mode="k"})
util.AddNetworkString("LOD_SpecialMoveToken")
util.AddNetworkString("LOD_SpecialMoveFX")

function E:ClearTransient(ply)
    if self.EndStatue then self:EndStatue(ply,"lifecycle changed");self.StatueInputAt[ply]=nil end
    if self.StompFlights then self.StompFlights[ply]=nil end
    if self.EndCloak then self:EndCloak(ply,"lifecycle changed") end
    self.MoveSessions[ply] = nil
    Rules:StopVoluntaryDash(ply)
    if Rules.ClearDodge then Rules:ClearDodge(ply) end
    for _, targets in pairs(Rules.BlockEvents or {}) do targets[ply]=nil end
    if IsValid(self.Projectiles[ply]) then self.Projectiles[ply]:Remove() end
    if IsValid(self.MoveProjectiles[ply]) then self.MoveProjectiles[ply]:Remove() end
    self.MoveProjectiles[ply]=nil
end

function E:MoveSession(ply)
    local ps = Run:GetPlayerState(ply)
    local session = self.MoveSessions[ply]
    if not session or session.ps ~= ps or session.run ~= Run.State or session.levelSeed ~= Run.State.LevelSeed
        or session.life ~= (ps and ps.equipmentLifeSerial) then
        session={ps=ps,run=Run.State,levelSeed=Run.State.LevelSeed,life=ps and ps.equipmentLifeSerial,tokens={},cooldowns={}}
        self.MoveSessions[ply]=session
    end
    return session
end

function Rules:BeginVoluntaryDash(ply, move)
    local current=self.VoluntaryDashes[ply]
    if current and CurTime()<current.ends then return false end
    if current then self:StopVoluntaryDash(ply,current) end
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

function Rules:StopVoluntaryDash(ply, expected)
    local dash=self.VoluntaryDashes[ply]
    if not dash or expected and dash~=expected then return false end
    self.VoluntaryDashes[ply]=nil
    if dash.ended then dash.ended(ply,dash) end
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
        or ply:GetMoveType() ~= MOVETYPE_WALK or dash.valid and not dash.valid(ply,dash)
        or ply.LODForcedMovementUntil and CurTime() < ply.LODForcedMovementUntil then
        -- Do not overwrite a newly imposed Push; it remains the displacement authority.
        if not (ply.LODForcedMovementUntil and CurTime() < ply.LODForcedMovementUntil) then
            data:SetVelocity(dash.stopAtRest and Vector(0,0,velocity.z) or Vector(dash.prior.x,dash.prior.y,velocity.z))
        end
        self:StopVoluntaryDash(ply,dash)
        return
    end
    local speed=math.min(dash.speed,dash.remaining/math.max(engine.TickInterval(),0.001))
    if dash.step then speed=dash.step(ply,dash,speed) end
    data:SetMaxSpeed(math.max(data:GetMaxSpeed(),speed))
    data:SetMaxClientSpeed(math.max(data:GetMaxClientSpeed(),speed))
    data:SetForwardSpeed(0); data:SetSideSpeed(0)
    data:SetVelocity(dash.direction*speed+Vector(0,0,velocity.z))
end

-- Innate delivery binds the actual equipped record, not just a family name.
function E:BindMoveSource(ply,move)
    local session=self:MoveSession(ply)
    local state=session.ps.equipment
    local source,sourceSlot
    for _,slot in ipairs(self.SlotOrder) do
        local item=self:Equipped(state,slot)
        if item and item.definitionId==move.family then source,sourceSlot=item,slot;break end
    end
    if not source then return nil end
    local def=self:Definition(source)
    for _,slot in ipairs(def.occupancy or {}) do
        if self:Equipped(state,slot)~=source then return nil end
    end
    return {session=session,graph=Run.State.Graph,source=source,state=state,
        slot=sourceSlot,identity=session.ps.identity}
end

function E:PrepareMoveAttack(ply,move)
    local binding=self:BindMoveSource(ply,move)
    if not binding then return nil end
    local source=binding.source
    local element
    for _,record in ipairs(source.properties or {}) do
        local property=self:RecordDefinition(source,record)
        if property and property.element and record.amount>0 then element=property.element;break end
    end
    local content=LOD.RPG.MagicContents[move.element or element or "fire"]
    if not content then return nil end
    content=table.Copy(content)
    if move.rider then content.rider=move.rider end
    local context=Forms:_NewContext(ply,move,content)
    context.moveBinding=binding
    context.deliveryForm=move
    context.deliveryContent=content
    return context
end

function E:MoveAttackValid(ply,context)
    local binding=context and context.moveBinding
    if not binding or not IsValid(ply) or not self:CanAct(ply)
        or self:MoveSession(ply)~=binding.session or Run.State.Graph~=binding.graph
        or binding.session.ps.equipment~=binding.state or binding.session.ps.identity~=binding.identity then return false end
    local source=binding.source
    if binding.state.items[source.id]~=source or self:Equipped(binding.state,binding.slot)~=source then return false end
    for _,slot in ipairs(self:Definition(source).occupancy or {}) do
        if self:Equipped(binding.state,slot)~=source then return false end
    end
    return true
end

-- Handlers preflight before the single resource/cooldown commit, then resolve
-- through shared authorities. New items register here instead of new listeners.
E.MoveHandlers = {
    projectile = {
        prepare=function(ply,move)
            if IsValid(E.MoveProjectiles[ply]) then return nil end
            local context=E:PrepareMoveAttack(ply,move)
            if not context then return nil end
            local ok,ent=Forms:_SpawnProjectile(ply,move,context.deliveryContent,context)
            if not ok then return nil end
            E.MoveProjectiles[ply]=ent
            return context
        end,
        resolve=function() end
    },
    strike = {
        prepare=function(ply,move)
            if not Run.State.Graph or not LOD.MazeNavigator:WorldToCell(Run.State.Graph,ply:GetPos()) then return nil end
            return E:PrepareMoveAttack(ply,move)
        end,
        resolve=function(ply,move,context)
            local targets,footprint=Forms:_BlastTargets(ply,move.cells)
            for _,target in ipairs(targets) do
                Forms:_ApplyDamage(ply,ply,target,move,context.deliveryContent,context,
                    (target:GetPos()-ply:GetPos()):GetNormalized())
            end
            Forms:BroadcastFX(move.id,context.deliveryContent.id,ply:GetPos(),ply:GetPos()+Vector(0,0,72),ply,
                {kind=2,cells=footprint})
        end
    },
    dash = {
        prepare=function(ply,move)
            return Rules:BeginVoluntaryDash(ply,move) and {} or nil
        end,
        resolve=function() end
    },
    burst = {
        prepare=function(ply,move) return Forms:_NewContext(ply,move,nil) end,
        resolve=function(ply,move,context)
            for _, target in ipairs(Forms:_BlastTargets(ply,move.cells)) do
                local before=target:Health()
                local direction=(target:GetPos()-ply:GetPos()):GetNormalized()
                Forms:_ApplyDamage(ply,ply,target,move,nil,context,direction)
                if IsValid(target) and not target.LODDead and target:Health()>0 and target:Health()<before then
                    LOD.Pushback:Apply(target,{attacker=ply,origin=ply:GetPos(),direction=direction,
                        distance=move.push,source=move.name,magicPush=true})
                end
            end
        end
    },
    nearest = {
        prepare=function(ply,move)
            local nearest,distance
            -- Same graph reachability, cover and faction rules as Blast.
            for _,target in ipairs(Forms:_BlastTargets(ply,move.cells)) do
                local d=target:GetPos():DistToSqr(ply:GetPos())
                if not distance or d<distance or d==distance and target:EntIndex()<nearest:EntIndex() then
                    nearest,distance=target,d
                end
            end
            if not nearest then
                E:Report(ply,move.name.." — no visible enemy in reach", "special_move_rejected")
                return nil
            end
            local context=Forms:_NewContext(ply,move,nil)
            context.selectedTarget=nearest
            return context
        end,
        resolve=function(ply,move,context)
            local target=context.selectedTarget
            Forms:_ApplyDamage(ply,ply,target,move,nil,context,(target:GetPos()-ply:GetPos()):GetNormalized())
        end
    }
}

function E:ExecuteMove(ply, id, session)
    local move=self.SpecialMoves[id]
    if not move or not self:CanAct(ply) or self:IsActive(ply) then return false end
    -- An old call/session cannot spend the resources of a fresh Hero/life/run.
    if session~=self:MoveSession(ply) then return false end
    if self.EndStatue then self.StatueInputAt[ply]=CurTime();self:EndStatue(ply,"technique attempt") end
    local status=LOD.RPGStatusElements
    if not status:CanInitiateMagic(ply) then return false end
    local _,grants=self:Contributions(session.ps.equipment)
    local handler=self.MoveHandlers[move.effect]
    if not handler or not grants[id] or CurTime() < (session.cooldowns[id] or 0) then return false end
    local offensive=move.offensive or move.effect=="burst"
    local cost=offensive and Rules.OffensiveMagicCost
        and Rules:OffensiveMagicCost(ply,move.magicCost) or move.magicCost
    local resource=Magic:_EnsureState(ply)
    if not resource or resource.magic < cost then
        self:Report(ply,move.name.." — insufficient Magic", "special_move_rejected"); return false
    end
    local context=handler.prepare(ply,move)
    if not context then return false end
    if offensive then context.castSerial=Forms:_NextCastSerial(ply) end
    if LOD.RPG.PrepareCheckpointDAuraBurst then context.auraBurst=LOD.RPG:PrepareCheckpointDAuraBurst(ply) end
    resource.magic=resource.magic-cost
    session.cooldowns[id]=CurTime()+move.cooldown
    Magic:_Sync(ply,resource)
    if offensive and self.EndCloak then self:EndCloak(ply,"offensive technique") end
    handler.resolve(ply,move,context)
    local effects=LOD.RPG.FeatEffectSystem
    if offensive and effects and effects.RecordQuantumSpend then effects:RecordQuantumSpend(ply,move.magicCost,cost) end
    hook.Run("LODDiscreteMagicSpent",ply,cost,context)
    ply:EmitSound(move.effect == "dash" and "weapons/iceaxe/iceaxe_swing1.wav" or "weapons/physcannon/energy_sing_explosion2.wav",60,115,0.4)
    net.Start("LOD_SpecialMoveFX"); net.WriteEntity(ply); net.WriteString(id); net.WriteEntity(IsValid(context.selectedTarget) and context.selectedTarget or NULL); net.Broadcast()
    self:Report(ply,string.format("%s — %g Magic spent / %.1f remaining",move.name,cost,resource.magic),"special_move_"..id)
    return true
end

function E:DirectionToken(ply, token)
    if not self:CanAct(ply) or self:IsActive(ply) then
        local old=self.MoveSessions[ply]; if old then old.tokens={} end
        return false
    end
    local session=self:MoveSession(ply)
    local _,grants=self:Contributions(session.ps.equipment)
    local owned={}
    for _,id in ipairs(self.MoveOrder) do if grants[id] then owned[#owned+1]=id end end
    -- Swapping gear cannot complete a recipe begun under another capability set.
    local signature=table.concat(owned,"|")
    if session.grants~=signature then session.tokens={};session.grants=signature end
    if token == "RESET" then session.tokens={}; return false end
    if token ~= "UP" and token ~= "DOWN" and token ~= "LEFT" and token ~= "RIGHT" then return false end
    local now=CurTime()
    if now-(session.lastToken or -math.huge)>self.InputTimeout then session.tokens={} end
    session.lastToken=now
    session.tokens[#session.tokens+1]=token
    -- Bounded suffix recognition allows different recipe lengths and ignores
    -- leading noise. Only owned abilities compete; ties use registry order.
    local maximum=0
    for _,id in ipairs(owned) do maximum=math.max(maximum,math.min(8,#self.SpecialMoves[id].recipe)) end
    while #session.tokens>maximum do table.remove(session.tokens,1) end
    local selected,length
    for _,id in ipairs(owned) do
        local recipe=self.SpecialMoves[id].recipe
        local n=#recipe
        local match=n>0 and n<=8 and #session.tokens>=n
        if match then
            for i,value in ipairs(recipe) do
                if session.tokens[#session.tokens-n+i]~=value then match=false;break end
            end
        end
        if match and (not length or n>length) then selected,length=id,n end
    end
    if selected then
        session.tokens={}
        -- Never fall through to a second move because the chosen one is on
        -- cooldown or lacks Magic; each completed recipe makes one attempt.
        return self:ExecuteMove(ply,selected,session)
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
