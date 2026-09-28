LOD = LOD or {}
LOD.FactionManager = LOD.FactionManager or {}

local FactionManager = LOD.FactionManager

function FactionManager:IsHostile(ent)
    return IsValid(ent) and ent.LODHostile == true
end

-- Faction membership is independent of engine entity class and controller.
function FactionManager:IsEnemyCombatant(ent)
    if not IsValid(ent) then return false end
    if ent.LODSummonedSeeker and IsValid(ent.LODCaster) and ent.LODCaster.LODFallenHero then return true end
    local run = LOD.RunManager
    return self:IsHostile(ent) or (run and run.IsSoldierControl and run:IsSoldierControl(ent)) == true
end

-- Combat allegiance is a role, not a Source player/team classification.
-- Retain a summon as its own status-bearing actor; only weapon/projectile
-- proxies resolve to an owner. Bounded traversal also rejects ownership cycles.
function FactionManager:DamageSource(ent)
    if IsValid(ent) and (ent:IsPlayer() or self:IsHostile(ent) or ent.LODSummonedSeeker) then return ent end
    local seen = {}
    for _ = 1, 4 do
        if not IsValid(ent) or seen[ent] then return nil end
        seen[ent] = true
        if ent:IsPlayer() or self:IsHostile(ent) or ent.LODSummonedSeeker then return ent end
        local owner = ent.LODCaster
        if not IsValid(owner) then owner = ent.LODOwner end
        if not IsValid(owner) and ent.GetOwner then owner = ent:GetOwner() end
        ent = owner
    end
end

function FactionManager:SameFaction(a, b)
    a, b = self:DamageSource(a), self:DamageSource(b)
    if not a or not b then return false end
    return self:IsEnemyCombatant(a) == self:IsEnemyCombatant(b)
end

-- Permissions belong to an accepted attack and exact actor life, never to a
-- global switch. Ordinary expiry/cure stops NEW attacks; committed projectiles
-- may finish, but death, role/incarnation or world replacement revokes receipts.
FactionManager.AttackPermissions = FactionManager.AttackPermissions or setmetatable({}, {__mode="k"})
FactionManager.DamagePackets = FactionManager.DamagePackets or setmetatable({}, {__mode="k"})
function FactionManager:CaptureAttackPermission(source, event)
    if not event or self.AttackPermissions[event] then return end
    local status = LOD.RPGStatusElements
    local allowed = status and status:AllowsFriendlyFire(source) == true
    self.AttackPermissions[event] = {source=source, allowed=allowed,
        life=status and status.ActorLives and status.ActorLives[source],
        enemy=self:IsEnemyCombatant(source), run=LOD.RunManager and LOD.RunManager.State}
end

function FactionManager:AllowsFriendlyFire(source, event)
    if not IsValid(source) or source.LODDead or (source.Health and source:Health() <= 0) then return false end
    local status = LOD.RPGStatusElements
    if status and status:AllowsFriendlyFire(source) then return true end
    local receipt = event and self.AttackPermissions[event]
    return receipt ~= nil and receipt.allowed == true and receipt.source == source
        and IsValid(source) and not source.LODDead and source:Health() > 0
        and receipt.enemy == self:IsEnemyCombatant(source)
        and receipt.run == (LOD.RunManager and LOD.RunManager.State)
        and receipt.life ~= nil and status and status.ActorLives[source] == receipt.life
end

-- PlayerShouldTakeDamage has no DamageInfo argument. Scope a sealed delivery
-- around its one native call so either native hook order sees the SAME packet.
-- Preserve original attacker/inflictor/XP attribution and unwind on errors.
function FactionManager:DealDamage(target, info, event, source)
    local previous = self.DamagePackets[target]
    self.DamagePackets[target] = {attacker=info:GetAttacker(), source=source or info:GetAttacker(), event=event}
    local ok, result = pcall(target.TakeDamageInfo, target, info)
    self.DamagePackets[target] = previous
    if not ok then error(result, 0) end
    return result
