#!/usr/bin/env python3
"""Apply V19 coverage-first company-brand placement.

V19 keeps the 40% global ceiling and hard no-touching invariant, but makes player-space
coverage the primary selection objective. Company paint gets a decal-safe eligibility
rule: duplicate logical faces remain forbidden, while perpendicular walls touching only
an endpoint no longer reject the inset 86%-wide spray rectangle. Wayfinding keeps V15's
stricter full-face rule.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one occurrence, found {count}")
    return text.replace(old, new, 1)


def patch_walls():
    text = WALLS.read_text(encoding="utf-8")
    if "brandSurfaceEligible = brandSurfaceEligibility[segmentIndex] == true" in text:
        return False

    anchor = '''local function rebuildWorldCache()\n'''
    helper = r'''-- Company paint is inset to 86% of the broad face, so a perpendicular wall that
-- merely meets the extreme endpoint does not clip the actual spray rectangle. Keep
-- duplicate logical faces ineligible, but otherwise allow the central decal-safe area.
-- Wayfinding continues to use the stricter fullSurfaceEligible classifier above.
local function buildBrandSurfaceEligibility(logical)
    local counts = {}
    local infoByIndex = {}
    for index, segment in ipairs(logical or {}) do
        local info = segmentFaceInfo(segment)
        infoByIndex[index] = info
        if info then counts[info.edgeKey] = (counts[info.edgeKey] or 0) + 1 end
    end

    local eligible = {}
    for index, info in ipairs(infoByIndex) do
        eligible[index] = info ~= nil and counts[info.edgeKey] == 1
    end
    return eligible
end

local function rebuildWorldCache()
'''
    text = replace_once(text, anchor, helper, "brand-surface helper")

    text = replace_once(
        text,
        '''    local fullSurfaceEligibility = buildFullSurfaceEligibility(Wall.logical or {})\n    for segmentIndex, segment in ipairs(Wall.logical or {}) do\n''',
        '''    local fullSurfaceEligibility = buildFullSurfaceEligibility(Wall.logical or {})\n    local brandSurfaceEligibility = buildBrandSurfaceEligibility(Wall.logical or {})\n    for segmentIndex, segment in ipairs(Wall.logical or {}) do\n''',
        "brand eligibility cache",
    )

    text = replace_once(
        text,
        '''                    fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true,\n                    overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil,\n''',
        '''                    fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true,\n                    brandSurfaceEligible = brandSurfaceEligibility[segmentIndex] == true,\n                    overlayDirection = segment[4],\n                    overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil,\n''',
        "brand eligibility instance metadata",
    )

    WALLS.write_text(text, encoding="utf-8")
    return True


def patch_branding():
    text = BRANDING.read_text(encoding="utf-8")
    if "container-brand-coverage:v5" in text and "BRAND_COVERAGE_RADIUS_CELLS = 3" in text:
        return False

    text = replace_once(
        text,
        '''local BRAND_GLOBAL_CAP_FRACTION = 0.40\nlocal BRAND_SOFT_SPACING_CELLS = 2\nlocal BRAND_LOWER_TIER_BIAS = 0.35\n''',
        '''local BRAND_GLOBAL_CAP_FRACTION = 0.40\nlocal BRAND_COVERAGE_RADIUS_CELLS = 3\nlocal BRAND_COVERAGE_GOAL = 0.92\nlocal BRAND_LOWER_TIER_BIAS = 0.35\n''',
        "coverage constants",
    )

    start = text.find("local placementWorldRef = nil")
    end = text.find("\nlocal function sprayPaintColor(instance)", start)
    if start < 0 or end < 0:
        raise SystemExit("brand placement block boundaries not found")

    replacement = r'''local placementWorldRef = nil
local placementSeed = nil
local placementMarkedCount = -1
local brandedCount = 0
local brandableCount = 0
local geometryBlockedCount = 0
local targetBrandCount = 0
local placeableCount = 0
local globalBrandCap = 0
local relaxedGeometryCount = 0
local coverageObservedCount = 0
local coverageCoveredCount = 0
local coveragePrefixCount = 0

local DIR_DELTA = {
    [1] = {0, 1},
    [2] = {1, 0},
    [3] = {0, -1},
    [4] = {-1, 0}
}

local function placementSort(a, b)
    local ia, ib = a.instance, b.instance
    if (ia.floor or 0) ~= (ib.floor or 0) then return (ia.floor or 0) < (ib.floor or 0) end
    if (ia.quadrant or 0) ~= (ib.quadrant or 0) then return (ia.quadrant or 0) < (ib.quadrant or 0) end
    if (ia.gridY or 0) ~= (ib.gridY or 0) then return (ia.gridY or 0) < (ib.gridY or 0) end
    if (ia.gridX or 0) ~= (ib.gridX or 0) then return (ia.gridX or 0) < (ib.gridX or 0) end
    if (ia.stackIndex or 0) ~= (ib.stackIndex or 0) then
        return (ia.stackIndex or 0) < (ib.stackIndex or 0)
    end
    return a.index < b.index
end

local function currentMarkedCount(world)
    local count = 0
    for _, instance in ipairs(world or {}) do
        if instance.marked then count = count + 1 end
    end
    return count
end

-- Physical contact is always forbidden: vertical partners on one logical wall edge
-- touch, and same-tier collinear neighbors sharing an endpoint touch end-to-end.
local function candidateConflicts(instance, occupiedEdges, occupiedEndpoints)
    local edgeKey = instance.overlayEdgeKey
    local endpointA = instance.overlayEndpointA
    local endpointB = instance.overlayEndpointB
    local orientation = instance.overlayOrientation
    if not edgeKey or not endpointA or not endpointB or not orientation then return true end
    if occupiedEdges[edgeKey] then return true end

    local stackKey = tostring(instance.stackIndex or 0) .. ":" .. orientation
    local endpoints = occupiedEndpoints[stackKey]
    return endpoints and (endpoints[endpointA] or endpoints[endpointB]) or false
end

local function reserveCandidate(instance, occupiedEdges, occupiedEndpoints)
    occupiedEdges[instance.overlayEdgeKey] = true
    local stackKey = tostring(instance.stackIndex or 0) .. ":" .. instance.overlayOrientation
    local endpoints = occupiedEndpoints[stackKey]
    if not endpoints then
        endpoints = {}
        occupiedEndpoints[stackKey] = endpoints
    end
    endpoints[instance.overlayEndpointA] = true
    endpoints[instance.overlayEndpointB] = true
end

local function inBounds(x, y)
    return x >= 1 and x <= MC.Width and y >= 1 and y <= MC.Height
end

local function observationKey(floor, x, y)
    return string.format("%d:%d:%d", floor or 0, x, y)
end

local function passageKey(floor, x1, y1, x2, y2)
    if x2 < x1 or (x2 == x1 and y2 < y1) then
        x1, x2 = x2, x1
        y1, y2 = y2, y1
    end
    return string.format("%d:%d:%d>%d:%d", floor or 0, x1, y1, x2, y2)
end

local function buildBlockedPassages()
    local blocked = {}
    for _, segment in ipairs(Wall.logical or {}) do
        local x = tonumber(segment[1]) or 0
        local y = tonumber(segment[2]) or 0
        local floor = tonumber(segment[3]) or 0
        local delta = DIR_DELTA[tonumber(segment[4]) or 0]
        if delta then
            blocked[passageKey(floor, x, y, x + delta[1], y + delta[2])] = true
        end
    end
    return blocked
end

-- Approximate first-person visibility from the actual maze topology, not Euclidean
-- distance through walls. The company stencil is rendered on whichever broad side the
-- player occupies, so seed the neighborhood from both cells adjacent to the wall and
-- flood through open passages for a short corridor-aware radius.
local function coverageForInstance(instance, blocked)
    local floor = instance.floor or 0
    local starts = {{instance.gridX or 0, instance.gridY or 0}}
    local delta = DIR_DELTA[instance.overlayDirection or 0]
    if delta then
        local nx = (instance.gridX or 0) + delta[1]
        local ny = (instance.gridY or 0) + delta[2]
        if inBounds(nx, ny) then starts[#starts + 1] = {nx, ny} end
    end

    local covered = {}
    local visited = {}
    local queue = {}
    local head = 1
    for _, cell in ipairs(starts) do
        local x, y = cell[1], cell[2]
        if inBounds(x, y) then
            local key = observationKey(floor, x, y)
            if not visited[key] then
                visited[key] = true
                queue[#queue + 1] = {x = x, y = y, distance = 0}
            end
        end
    end

    while head <= #queue do
        local current = queue[head]
        head = head + 1
        covered[observationKey(floor, current.x, current.y)] = true
        if current.distance < BRAND_COVERAGE_RADIUS_CELLS then
            for _, move in pairs(DIR_DELTA) do
                local nx = current.x + move[1]
                local ny = current.y + move[2]
                if inBounds(nx, ny)
                    and not blocked[passageKey(floor, current.x, current.y, nx, ny)]
                then
                    local key = observationKey(floor, nx, ny)
                    if not visited[key] then
                        visited[key] = true
                        queue[#queue + 1] = {
                            x = nx,
                            y = ny,
                            distance = current.distance + 1
                        }
                    end
                end
            end
        end
    end
    return covered
end

local function floorDistanceSquared(a, b)
    local dx = (a.gridX or 0) - (b.gridX or 0)
    local dy = (a.gridY or 0) - (b.gridY or 0)
    return dx * dx + dy * dy
end

local function deterministicNoise(seed, candidate)
    local token = string.format(
        "container-brand-coverage:v5:%d:%d:%d:%d:%d",
        candidate.index or 0,
        candidate.instance.floor or 0,
        candidate.instance.gridX or 0,
        candidate.instance.gridY or 0,
        candidate.instance.stackIndex or 0
    )
    local derived = tonumber(LOD.Seeds.Derive(seed, token)) or 0
    return (derived % 10000) / 10000
end

local function minChosenDistanceSquared(instance, chosen)
    if #chosen == 0 then return math.huge end
    local best = math.huge
    for _, item in ipairs(chosen) do
        local distance = floorDistanceSquared(instance, item.instance)
        if distance < best then best = distance end
    end
    return best
end

local function coverageGain(candidate, covered)
    local gain = 0
    for key in pairs(candidate.coverage or {}) do
        if not covered[key] then gain = gain + 1 end
    end
    return gain
end

local function pickCoverageCandidate(candidates, chosen, covered,
    occupiedEdges, occupiedEndpoints, seed)
    local best = nil
    local bestGain = -1
    local bestDistance = -1
    local bestVisibility = -1
    local bestNoise = -1

    for _, candidate in ipairs(candidates) do
        local instance = candidate.instance
        if not candidate.selected
            and not candidateConflicts(instance, occupiedEdges, occupiedEndpoints)
        then
            local gain = coverageGain(candidate, covered)
            local distance = minChosenDistanceSquared(instance, chosen)
            local visibility = (instance.stackIndex or 0) == 0 and BRAND_LOWER_TIER_BIAS or 0
            local noise = deterministicNoise(seed, candidate)
            if gain > bestGain
                or (gain == bestGain and distance > bestDistance)
                or (gain == bestGain and distance == bestDistance and visibility > bestVisibility)
                or (gain == bestGain and distance == bestDistance
                    and visibility == bestVisibility and noise > bestNoise)
            then
                best = candidate
                bestGain = gain
                bestDistance = distance
                bestVisibility = visibility
                bestNoise = noise
            end
        end
    end
    return best, bestGain
end

local function selectCoverageOrder(candidates, floor, seed, blocked)
    local chosen = {}
    local occupiedEdges = {}
    local occupiedEndpoints = {}
    local covered = {}
    local coveredCount = 0
    local observationCount = MC.Width * MC.Height
    local goalCount = math.ceil(observationCount * BRAND_COVERAGE_GOAL)
    local prefixCount = 0

    for _, candidate in ipairs(candidates) do
        candidate.coverage = coverageForInstance(candidate.instance, blocked)
    end

    while true do
        local candidate = pickCoverageCandidate(
            candidates, chosen, covered, occupiedEdges, occupiedEndpoints, seed
        )
        if not candidate then break end

        candidate.selected = true
        reserveCandidate(candidate.instance, occupiedEdges, occupiedEndpoints)
        chosen[#chosen + 1] = candidate
        for key in pairs(candidate.coverage or {}) do
            if not covered[key] then
                covered[key] = true
                coveredCount = coveredCount + 1
            end
        end
        if prefixCount == 0 and coveredCount >= goalCount then
            prefixCount = #chosen
        end
    end

    if prefixCount == 0 then prefixCount = #chosen end
    return {
        floor = floor,
        chosen = chosen,
        coveragePrefix = prefixCount,
        observationCount = observationCount
    }
end

local function allocateFloorCounts(groups, target)
    local allocation = {}
    if target <= 0 or #groups == 0 then return allocation end

    local totalChosen = 0
    local totalCoveragePrefix = 0
    for index, group in ipairs(groups) do
        allocation[index] = 0
        totalChosen = totalChosen + #group.chosen
        totalCoveragePrefix = totalCoveragePrefix + math.min(#group.chosen, group.coveragePrefix or 0)
    end
    if target >= totalChosen then
        for index, group in ipairs(groups) do allocation[index] = #group.chosen end
        return allocation
    end

    -- Spend the constrained budget on coverage prefixes first. If even those exceed
    -- the 40% ceiling, preserve at least one mark per floor when possible and then
    -- distribute proportionally by each floor's coverage-prefix demand.
    local baselineTarget = math.min(target, totalCoveragePrefix)
    if baselineTarget >= #groups then
        for index, group in ipairs(groups) do
            if #group.chosen > 0 then allocation[index] = 1 end
        end
    end

    local allocated = 0
    for _, count in pairs(allocation) do allocated = allocated + count end
    local remaining = baselineTarget - allocated
    while remaining > 0 do
        local bestIndex = nil
        local bestNeed = -1
        for index, group in ipairs(groups) do
            local need = math.min(#group.chosen, group.coveragePrefix or 0) - (allocation[index] or 0)
            if need > bestNeed and need > 0 then
                bestNeed = need
                bestIndex = index
            end
        end
        if not bestIndex then break end
        allocation[bestIndex] = (allocation[bestIndex] or 0) + 1
        remaining = remaining - 1
    end

    allocated = 0
    for _, count in pairs(allocation) do allocated = allocated + count end
    remaining = target - allocated
    while remaining > 0 do
        local bestIndex = nil
        local bestCapacity = -1
        for index, group in ipairs(groups) do
            local capacity = #group.chosen - (allocation[index] or 0)
            if capacity > bestCapacity and capacity > 0 then
                bestCapacity = capacity
                bestIndex = index
            end
        end
        if not bestIndex then break end
        allocation[bestIndex] = (allocation[bestIndex] or 0) + 1
        remaining = remaining - 1
    end
    return allocation
end

local function rebuildBrandPlacement(world)
    brandedCount = 0
    brandableCount = 0
    geometryBlockedCount = 0
    targetBrandCount = 0
    placeableCount = 0
    relaxedGeometryCount = 0
    coverageObservedCount = 0
    coverageCoveredCount = 0
    coveragePrefixCount = 0
    globalBrandCap = math.floor(#(world or {}) * BRAND_GLOBAL_CAP_FRACTION)

    local byFloor = {}
    for index, instance in ipairs(world or {}) do
        instance.companyBranded = false
        if instance.brandSurfaceEligible ~= true then
            geometryBlockedCount = geometryBlockedCount + 1
        elseif not instance.marked then
            if instance.fullSurfaceEligible ~= true then
                relaxedGeometryCount = relaxedGeometryCount + 1
            end
            local floor = instance.floor or 0
            local group = byFloor[floor]
            if not group then
                group = {}
                byFloor[floor] = group
            end
            group[#group + 1] = {index = index, instance = instance, selected = false}
            brandableCount = brandableCount + 1
        end
    end

    local seed = tonumber(Wall.seed) or 1
    local blocked = buildBlockedPassages()
    local floors = {}
    for floor in pairs(byFloor) do floors[#floors + 1] = floor end
    table.sort(floors)

    local groups = {}
    for _, floor in ipairs(floors) do
        local candidates = byFloor[floor]
        table.sort(candidates, placementSort)
        local floorSeed = LOD.Seeds.Derive(seed, "container-brand-coverage:v5:floor:" .. tostring(floor))
        local group = selectCoverageOrder(candidates, floor, floorSeed, blocked)
        groups[#groups + 1] = group
        placeableCount = placeableCount + #group.chosen
        coverageObservedCount = coverageObservedCount + group.observationCount
        coveragePrefixCount = coveragePrefixCount + group.coveragePrefix
    end

    targetBrandCount = math.min(placeableCount, globalBrandCap)
    local allocation = allocateFloorCounts(groups, targetBrandCount)
    local finalCovered = {}

    for index, group in ipairs(groups) do
        local count = math.min(#group.chosen, allocation[index] or 0)
        for chosenIndex = 1, count do
            local item = group.chosen[chosenIndex]
            if item and item.instance then
                item.instance.companyBranded = true
                brandedCount = brandedCount + 1
                for key in pairs(item.coverage or {}) do finalCovered[key] = true end
            end
        end
    end
    for _ in pairs(finalCovered) do coverageCoveredCount = coverageCoveredCount + 1 end

    placementWorldRef = world
    placementSeed = tonumber(Wall.seed) or 0
    placementMarkedCount = currentMarkedCount(world)
end

local function ensureBrandPlacement(world)
    local seed = tonumber(Wall.seed) or 0
    local marked = currentMarkedCount(world)
    if placementWorldRef ~= world or placementSeed ~= seed or placementMarkedCount ~= marked then
        rebuildBrandPlacement(world)
    end
end

hook.Add("Think", "LOD_RebuildSparseContainerBrandPlacement", function()
    local world = Wall.world or {}
    if #world == 0 then return end
    ensureBrandPlacement(world)
end)
'''
    text = text[:start] + replacement + text[end:]

    text = text.replace(
        "and instance.fullSurfaceEligible == true and not instance.marked",
        "and instance.brandSurfaceEligible == true and not instance.marked",
        1,
    )

    old_status_start = '''        "[LOD] container brand: seed=%s brand=%s atlas=%s cell=%s,%s material=%s path=%s mode=vertexlit-spray-v8-alphatest-dither width=%.2f height=%.2f placement=%d/%d placeable=%d all=%d cap=%.0f%% capCount=%d targetCount=%d separation=touching-never distribution=blue-noise-packed softSpacing=%dcells lowerBias=%.2f geometryBlocked=%d relaxed=%d",\n'''
    new_status_start = '''        "[LOD] container brand: seed=%s brand=%s atlas=%s cell=%s,%s material=%s path=%s mode=vertexlit-spray-v8-alphatest-dither width=%.2f height=%.2f placement=%d/%d placeable=%d all=%d cap=%.0f%% capCount=%d targetCount=%d separation=touching-never distribution=coverage-first radius=%dcells coverage=%d/%d(%.0f%%) goal=%.0f%% coveragePrefix=%d geometryBlocked=%d decalRelaxed=%d lowerBias=%.2f",\n'''
    text = replace_once(text, old_status_start, new_status_start, "V19 status format")

    old_args = '''        brandedCount,\n        brandableCount,\n        placeableCount,\n        #world,\n        BRAND_GLOBAL_CAP_FRACTION * 100,\n        globalBrandCap,\n        targetBrandCount,\n        BRAND_SOFT_SPACING_CELLS,\n        BRAND_LOWER_TIER_BIAS,\n        geometryBlockedCount,\n        relaxedSpacingCount\n'''
    new_args = '''        brandedCount,\n        brandableCount,\n        placeableCount,\n        #world,\n        BRAND_GLOBAL_CAP_FRACTION * 100,\n        globalBrandCap,\n        targetBrandCount,\n        BRAND_COVERAGE_RADIUS_CELLS,\n        coverageCoveredCount,\n        coverageObservedCount,\n        coverageObservedCount > 0 and (coverageCoveredCount / coverageObservedCount) * 100 or 0,\n        BRAND_COVERAGE_GOAL * 100,\n        coveragePrefixCount,\n        geometryBlockedCount,\n        relaxedGeometryCount,\n        BRAND_LOWER_TIER_BIAS\n'''
    text = replace_once(text, old_args, new_args, "V19 status arguments")

    BRANDING.write_text(text, encoding="utf-8")
    return True


def patch_docs():
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V19 coverage-first company branding"
    if marker in text:
        return False

    appendix = r'''

## V19 coverage-first company branding

V18's dense 40% ceiling remains, but percentage is no longer the placement objective.
V19 treats the maze's player-space coverage as primary. Each floor's maze cells are used
as observation points. For every company-brand candidate, the client derives a short
three-cell neighborhood by flooding through open passages in the authoritative logical
wall manifest from both cells adjacent to the cargo wall. Candidates are then selected
by maximum newly covered observation cells, with spatial distance, lower-tier visibility,
and seeded noise as deterministic tie-breakers.

The coverage phase aims to place a company mark within the three-cell topological
neighborhood of roughly 92% of maze cells whenever topology, geometry eligibility, and
the no-touching invariant allow it. After coverage is satisfied, selection continues to
pack additional legal brands up to the existing global ceiling of 40% of all containers.
If that ceiling binds, coverage-prefix selections receive budget before density fill.

Company branding now has a decal-safe eligibility classifier separate from wayfinding.
The spray occupies only the central 86% of a broad cargo side, so a perpendicular wall
that merely meets the extreme endpoint no longer disqualifies the company stencil; the
actual inset spray rectangle remains clear. Duplicate logical faces remain forbidden.
Wayfinding plates continue to require V15's stricter full-face eligibility.

Physical separation remains absolute: vertically stacked partners and same-tier
collinear neighbors that touch end-to-end can never both carry company branding.
'''
    DOCS.write_text(text.rstrip() + appendix + "\n", encoding="utf-8")
    return True


def main():
    changed = {
        "walls": patch_walls(),
        "branding": patch_branding(),
        "docs": patch_docs(),
    }
    print("V19 coverage-first branding patch:", changed)


if __name__ == "__main__":
    main()
