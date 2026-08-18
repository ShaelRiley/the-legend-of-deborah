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

function FactionManager:BestTarget(hostile, graph, homeCell)
    local navigator = LOD.MazeNavigator
    if not navigator or not graph then return nil end

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
    if FactionManager:IsHostile(attacker) or FactionManager:IsHostile(inflictor) then
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)
        return true
    end
end)