end

-- Used by BOTH native player gates and EntityTakeDamage. Returning permission
-- here never short-circuits other protection/defense hooks with an allow result.
function FactionManager:BlocksFriendlyDamage(victim, attacker, inflictor)
    local source = self:DamageSource(attacker) or self:DamageSource(inflictor)
    if not source or not self:SameFaction(source, victim) then return false end
    -- Preserve ordinary Hero self damage and the enemy faction's self rejection.
    if source == victim then return self:IsEnemyCombatant(source) end
    local packet = self.DamagePackets[victim]
    if packet and packet.attacker == attacker then
        return not self:AllowsFriendlyFire(packet.source, packet.event)
    end
    return not self:AllowsFriendlyFire(source, source.LODCommittedAttackEvent)
end

-- Damage geometry may include allies while Reckless. IsOpponent/Opponents
-- remain natural allegiance/AI-selection queries: Reckless must not rewrite
-- factions or replace the existing sealed 1-in-3 AI betrayal decision.
function FactionManager:CanDamage(source, target, event)
    source = self:DamageSource(source) or source
    if not IsValid(source) or not IsValid(target) or source == target
        or target.LODDead or target:Health() <= 0 then return false end
    if self:IsOpponent(source, target) then return true end
    if not (self:IsEnemyCombatant(target) or self:IsValidPlayerTarget(target)
        or target.LODSummonedSeeker) then return false end
    return self:SameFaction(source, target) and self:AllowsFriendlyFire(source, event)
end

