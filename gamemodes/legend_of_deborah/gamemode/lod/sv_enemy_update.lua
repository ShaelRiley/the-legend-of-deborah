-- Enemy variety checkpoint. All movement, damage, XP and drops retain their
-- existing authorities; this module supplies Sniper intent and firing state.
LOD.EnemyUpdate = LOD.EnemyUpdate or {}
local U = LOD.EnemyUpdate
local EC = LOD.Config.Encounter
local N = LOD.MazeNavigator

local sniper = table.Copy(EC.Archetypes.soldier)
sniper.name, sniper.class = "Sniper", "lod_hostile"
-- Live HUMAN Sniper explicitly delegates these attack parameters to tuning.
sniper.burstDamage, sniper.burstTelegraph, sniper.burstCooldown = 25, 1.25, 3
sniper.fireRange = 2304
sniper.projectileLifetime = sniper.fireRange / sniper.projectileSpeed
EC.Archetypes.sniper = sniper
LOD.CombatRolls.HostileDamageProfiles.sniper = {
    label = "SNIPER", source = "crossbow bolt", count = 4, sides = 8, bonus = 7, reference = 25
}

local function key(cell)
    return cell and LOD.MazeGenerator.CellKey(cell.x, cell.y, cell.z)
end
local function legal(graph, k)
    local tag = (graph.CellTags or {})[k] or {}
    return graph.Cells[k] and not tag.safe and tag.role ~= "boss"
