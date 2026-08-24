LOD = LOD or {}

local RunManager = LOD.RunManager
local ProgressionDirector = LOD.ProgressionDirector
local PC = LOD.Config.Progression

local function allowed(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function cellText(cell)
    if not cell then return "nil" end
    return string.format("(%d,%d,%d)", cell.x, cell.y, cell.z)
end

local function boolText(v)
    return v and "yes" or "no"
end

local function validJailEdge(progression)
    local jail = progression and progression.JailEdge
    local yellow = progression and progression.Gates and progression.Gates[3]
    return jail and yellow and jail.beforeCell and jail.afterCell and jail.edgeKey and
        jail.beforeCell.z == jail.afterCell.z and
        (jail.pathIndex or -1) > (yellow.pathIndex or math.huge)
end

local function printTo(ply, text)
    print("[LOD:M2] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end

concommand.Add("lod_m2_status", function(ply)
    if not allowed(ply) then return end
    local state = RunManager.State
    printTo(ply, string.format(
        "level=%d campaign=%s levelSeed=%s ranked=%s buildReady=%s objective=%d checkpoint=%d played=%d active=%d frozen=%s failed=%s cleared=%s",
        state.Level or -1,
        tostring(state.CampaignSeed),
        tostring(state.LevelSeed),
        boolText(state.Ranked),
        boolText(state.BuildReady),
        state.ObjectiveStage or -1,
        state.CheckpointIndex or -1,
        table.Count(state.PlayedIdentities or {}),
        RunManager:_ActiveCount(),
        boolText(state.SimulationFrozen),
        boolText(state.Failed),
        boolText(state.LevelCleared)
    ))
    printTo(ply, string.format(
        "cards R=%s B=%s Y=%s | gates R=%s B=%s Y=%s | jailKey=%s jailDoor=%s | objective=%s",
        boolText(state.Cards and state.Cards[1]), boolText(state.Cards and state.Cards[2]), boolText(state.Cards and state.Cards[3]),
        boolText(state.GatesOpen and state.GatesOpen[1]), boolText(state.GatesOpen and state.GatesOpen[2]), boolText(state.GatesOpen and state.GatesOpen[3]),
        boolText(state.JailKey), boolText(state.JailDoorOpen),
        ProgressionDirector:GetObjectiveText()
    ))

    for _, candidate in ipairs(player.GetAll()) do
        local ps = RunManager:GetPlayerState(candidate)
        printTo(ply, string.format(
            "player=%s played=%s active=%s lives=%d eliminated=%s character=%s respawnIn=%.1f",
            candidate:Nick(),
            boolText(ps ~= nil),
            boolText(RunManager:IsActivePlayer(candidate)),
            ps and ps.lives or 0,
            boolText(ps and ps.eliminated),
            ps and ps.characterName or "none",
            ps and ps.respawnAt and math.max(0, ps.respawnAt - CurTime()) or 0
        ))
    end
end)

concommand.Add("lod_m2_objectives", function(ply)
    if not allowed(ply) then return end
    local graph = RunManager.State.Graph
    local progression = graph and graph.Progression
    if not progression then
        printTo(ply, "no committed progression plan")
        return
    end

    printTo(ply, "ordered route=" .. tostring(progression.Validation and progression.Validation.orderedRoute))
    for i = 1, 3 do
        local gate = progression.Gates[i]
        local card = progression.Keycards[i]
        printTo(ply, string.format(
            "%s card=%s detour=%d branchPreferred=%s | gate edge=%s pathIndex=%d before=%s after=%s",
            PC.Cards[i].name,
            cellText(card.cell),
            card.graphDistanceFromSectorEntry or -1,
            boolText(card.branchPreferred),
            tostring(gate.edgeKey),
            gate.pathIndex or -1,
            cellText(gate.beforeCell),
            cellText(gate.afterCell)
        ))
    end
    local jail = progression.JailEdge
    printTo(ply, string.format(
        "jail edge=%s pathIndex=%d before/core=%s after/deborah=%s horizontal=%s",
        tostring(jail and jail.edgeKey),
        jail and jail.pathIndex or -1,
        cellText(jail and jail.beforeCell),
        cellText(jail and jail.afterCell),
        boolText(jail and jail.beforeCell and jail.afterCell and jail.beforeCell.z == jail.afterCell.z)
    ))
end)

local function debugTeleport(ply, target, label)
    if not IsValid(ply) or not target then return end
    RunManager:MarkUnranked("Milestone 2 objective debug teleport")
    ply:UnSpectate()
    ply:SetPos(target)
    ply:SetVelocity(-ply:GetVelocity())
    ply:ChatPrint("Debug teleport: " .. label)
end

concommand.Add("lod_m2_tp", function(ply, _, args)
    if not allowed(ply) or not IsValid(ply) then return end
    local graph = RunManager.State.Graph
    local progression = graph and graph.Progression
    if not RunManager.State.BuildReady or not progression then
        ply:ChatPrint("No validated Milestone 2 level is active.")
        return
    end

    local kind = string.lower(args[1] or "")
    if kind == "card" then
        local index = math.floor(tonumber(args[2]) or 1)
        local card = progression.Keycards[index]
        if not card then ply:ChatPrint("Card index must be 1-3.") return end
        debugTeleport(ply, LOD.MazeBuilder:CellCenter(card.cell) + Vector(0, 0, 24), PC.Cards[index].name .. " keycard")
        return
    end

    if kind == "gate" then
        local index = math.floor(tonumber(args[2]) or 1)
        local gate = progression.Gates[index]
        if not gate then ply:ChatPrint("Gate index must be 1-3.") return end
        debugTeleport(ply, LOD.MazeBuilder:CellCenter(gate.beforeCell) + Vector(0, 0, 24), PC.Cards[index].name .. " gate approach")
        return
    end

    if kind == "deborah" then
        debugTeleport(ply, LOD.MazeBuilder:CellCenter(progression.DeborahCell) + Vector(0, 0, 24), "Deborah chamber")
        return
    end

    ply:ChatPrint("Usage: lod_m2_tp card <1-3> | gate <1-3> | deborah")
end)

concommand.Add("lod_m2_seed_test", function(ply, _, args)
    if not allowed(ply) then return end
    local count = math.Clamp(math.floor(tonumber(args[1]) or 100), 1, LOD.Config.Debug.SeedTestMax)
    local base = RunManager.State.LevelSeed or 1
    local failures = 0
    local worstLayoutAttempt = 0
    local minDetour = math.huge
    local maxDetour = 0

    for i = 1, count do
        local seed = LOD.Seeds.Derive(base, "m2-seed-test:" .. i)
        local graph = RunManager:_GenerateProgressionLevel(seed)
        if not graph or not graph.Progression or not graph.Progression.Validation or
            not graph.Progression.Validation.valid or not validJailEdge(graph.Progression) then
            failures = failures + 1
        else
            worstLayoutAttempt = math.max(worstLayoutAttempt, graph.ProgressionLayoutAttempt or 1)
            for _, card in ipairs(graph.Progression.Keycards or {}) do
                local d = card.graphDistanceFromSectorEntry or 0
                minDetour = math.min(minDetour, d)
                maxDetour = math.max(maxDetour, d)
            end
        end
    end

    if minDetour == math.huge then minDetour = 0 end
    printTo(ply, string.format(
        "seed test generated=%d failures=%d worstLayoutAttempt=%d cardDetourRange=%d-%d jailEdges=horizontal-after-yellow result=%s",
        count, failures, worstLayoutAttempt, minDetour, maxDetour, failures == 0 and "PASS" or "FAIL"
    ))
end)

concommand.Add("lod_m2_audit", function(ply)
    if not allowed(ply) then return end
    local state = RunManager.State
    local graph = state.Graph
    local progression = graph and graph.Progression
    if not state.BuildReady or not progression then
        printTo(ply, "AUDIT FAIL: no validated progression level is active")
        return
    end

    local reasons = {}
    local function require(condition, reason)
        if not condition then reasons[#reasons + 1] = reason end
    end

    require(progression.Validation and progression.Validation.valid == true, "ordered progression validation false")
    require(#(progression.Gates or {}) == 3, "gate plan count is not 3")
    require(#(progression.Keycards or {}) == 3, "keycard plan count is not 3")
    require(validJailEdge(progression), "JailEdge is missing, vertical, or not after Yellow Gate")
    require(progression.JailEdge and graph.Edges and graph.Edges[progression.JailEdge.edgeKey] ~= nil,
        "JailEdge is not a canonical graph edge")
    require(progression.Validation and progression.Validation.orderedRoute ==
        "Start>Red Card>Red Gate>Blue Card>Blue Gate>Yellow Card>Yellow Gate>Jail Key>Jail Door>Deborah",
        "ordered route does not include Jail Key and Jail Door")
    require(progression.Gates[1].pathIndex < progression.Gates[2].pathIndex and progression.Gates[2].pathIndex < progression.Gates[3].pathIndex,
        "gate path indices are not strictly ordered")

    for i = 1, 3 do
        local card = progression.Keycards[i]
        require((card.graphDistanceFromSectorEntry or -1) >= PC.KeycardDetourMin,
            PC.Cards[i].name .. " card detour below configured minimum")
    end

    local gateEntities = ents.FindByClass("lod_gate")
    local cardEntities = ents.FindByClass("lod_keycard")
    local deborahEntities = ents.FindByClass("lod_deborah")
    require(#gateEntities == 3, "runtime gate entity count is " .. #gateEntities)
    require(#deborahEntities == 1, "runtime Deborah entity count is " .. #deborahEntities)

    local expectedCardsRemaining = 0
    for i = 1, 3 do if not (state.Cards and state.Cards[i]) then expectedCardsRemaining = expectedCardsRemaining + 1 end end
    require(#cardEntities == expectedCardsRemaining,
        string.format("runtime keycard count=%d expected=%d", #cardEntities, expectedCardsRemaining))

    local playedCount = table.Count(state.PlayedIdentities or {})
    local activeCount = RunManager:_ActiveCount()
    require(playedCount <= LOD.Config.Campaign.MaxPlayedIdentities, "played identity cap exceeded")
    require(activeCount <= LOD.Config.MaxActivePlayers, "active-player cap exceeded")

    for id, ps in pairs(state.PlayerState or {}) do
        require(ps.lives >= 0 and ps.lives <= LOD.Config.Lives.MaxLives, "invalid life count for " .. tostring(id))
        require(state.PlayedIdentities[id] == true, "player state exists without played identity ledger entry")
    end

    for _, gateEnt in ipairs(gateEntities) do
        local index = gateEnt:GetGateIndex()
        if index >= 1 and index <= 3 then
            require(gateEnt:GetOpened() == (state.GatesOpen and state.GatesOpen[index] == true),
                PC.Cards[index].name .. " gate entity/state mismatch")
        else
            require(false, "runtime gate has invalid index")
        end
    end

    local pass = #reasons == 0
    printTo(ply, string.format(
        "M2 AUDIT %s | level=%d layoutAttempt=%d gates=%d cardsRemaining=%d Deborah=%d played=%d active=%d checkpoint=%d objective=%d",
        pass and "PASS" or "FAIL",
        state.Level or -1,
        graph.ProgressionLayoutAttempt or -1,
        #gateEntities,
        #cardEntities,
        #deborahEntities,
        playedCount,
        activeCount,
        state.CheckpointIndex or -1,
        state.ObjectiveStage or -1
    ))
    if not pass then
        for _, reason in ipairs(reasons) do printTo(ply, "audit reason: " .. reason) end
    end
end)
