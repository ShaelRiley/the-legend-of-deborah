LOD = LOD or {}

local Loot = LOD.LootDirector
local RunManager = LOD.RunManager
if not Loot or not RunManager then return end

local MIN_COVERAGE = 0.70
local TARGET_COVERAGE = 0.76
local ACCURACY_ALLOWANCE = 0.72
local SMALL_PICKUP_DAMAGE_EQUIVALENT = 15
local WANDERERS_PER_FLOOR = 16
local MANDATORY_ROUTE_WANDERER_FRACTION = 0.25
local EXPECTED_WANDERER_HP = 14
local MAX_SUPPLEMENTS_PER_SECTOR = 4

local TIER_UNITS = {
    small = 1,
    medium = 2,
    large = 3
}

local function cellKey(cell)
    return cell and LOD.MazeGenerator.CellKey(cell.x, cell.y, cell.z) or nil
end

local function mandatoryAmmoSupplyUnits(plan, sector)
    local units = 0
    for _, node in ipairs(plan.nodes or {}) do
        if node.sector == sector and node.kind == "ammo" and node.role ~= "reward" then
            units = units + (TIER_UNITS[node.payload and node.payload.tier or "small"] or 1)
        end
    end
    return units
end

local function sectorDemandHP(plan, graph, sector)
    local authored = math.max(0, plan.expectedAuthoredHP and plan.expectedAuthoredHP[sector] or 0)
    local floors = math.max(1, tonumber(graph.Layers) or 1)

    -- The wandering population is persistent and not encoded in EncounterPlan.
    -- Budget only the conservative share expected to intersect an efficient
    -- mandatory route; optional hunting and prolonged backtracking are not funded.
    local wanderingTotal = floors * WANDERERS_PER_FLOOR
        * MANDATORY_ROUTE_WANDERER_FRACTION * EXPECTED_WANDERER_HP
    local wanderingShare = wanderingTotal / 4
    return authored + wanderingShare
end

local function coverageFor(plan, graph, sector)
    local demand = sectorDemandHP(plan, graph, sector)
    if demand <= 0 then return 1, 0, 0 end
    local units = mandatoryAmmoSupplyUnits(plan, sector)
    local supportedDamage = units * SMALL_PICKUP_DAMAGE_EQUIVALENT * ACCURACY_ALLOWANCE
    return supportedDamage / demand, demand, units
end

local function occupiedStaticCells(plan)
    local used = {}
    for _, node in ipairs(plan.nodes or {}) do
        local key = cellKey(node.cell)
        if key then used[key] = true end
    end
    return used
end

local function addSupplements(self, graph, plan, sector, needed)
    if needed <= 0 then return 0 end

    local candidates = self:_SectorCandidates(graph, sector)
    local rng = LOD.RNG.New(LOD.Seeds.Derive(plan.levelSeed,
        "loot-budget-supplement:" .. tostring(sector)))
    rng:Shuffle(candidates)

    local used = occupiedStaticCells(plan)
    local added = 0
    for _, cell in ipairs(candidates) do
        if added >= needed or added >= MAX_SUPPLEMENTS_PER_SECTOR then break end
        local key = cellKey(cell)
        if key and not used[key] then
            used[key] = true
            local tier = sector == 1 and "small" or "medium"
            self:_AddStaticNode(plan, cell, "ammo", {tier = tier}, sector,
                "budget-supplement", Vector(0, 0, 28))
            if plan.ammoNodes then plan.ammoNodes[sector] = (plan.ammoNodes[sector] or 0) + 1 end
            added = added + 1
        end
    end
    return added
end

local baseBuildStaticPlan = Loot.BuildStaticPlan
function Loot:BuildStaticPlan(graph)
    local ok, planOrErr = baseBuildStaticPlan(self, graph)
    if not ok then return ok, planOrErr end

    local plan = planOrErr
    plan.resourceBudget = {
        minCoverage = MIN_COVERAGE,
        targetCoverage = TARGET_COVERAGE,
        accuracyAllowance = ACCURACY_ALLOWANCE,
        wanderingFraction = MANDATORY_ROUTE_WANDERER_FRACTION,
        sectors = {},
        supplements = 0,
        underTarget = false
    }

    for sector = 1, 4 do
        local coverage, demand, units = coverageFor(plan, graph, sector)
        local supplements = 0

        if coverage < MIN_COVERAGE then
            local targetUnits = math.ceil(
                (demand * TARGET_COVERAGE)
                / (SMALL_PICKUP_DAMAGE_EQUIVALENT * ACCURACY_ALLOWANCE))
            local missingUnits = math.max(0, targetUnits - units)
            local perNodeUnits = sector == 1 and 1 or 2
            local neededNodes = math.ceil(missingUnits / perNodeUnits)
            supplements = addSupplements(self, graph, plan, sector, neededNodes)
            plan.resourceBudget.supplements = plan.resourceBudget.supplements + supplements
            coverage, demand, units = coverageFor(plan, graph, sector)
        end

        local pass = coverage >= MIN_COVERAGE
        if not pass then plan.resourceBudget.underTarget = true end
        plan.resourceBudget.sectors[sector] = {
            coverage = coverage,
            demandHP = demand,
            supplyUnits = units,
            supplements = supplements,
            pass = pass
        }
    end

    graph.LootPlan = plan
    self.StaticPlan = plan
    return true, plan
end

concommand.Add("lod_loot_budget_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local plan = Loot.StaticPlan
    local budget = plan and plan.resourceBudget
    if not budget then
        local line = "no committed resource budget result=FAIL"
        print("[LOD:LOOT-BUDGET] " .. line)
        if IsValid(ply) then ply:ChatPrint(line) end
        return
    end

    local parts = {}
    for sector = 1, 4 do
        local data = budget.sectors[sector] or {}
        parts[#parts + 1] = string.format("S%d=%.0f%%(%dU,+%d)", sector,
            (data.coverage or 0) * 100, data.supplyUnits or 0, data.supplements or 0)
    end
    local result = budget.underTarget and "WARN" or "PASS"
    local line = string.format("%s supplements=%d target=70-85%% result=%s",
        table.concat(parts, " "), budget.supplements or 0, result)
    print("[LOD:LOOT-BUDGET] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