end
local function sorted(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end
-- Bounded searches consume the canonical graph and gate authority. They neither
-- invent links nor use render geometry as a navigation graph.
function U:Reachable(graph, start, maximum, allowed)
    local distances, previous, queue = {}, {}, {}
    if not start or not legal(graph, start) or (allowed and not allowed[start]) then return distances, previous end
    distances[start], queue[1] = 0, start
    local head = 1
    while queue[head] do
        local current = queue[head]; head = head + 1
        if distances[current] < maximum then
            for _, nextKey in ipairs(sorted(graph.Cells[current].neighbors)) do
                if distances[nextKey] == nil and legal(graph, nextKey)
                    and (not allowed or allowed[nextKey] ~= nil) and N:CanTraverse(graph, current, nextKey) then
                    distances[nextKey], previous[nextKey] = distances[current] + 1, current
                    queue[#queue + 1] = nextKey
                end
            end
        end
    end
    return distances, previous
end
function U:Visible(hostile, origin, target)
    local tr = util.TraceLine({start = origin, endpos = target:WorldSpaceCenter(), mask = MASK_SHOT,
        filter = function(ent) return ent ~= hostile and ent:GetParent() ~= hostile end})
    return not tr.Hit or tr.Entity == target or (IsValid(tr.Entity) and tr.Entity:GetOwner() == target)
end
function U:CanShoot(hostile, target)
    return LOD.FactionManager:CanAcquirePlayerTarget(target)
        and hostile:GetPos():DistToSqr(target:GetPos()) <= hostile.LODConfig.fireRange ^ 2
        and self:Visible(hostile, hostile:WorldSpaceCenter(), target)
end
function U:SelectPosition(hostile, graph, target)
    local current = key(N:WorldToCell(graph, hostile:GetPos()))
    local home = hostile.LODHomeCellKey or current
    local domain = self:Reachable(graph, home, EC.LeashCells)
    local distances, previous = self:Reachable(graph, current, math.huge, domain)
    local inPosition = self:CanShoot(hostile, target)
    local candidates = {}
    for k, travel in pairs(distances) do
        local pos = N:CellCenter(graph.Cells[k])
        local range = pos:DistToSqr(target:GetPos())
        if range <= hostile.LODConfig.fireRange ^ 2 then
            candidates[#candidates + 1] = {key = k, pos = pos, range = range, travel = travel}
        end
    end
    table.sort(candidates, function(a, b)
        if not inPosition and a.travel ~= b.travel then return a.travel < b.travel end
        if a.range ~= b.range then return a.range > b.range end
        if a.travel ~= b.travel then return a.travel < b.travel end
        return a.key < b.key
    end)
    -- Test candidates in objective order and stop at the first legal shot;
    -- never trace every visible cell after the winner is already known.
    local best
    for _, candidate in ipairs(candidates) do
        if self:Visible(hostile, candidate.pos + (hostile:WorldSpaceCenter() - hostile:GetPos()), target) then
            best = candidate.key; break
        end
    end
    if not best then return nil end
    local path, cursor = {}, best
    while cursor do
        table.insert(path, 1, graph.Cells[cursor])
        cursor = previous[cursor]
    end
    return best, path
end
function U:Cancel(hostile)
    hostile.LODSniperShot = nil
    hostile:SetNW2Bool("LOD_SoldierShotTelegraph", false)
end
function U:PrepareVisual(hostile)
    if hostile.LODSniperVisualReady then return end
    hostile.LODSniperVisualReady = true
    hostile:SetColor(Color(40, 70, 255))
    local weapon = ents.Create("prop_dynamic")
    if not IsValid(weapon) then return end
    weapon:SetModel("models/weapons/w_crossbow.mdl")
    weapon:SetSolid(SOLID_NONE); weapon:SetMoveType(MOVETYPE_NONE)
    weapon:SetPos(hostile:WorldSpaceCenter()); weapon:Spawn(); weapon:Activate()
    weapon:SetOwner(hostile); weapon:SetParent(hostile); weapon:AddEffects(EF_BONEMERGE)
    hostile.LODWeaponVisual = weapon -- existing death/remove cleanup owns this
end
function U:BeginShot(hostile, target, now, seed)
    local origin = hostile:WorldSpaceCenter()
    local aim = target:WorldSpaceCenter()
    local direction = (aim - origin):GetNormalized()
    hostile.LODSniperShot = {target = target, origin = origin, aim = aim, direction = direction,
        ready = now + hostile.LODConfig.burstTelegraph, seed = seed, attackEvent = {}}
    hostile:SetNW2Vector("LOD_SoldierShotOrigin", origin)
    hostile:SetNW2Vector("LOD_SoldierShotDirection", direction)
    hostile:SetNW2Vector("LOD_SoldierShotAimPoint", aim)
    hostile:SetNW2Bool("LOD_SoldierShotTelegraph", true)
    hostile:EmitSound("Weapon_Crossbow.Reload")
end
function U:Fire(hostile, shot, now)
    local cfg = hostile.LODConfig
    local bolt = ents.Create("lod_soldier_bolt")
    if IsValid(bolt) then
        bolt.LODOwner, bolt.LODDirection = hostile, shot.direction
        bolt.LODSpeed, bolt.LODDamage = cfg.projectileSpeed, cfg.burstDamage
        bolt.LODLifetime = cfg.fireRange / cfg.projectileSpeed
        bolt.LODAttackEvent = shot.attackEvent
        bolt:SetNW2Bool("LOD_SniperBolt", true)
        bolt:SetPos(shot.origin); bolt:SetAngles(shot.direction:Angle())
        bolt:Spawn(); bolt:Activate()
        hostile:EmitSound("Weapon_Crossbow.Single")
        hostile.LODSniperShotsFired = (hostile.LODSniperShotsFired or 0) + 1
    end
    local rules = LOD.RPGAbilityRules
    local rate = rules and rules.RateOfFireMultiplier and rules:RateOfFireMultiplier(hostile) or 1
    hostile.LODNextAttack = now + cfg.burstCooldown / rate
    self:Cancel(hostile)
end
function U:Tick(hostile)
    if hostile.LODArchetypeId ~= "sniper" then return false end
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    local motion, now = LOD.HostileMotionV2, CurTime()
    local statuses = LOD.RPGStatusElements
    if hostile.LODDead or not hostile.LODActivated or not graph or not state.BuildReady
        or state.Failed or state.LevelCleared or state.SimulationFrozen then
        self:Cancel(hostile); motion:Stop(hostile); return true
    end
    self:PrepareVisual(hostile)
    if motion:HoldHitStun(hostile, now) then self:Cancel(hostile); return true end
    if statuses and statuses:HandleAIFlee(hostile, graph, motion) then self:Cancel(hostile); return true end
    hostile:_RefreshTarget(graph)
    local target, shot = hostile.LODTarget, hostile.LODSniperShot
    if not LOD.FactionManager:CanAcquirePlayerTarget(target) then
        self:Cancel(hostile)
        hostile:_RefreshRoute(graph)
        local waypoint = hostile:_AdvanceWaypoint()
        if waypoint then motion:MoveToward(hostile, waypoint) else motion:Stop(hostile) end
        return true
    end
    local canAttack = not statuses or statuses:CanInitiateAttack(hostile)
    if shot then
        motion:Stop(hostile)
        if shot.seed ~= state.LevelSeed or shot.target ~= target or not canAttack or not self:CanShoot(hostile, target) then
            self:Cancel(hostile); return true
        end
        motion:FaceToward(hostile, shot.aim)
        if now >= shot.ready then self:Fire(hostile, shot, now) end
        return true
    end
    local waypoint = hostile.LODWaypoints and hostile.LODWaypoints[hostile.LODWaypointIndex or 1]
    -- Never abandon an authored stair connector midway through its traversal.
    if not (waypoint and waypoint.stair) and now >= (hostile.LODSniperNextRoute or 0) then
        hostile.LODSniperNextRoute = now + EC.RouteRefreshSeconds
        local destination, path = self:SelectPosition(hostile, graph, target)
        hostile.LODSniperDestination = destination
        if path then
            hostile.LODWaypoints = N:PathToWaypoints(graph, path)
            hostile.LODWaypointIndex = 1
        else
            -- No shot exists inside the legal leash: hold and reassess rather
            -- than pursuing through a safe cell or chasing raw wall coordinates.
            hostile.LODWaypoints = {}
            hostile.LODWaypointIndex = 1
        end
    end
    waypoint = hostile:_AdvanceWaypoint()
    if waypoint then
        hostile:_SetActivity(ACT_RUN_AIM_RIFLE or ACT_RUN)
        motion:MoveToward(hostile, waypoint)
    else
        motion:Stop(hostile); motion:FaceToward(hostile, target:GetPos())
        hostile:_SetActivity(ACT_IDLE_ANGRY_SMG1 or ACT_IDLE_ANGRY)
        if canAttack and now >= (hostile.LODNextAttack or 0) and self:CanShoot(hostile, target) then
            self:BeginShot(hostile, target, now, state.LevelSeed)
        end
    end
    return true
end

-- Reuse Firing Line's authored membership count, phase/role eligibility and
-- encounter budget. Variant costs are recalculated by EncounterDirector.
for _, id in ipairs({"sniper", "blitzer"}) do
    local template = table.Copy(EC.Templates.firing_line)
    template.name = EC.Archetypes[id].name .. " Firing Line"
    template.composition.soldier = template.composition.soldier - 1
    template.composition[id] = 1
    EC.Templates[id .. "_firing_line"] = template
end
local director = LOD.EncounterDirector
local baseEligible = director._EligibleTemplates
function director:_EligibleTemplates(sector, role)
    local out = table.Copy(baseEligible(self, sector, role))
    if table.HasValue(out, "firing_line") then
        out[#out + 1] = "sniper_firing_line"
        out[#out + 1] = "blitzer_firing_line"
    end
    return out
end