function FactionManager:DamageTargets(source, event)
    if not self:AllowsFriendlyFire(source, event) then return self:Opponents(source) end
    local out, seen = {}, {}
    local function add(target)
        if not seen[target] and self:CanDamage(source, target, event) then
            seen[target] = true; out[#out + 1] = target
        end
    end
    for _, ent in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do add(ent) end
    for _, ent in ipairs(player.GetAll()) do add(ent) end
    for _, list in pairs(LOD.MagicForms and LOD.MagicForms.ActiveSummons or {}) do
        for _, ent in ipairs(list) do add(ent) end
    end
    table.sort(out, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return out
end

function FactionManager:IsOpponent(source, target)
    if not IsValid(source) or not IsValid(target) or source == target
        or target.LODDead or target:Health() <= 0 then return false end
    if self:IsEnemyCombatant(source) then return self:IsValidPlayerTarget(target) end
    return self:IsEnemyCombatant(target)
end

function FactionManager:IsValidPlayerTarget(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if not LOD.RunManager or LOD.RunManager.State.Failed or LOD.RunManager.State.LevelCleared then return false end
    return not self:IsEnemyCombatant(ply) and LOD.RunManager:IsActivePlayer(ply)
end

-- Acquisition differs from faction/damage eligibility: stray shots and hazards
-- can still hit a concealed Hero. All directed AI selection uses this gate.
function FactionManager:CanAcquirePlayerTarget(ply)
    local perception=LOD.RPGPerceptionState
    return self:IsValidPlayerTarget(ply) and not (LOD.EntrySafety and LOD.EntrySafety:Protected(ply))
        and not (perception and perception:IsInvisible(ply))
end

function FactionManager:LivingTargets()
    local targets = {}
    for _, ply in ipairs(player.GetAll()) do
        if self:IsValidPlayerTarget(ply) then targets[#targets + 1] = ply end
    end
    table.sort(targets, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return targets
end

-- Area feats need the same opposition as ordinary targeting, including human
-- Soldiers. Never scan every entity or let an AI aura damage its own faction.
function FactionManager:Opponents(source)
    if self:IsEnemyCombatant(source) then return self:LivingTargets() end
    local out = {}
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if self:IsOpponent(source, hostile) then
            out[#out + 1] = hostile
        end
    end
    for _, actor in ipairs(player.GetAll()) do
        if self:IsOpponent(source, actor) then out[#out + 1] = actor end
    end
    table.sort(out, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return out
end

function FactionManager:BestTarget(hostile, graph, homeCell)
    local navigator = LOD.MazeNavigator
    if not navigator or not graph then return nil end

    if hostile.LODArchetypeId=="listener" then
        local receipt=self:HeardFootstep(hostile,graph)
        return receipt and receipt.hero or nil,0
    end
    local statusElements = LOD.RPGStatusElements
    if statusElements and statusElements.ChooseRecklessTarget then
        local ally, distance = statusElements:ChooseRecklessTarget(hostile, graph, homeCell)
        if ally then return ally, distance end
    end

    if LOD.EnemySupport then
        local rallied, distance = LOD.EnemySupport:RallyTarget(hostile, graph, homeCell)
        if rallied then return rallied, distance end
    end

    local best, bestGraphDistance, bestWorldDistance
    for _, ply in ipairs(self:LivingTargets()) do
        local targetCell = navigator:WorldToCell(graph, ply:GetPos())
        if targetCell and self:CanAcquirePlayerTarget(ply) then
            local graphDistance = homeCell and navigator:Distance(graph, homeCell, targetCell) or 0
            if graphDistance ~= math.huge then
                local worldDistance = hostile:GetPos():DistToSqr(ply:GetPos())
                if not best
                    or graphDistance < bestGraphDistance
                    or (graphDistance == bestGraphDistance and worldDistance < bestWorldDistance)
                then
                    best = ply
                    bestGraphDistance = graphDistance
                    bestWorldDistance = worldDistance
                end
            end
        end
    end
    return best, bestGraphDistance
end

-- Same-faction protection for native actors, summons and attributed proxies.
-- B15 retains its exact packet-specific exception; it is not general infighting.
hook.Add("EntityTakeDamage", "LOD_HostileFactionDamage", function(victim, dmginfo)
    local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
    if FactionManager:BlocksFriendlyDamage(victim, attacker, inflictor)
        and not (LOD.EnemyRoster and LOD.EnemyRoster.AllowsCrossfire
            and LOD.EnemyRoster:AllowsCrossfire(dmginfo, attacker, victim)) then
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)
        return true
    end
end)

-- B13 cooperative proximity uses the same cached Hero roster/acquisition as
-- perception. Geometry is physical visibility, never either player's camera.
function FactionManager:CooperativeVisible(a,b)
    local tr=util.TraceLine({start=a:WorldSpaceCenter(),endpos=b:WorldSpaceCenter(),mask=MASK_SOLID,
        filter=function(v) return not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit or tr.Entity==b
end
function FactionManager:CooperativeNeighbor(source,primary,graph,radius,sameCell,now)
    local heroes=self:PerceptionHeroes(now)
    if #heroes>32 then return nil,false end -- fail closed; never infer isolation from truncation
    if not self:CanAcquirePlayerTarget(primary) or primary:Health()<=0 then return nil,false end
    local navigator=LOD.MazeNavigator;local cell=navigator:WorldToCell(graph,primary:GetPos())
    if not cell then return nil,false end
    local best,distance
    for _,p in ipairs(heroes) do
        if p~=primary and self:CanAcquirePlayerTarget(p) and p:Health()>0 then
            local other=navigator:WorldToCell(graph,p:GetPos());local d=primary:GetPos():DistToSqr(p:GetPos())
            if other and other.z==cell.z and (not sameCell or other==cell)
                and d<=radius^2 and self:CooperativeVisible(primary,p)
                and (not sameCell or (LOD.EnemyRoster:MeleeCellLegal(graph,other)
                    and source:GetPos():DistToSqr(p:GetPos())<=360^2 and LOD.EnemyRoster:Visible(source,p)))
                and (not best or d<distance or d==distance and p:EntIndex()<best:EntIndex()) then best=p;distance=d end
        end
    end
    return best,true
end
