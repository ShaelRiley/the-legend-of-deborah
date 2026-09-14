LOD = LOD or {}
LOD.FactionManager = LOD.FactionManager or {}

local FactionManager = LOD.FactionManager

function FactionManager:IsHostile(ent)
    return IsValid(ent) and ent.LODHostile == true
end

function FactionManager:IsValidPlayerTarget(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if not LOD.RunManager or LOD.RunManager.State.Failed or LOD.RunManager.State.LevelCleared then return false end
    return LOD.RunManager:IsActivePlayer(ply)
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
    local run = LOD.RunManager
    local soldier = run and run.IsSoldierControl and run:IsSoldierControl(source)
    if self:IsHostile(source) or soldier then return self:LivingTargets() end
    local out = {}
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile ~= source and not hostile.LODDead and hostile:Health() > 0 then
            out[#out + 1] = hostile
        end
    end
    for _, actor in ipairs(player.GetAll()) do
        if actor ~= source and IsValid(actor) and actor:Alive()
            and run and run.IsSoldierControl and run:IsSoldierControl(actor) then out[#out + 1] = actor end
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
        if targetCell then
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
    if not FactionManager:IsHostile(victim) then return end
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()
    local statusElements = LOD.RPGStatusElements
    local reckless = statusElements and statusElements:AllowsFriendlyFire(attacker)
    if (FactionManager:IsHostile(attacker) or FactionManager:IsHostile(inflictor)) and not reckless then
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)
        return true
    end
end)
