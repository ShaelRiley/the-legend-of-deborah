LOD = LOD or {}
LOD.FactionManager = LOD.FactionManager or {}

local FactionManager = LOD.FactionManager

function FactionManager:IsHostile(ent)
    return IsValid(ent) and ent.LODHostile == true
end

-- Faction membership is independent of engine entity class and controller.
function FactionManager:IsEnemyCombatant(ent)
    if not IsValid(ent) then return false end
    local run = LOD.RunManager
    return self:IsHostile(ent) or (run and run.IsSoldierControl and run:IsSoldierControl(ent)) == true
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
    return LOD.RunManager:IsActivePlayer(ply)
end

-- Acquisition differs from faction/damage eligibility: stray shots and hazards
-- can still hit a concealed Hero. All directed AI selection uses this gate.
function FactionManager:CanAcquirePlayerTarget(ply)
    local perception=LOD.RPGPerceptionState
    return self:IsValidPlayerTarget(ply) and not (perception and perception:IsInvisible(ply))
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

    local statusElements = LOD.RPGStatusElements
    if statusElements and statusElements.ChooseRecklessTarget then
        local ally, distance = statusElements:ChooseRecklessTarget(hostile, graph, homeCell)
        if ally then return ally, distance end
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

-- Hostiles are a single faction. A zombie-shaped hostile and a Combine-shaped
-- hostile must never spend encounter time damaging one another.
hook.Add("EntityTakeDamage", "LOD_HostileFactionDamage", function(victim, dmginfo)
    if not FactionManager:IsEnemyCombatant(victim) then return end
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()
    local statusElements = LOD.RPGStatusElements
    local reckless = statusElements and statusElements:AllowsFriendlyFire(attacker)
    if (FactionManager:IsEnemyCombatant(attacker) or FactionManager:IsEnemyCombatant(inflictor)) and not reckless then
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)
        return true
    end
end)
