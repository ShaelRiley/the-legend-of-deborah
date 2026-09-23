-- Finite combined equipment/enemy playtest; no key grants or dungeon changes.
local U, Run, Director = LOD.EnemyUpdate, LOD.RunManager, LOD.EncounterDirector
local EC, N = LOD.Config.Encounter, LOD.MazeNavigator
local function allowed(ply)
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and IsValid(ply) and ply:IsAdmin() and LOD.Equipment:CanAct(ply)
end
local function tell(ply, text)
    print("[LOD:ENEMY-UPDATE] " .. text)
    ply:ChatPrint(text)
end
local function key(cell) return cell and LOD.MazeGenerator.CellKey(cell.x, cell.y, cell.z) end
function U:TestCells(ply, graph)
    local current = N:WorldToCell(graph, ply:GetPos())
    local distances = self:Reachable(graph, key(current), EC.LeashCells)
    local stairs, occupied, out = {}, {}, {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do stairs[key(edge.a)], stairs[key(edge.b)] = true, true end
    for _, e in ipairs(Director.Plan and Director.Plan.encounters or {}) do occupied[e.cellKey] = true end
    for k, distance in pairs(distances) do
        local cell, tag = graph.Cells[k], (graph.CellTags or {})[k] or {}
        if distance >= 2 and cell.z == current.z and not stairs[k] and not occupied[k] and not tag.objective then
            local pos = N:CellCenter(cell) + Vector(0, 0, 2)
            local tr = util.TraceHull({start = pos, endpos = pos, mins = Vector(-16, -16, 0),
                maxs = Vector(16, 16, 72), mask = MASK_NPCSOLID})
            if not tr.Hit and not tr.StartSolid then out[#out + 1] = {cell = cell, distance = distance, key = k} end
        end
    end
    table.sort(out, function(a, b) return a.distance < b.distance or (a.distance == b.distance and a.key < b.key) end)
    return out
end
concommand.Add("lod_enemy_update_testkit", function(ply)
    if not allowed(ply) then return end
    local state, plan = Run.State, Director.Plan
    if not state.Graph or not state.BuildReady or state.SimulationFrozen or not plan then return end
    local ids = {"sniper", "blitzer"}
    if Director:GetActiveCount() + #ids > math.min(EC.ActiveHostileTarget, EC.ActiveHostileCeiling) then
        tell(ply, "Clear nearby enemies first; this test preserves the active-hostile reserve."); return
    end
    local cells = U:TestCells(ply, state.Graph)
    if #cells < #ids then tell(ply, "Move farther into an open sector, then retry; no two legal test cells nearby."); return end
    Run:MarkUnranked("enemy_update_testkit")
    for i, id in ipairs(ids) do
        local spot = cells[i]
        local e = Director:_AddEncounter(plan, spot.cell, (state.Graph.CellTags[spot.key] or {}).sector,
            "enemy_testkit", id .. "_firing_line", {[id] = 1}, false)
        if not Director:_SpawnEncounter(e) then
            e.cleared = true
            tell(ply, "Spawn deferred by the hostile cap; retry after clearing enemies.")
            return
        end
        for _, ent in ipairs(e.entities) do ent.LODTarget = ply end
        tell(ply, id .. " spawned " .. spot.distance .. " open graph cells away; normal level, XP and equipment drops.")
    end
end)
concommand.Add("lod_enemy_update_status", function(ply)
    if not allowed(ply) then return end
    local counts = {}
    for _, ent in ipairs(Director.Entities or {}) do
        if IsValid(ent) and not ent.LODDead then
            local id = ent.LODArchetypeId or "unknown"
            counts[id] = (counts[id] or 0) + 1
            if id == "sniper" then
                tell(ply, string.format("Sniper #%d hp=%d target=%s position=%s shots=%d sighting=%s",
                    ent:EntIndex(), ent:Health(), tostring(IsValid(ent.LODTarget)), tostring(ent.LODSniperDestination),
                    ent.LODSniperShotsFired or 0, tostring(ent.LODSniperShot ~= nil)))
            end
        end
    end
    local parts = {}
    for id, count in pairs(counts) do parts[#parts + 1] = id .. "=" .. count end
    table.sort(parts)
    tell(ply, "Active encounter roster: " .. table.concat(parts, ", ") .. "; dungeon=" .. tostring(Run.State.Level))
end)

-- One named archetype per request keeps acceptance readable and preserves caps.
concommand.Add("lod_enemy_roster_testkit",function(ply,_,args)
    if not allowed(ply) then return end
    local E=LOD.EnemyRoster;local id=string.lower(tostring(args[1] or ""))
    if not E or not E.Definitions[id] then
        local ids={};for candidate in pairs(E and E.Definitions or {}) do ids[#ids+1]=candidate end;table.sort(ids)
        tell(ply,"Choose: "..table.concat(ids,", "));return
    end
    local s,plan=Run.State,Director.Plan
    if not s or not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen or not plan then return end
    if Director:GetActiveCount()+1>math.min(EC.ActiveHostileTarget,EC.ActiveHostileCeiling) then tell(ply,"Clear nearby enemies first.");return end
    local chosen
    for _,spot in ipairs(U:TestCells(ply,s.Graph)) do
        local role=(s.Graph.CellTags[spot.key] or {}).role
        if E:Placement(s.Graph,spot.cell,id,role) then chosen=spot;break end
    end
    if not chosen then tell(ply,"No safe "..id.." placement nearby; move to another open junction or reward branch.");return end
    Run:MarkUnranked("enemy_roster_testkit")
    local tag=s.Graph.CellTags[chosen.key] or {}
    local encounter=Director:_AddEncounter(plan,chosen.cell,tag.sector,tag.role,"roster_testkit",{[id]=1},false)
    if not Director:_SpawnEncounter(encounter) then encounter.cleared=true;tell(ply,"Spawn deferred by population reserve.");return end
    for _,e in ipairs(encounter.entities) do e.LODTarget=ply end
    tell(ply,id.." placed "..chosen.distance.." cells away; normal XP, drops and progression.")
end)
concommand.Add("lod_enemy_animation_status",function(ply)
    if not allowed(ply) then return end
    local bad=0
    for _,e in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(e) and not e.LODDead then
            local seq=e:GetSequence();local valid=LOD.HostileAnimation:Valid(e,seq)
            if not valid then bad=bad+1 end
            tell(ply,string.format("%s #%d model=%s sequence=%s playback=%.2f valid=%s",
                e.LODArchetypeId or "?",e:EntIndex(),e:GetModel(),e:GetSequenceName(seq),e:GetPlaybackRate(),tostring(valid)))
        end
    end
    tell(ply,"Invalid/reference live sequences: "..bad)
end)
