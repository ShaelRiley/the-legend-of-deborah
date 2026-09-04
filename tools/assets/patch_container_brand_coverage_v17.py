#!/usr/bin/env python3
"""Apply V17 blue-noise company-brand placement.

V17 keeps V15 full-face eligibility and V16 hard no-touching constraints, but removes
the brittle one-in-three quota. It aims for a visually useful ~26% of eligible ordinary
containers, spreads marks across each floor with deterministic farthest-point sampling,
and gives lower-tier containers a slight visibility preference. A two-cell soft spacing
pass prevents clusters; if a pathological layout cannot hit the target, spacing relaxes
while physical touching remains forbidden.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def patch_branding():
    text = BRANDING.read_text(encoding="utf-8")
    if "container-brand-coverage:v3" in text:
        return False

    text = text.replace(
        "local BRANDING_DENOMINATOR = 3",
        "local BRAND_TARGET_FRACTION = 0.26\nlocal BRAND_SOFT_SPACING_CELLS = 2\nlocal BRAND_LOWER_TIER_BIAS = 0.35",
        1,
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
local relaxedSpacingCount = 0

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

-- Physical contact is a hard exclusion. Upper/lower partners on one wall edge touch,
-- and same-tier collinear neighbors sharing an endpoint touch end-to-end.
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

local function floorDistanceSquared(a, b)
    local dx = (a.gridX or 0) - (b.gridX or 0)
    local dy = (a.gridY or 0) - (b.gridY or 0)
    return dx * dx + dy * dy
end

local function deterministicNoise(seed, candidate)
    local token = string.format(
        "container-brand-coverage:v3:%d:%d:%d:%d:%d",
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

local function pickBestCandidate(candidates, chosen, occupiedEdges, occupiedEndpoints,
    seed, minimumDistanceSquared)
    local best = nil
    local bestDistance = -1
    local bestVisibility = -1
    local bestNoise = -1

    for _, candidate in ipairs(candidates) do
        local instance = candidate.instance
        if not candidate.selected
            and not candidateConflicts(instance, occupiedEdges, occupiedEndpoints)
        then
            local distance = minChosenDistanceSquared(instance, chosen)
            if distance >= minimumDistanceSquared then
                -- Favor eye-level/lower containers only as a tie-breaker. Spatial
                -- coverage remains the dominant criterion, which avoids visible clumps.
                local visibility = (instance.stackIndex or 0) == 0 and BRAND_LOWER_TIER_BIAS or 0
                local noise = deterministicNoise(seed, candidate)
                if distance > bestDistance
                    or (distance == bestDistance and visibility > bestVisibility)
                    or (distance == bestDistance and visibility == bestVisibility and noise > bestNoise)
                then
                    best = candidate
                    bestDistance = distance
                    bestVisibility = visibility
                    bestNoise = noise
                end
            end
        end
    end
    return best
end

local function selectBlueNoise(candidates, seed, target)
    local chosen = {}
    local occupiedEdges = {}
    local occupiedEndpoints = {}
    local softDistanceSquared = BRAND_SOFT_SPACING_CELLS * BRAND_SOFT_SPACING_CELLS

    -- Pass one: strong two-cell spacing. This is what creates a believable, evenly
    -- distributed industrial-yard impression instead of random deserts and clusters.
    while #chosen < target do
        local candidate = pickBestCandidate(
            candidates, chosen, occupiedEdges, occupiedEndpoints,
            seed, softDistanceSquared
        )
        if not candidate then break end
        candidate.selected = true
        reserveCandidate(candidate.instance, occupiedEdges, occupiedEndpoints)
        chosen[#chosen + 1] = candidate
    end

    -- Pass two: fill toward the visual-density target if necessary, but NEVER relax
    -- physical contact. This only relaxes the aesthetic two-cell cushion.
    while #chosen < target do
        local candidate = pickBestCandidate(
            candidates, chosen, occupiedEdges, occupiedEndpoints,
            seed, 0
        )
        if not candidate then break end
        candidate.selected = true
        reserveCandidate(candidate.instance, occupiedEdges, occupiedEndpoints)
        chosen[#chosen + 1] = candidate
        relaxedSpacingCount = relaxedSpacingCount + 1
    end

    return chosen
end

local function rebuildBrandPlacement(world)
    brandedCount = 0
    brandableCount = 0
    geometryBlockedCount = 0
    targetBrandCount = 0
    relaxedSpacingCount = 0

    local byFloor = {}
    for index, instance in ipairs(world or {}) do
        instance.companyBranded = false
        if instance.fullSurfaceEligible ~= true then
            geometryBlockedCount = geometryBlockedCount + 1
        elseif not instance.marked then
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
    local floors = {}
    for floor in pairs(byFloor) do floors[#floors + 1] = floor end
    table.sort(floors)

    for _, floor in ipairs(floors) do
        local candidates = byFloor[floor]
        table.sort(candidates, placementSort)
        local target = math.floor(#candidates * BRAND_TARGET_FRACTION + 0.5)
        if #candidates >= 4 then target = math.max(1, target) end
        targetBrandCount = targetBrandCount + target

        local floorSeed = LOD.Seeds.Derive(seed, "container-brand-coverage:v3:floor:" .. tostring(floor))
        local chosen = selectBlueNoise(candidates, floorSeed, target)
        for _, item in ipairs(chosen) do
            item.instance.companyBranded = true
            brandedCount = brandedCount + 1
        end
    end

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

    old_status = "placement=%d/%d target=1/%d targetCount=%d separation=touching-never geometryBlocked=%d attempts=%d"
    new_status = "placement=%d/%d target=%.0f%% targetCount=%d separation=touching-never distribution=blue-noise softSpacing=%dcells lowerBias=%.2f geometryBlocked=%d relaxed=%d"
    if old_status not in text:
        raise SystemExit("V16 brand status format not found")
    text = text.replace(old_status, new_status, 1)

    old_args = '''        brandedCount,\n        brandableCount,\n        BRANDING_DENOMINATOR,\n        targetBrandCount,\n        geometryBlockedCount,\n        placementAttempts\n'''
    new_args = '''        brandedCount,\n        brandableCount,\n        BRAND_TARGET_FRACTION * 100,\n        targetBrandCount,\n        BRAND_SOFT_SPACING_CELLS,\n        BRAND_LOWER_TIER_BIAS,\n        geometryBlockedCount,\n        relaxedSpacingCount\n'''
    if old_args not in text:
        raise SystemExit("V16 brand status arguments not found")
    text = text.replace(old_args, new_args, 1)

    BRANDING.write_text(text, encoding="utf-8")
    return True


def patch_docs():
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V17 verisimilitude-oriented brand coverage"
    if marker in text:
        return False

    appendix = r'''

## V17 verisimilitude-oriented brand coverage

Raw one-in-N branding quotas are retired. Footage review showed that the V16 independent
set could satisfy a global numerical target while still leaving long first-person views
visually empty. V17 therefore treats *coverage* as the presentation goal.

After full-face geometry filtering and wayfinding reservation, each dungeon floor targets
approximately 26% of its remaining ordinary containers. Placement uses deterministic
farthest-point (blue-noise-like) sampling in maze-grid space, with a two-cell soft spacing
cushion and a small lower-tier preference so marks are more likely to enter the player's
natural first-person sight line. The intent is typically one visible company mark, with two
or occasionally three in long views, rather than either blank corridors or logo walls.

The no-touching rule remains absolute. Upper/lower partners on one logical wall edge can
never both be branded, and same-tier collinear neighbors that share an endpoint can never
both be branded. If the two-cell aesthetic cushion prevents reaching the target, V17 may
relax that cushion while preserving the physical no-touching invariant. Full-surface
eligibility remains authoritative, so clipped corners and other partial faces stay clean.
'''
    DOCS.write_text(text.rstrip() + appendix + "\n", encoding="utf-8")
    return True


def main():
    changed = {
        "branding": patch_branding(),
        "docs": patch_docs(),
    }
    print("V17 brand coverage patch:", changed)


if __name__ == "__main__":
    main()
