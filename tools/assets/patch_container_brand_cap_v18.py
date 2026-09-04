#!/usr/bin/env python3
"""Apply V18 dense company branding with a global 40% ceiling.

V18 keeps V15 full-face eligibility and the V16/V17 hard no-touching rule. It no
longer aims for a fixed percentage of eligible containers. Instead it computes a
dense non-touching blue-noise set on every floor, then brands all of that set unless
doing so would exceed 40% of *all* container instances, eligible or otherwise. If the
global ceiling binds, floor-balanced prefixes of the blue-noise selections preserve
coverage and verisimilitude.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one occurrence, found {count}")
    return text.replace(old, new, 1)


def patch_branding():
    text = BRANDING.read_text(encoding="utf-8")
    if "BRAND_GLOBAL_CAP_FRACTION = 0.40" in text and "container-brand-coverage:v4" in text:
        return False

    text = replace_once(
        text,
        "local BRAND_TARGET_FRACTION = 0.26",
        "local BRAND_GLOBAL_CAP_FRACTION = 0.40",
        "global branding cap",
    )

    text = text.replace("container-brand-coverage:v3:", "container-brand-coverage:v4:")

    start = text.find("local function rebuildBrandPlacement(world)")
    end = text.find("\nlocal function ensureBrandPlacement(world)", start)
    if start < 0 or end < 0:
        raise SystemExit("rebuildBrandPlacement boundaries not found")

    replacement = r'''local placeableCount = 0
local globalBrandCap = 0

local function allocateFloorCounts(groups, target)
    local allocation = {}
    if target <= 0 or #groups == 0 then return allocation end

    local allocated = 0
    -- Preserve visual coverage across dungeon floors before spending the remaining
    -- global budget proportionally. Every floor with a placeable brand gets one when
    -- the cap is large enough to support that baseline.
    if target >= #groups then
        for index, group in ipairs(groups) do
            if #group.chosen > 0 then
                allocation[index] = 1
                allocated = allocated + 1
            else
                allocation[index] = 0
            end
        end
    else
        for index = 1, #groups do allocation[index] = 0 end
    end

    local remaining = target - allocated
    if remaining <= 0 then return allocation end

    local residualCapacity = 0
    for index, group in ipairs(groups) do
        residualCapacity = residualCapacity + math.max(0, #group.chosen - (allocation[index] or 0))
    end
    if residualCapacity <= 0 then return allocation end

    local remainders = {}
    local used = 0
    for index, group in ipairs(groups) do
        local capacity = math.max(0, #group.chosen - (allocation[index] or 0))
        local exact = remaining * capacity / residualCapacity
        local base = math.min(capacity, math.floor(exact))
        allocation[index] = (allocation[index] or 0) + base
        used = used + base
        remainders[#remainders + 1] = {
            index = index,
            fraction = exact - math.floor(exact),
            floor = group.floor or 0,
            capacity = capacity - base
        }
    end

    table.sort(remainders, function(a, b)
        if a.fraction ~= b.fraction then return a.fraction > b.fraction end
        return a.floor < b.floor
    end)

    local left = remaining - used
    while left > 0 do
        local progressed = false
        for _, item in ipairs(remainders) do
            if left <= 0 then break end
            if item.capacity > 0 then
                allocation[item.index] = (allocation[item.index] or 0) + 1
                item.capacity = item.capacity - 1
                left = left - 1
                progressed = true
            end
        end
        if not progressed then break end
    end
    return allocation
end

local function rebuildBrandPlacement(world)
    brandedCount = 0
    brandableCount = 0
    geometryBlockedCount = 0
    targetBrandCount = 0
    relaxedSpacingCount = 0
    placeableCount = 0
    globalBrandCap = math.floor(#(world or {}) * BRAND_GLOBAL_CAP_FRACTION)

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

    -- First find the dense, physically legal set. selectBlueNoise starts with broad
    -- visual spacing, then relaxes only that aesthetic cushion until the hard
    -- no-touching graph has no more candidates.
    local groups = {}
    for _, floor in ipairs(floors) do
        local candidates = byFloor[floor]
        table.sort(candidates, placementSort)
        local floorSeed = LOD.Seeds.Derive(seed, "container-brand-coverage:v4:floor:" .. tostring(floor))
        local chosen = selectBlueNoise(candidates, floorSeed, #candidates)
        groups[#groups + 1] = {floor = floor, chosen = chosen}
        placeableCount = placeableCount + #chosen
    end

    targetBrandCount = math.min(placeableCount, globalBrandCap)
    local allocation = allocateFloorCounts(groups, targetBrandCount)

    -- Prefixes of each blue-noise list retain the widest coverage. Any subset of the
    -- already non-touching chosen set remains non-touching, so enforcing the global
    -- 40% ceiling cannot introduce a contact violation.
    for index, group in ipairs(groups) do
        local count = math.min(#group.chosen, allocation[index] or 0)
        for chosenIndex = 1, count do
            local item = group.chosen[chosenIndex]
            if item and item.instance then
                item.instance.companyBranded = true
                brandedCount = brandedCount + 1
            end
        end
    end

    placementWorldRef = world
    placementSeed = tonumber(Wall.seed) or 0
    placementMarkedCount = currentMarkedCount(world)
end
'''
    text = text[:start] + replacement + text[end:]

    old_status = "placement=%d/%d target=%.0f%% targetCount=%d separation=touching-never distribution=blue-noise softSpacing=%dcells lowerBias=%.2f geometryBlocked=%d relaxed=%d"
    new_status = "placement=%d/%d placeable=%d all=%d cap=%.0f%% capCount=%d targetCount=%d separation=touching-never distribution=blue-noise-packed softSpacing=%dcells lowerBias=%.2f geometryBlocked=%d relaxed=%d"
    text = replace_once(text, old_status, new_status, "brand status format")

    old_args = '''        brandedCount,\n        brandableCount,\n        BRAND_TARGET_FRACTION * 100,\n        targetBrandCount,\n        BRAND_SOFT_SPACING_CELLS,\n        BRAND_LOWER_TIER_BIAS,\n        geometryBlockedCount,\n        relaxedSpacingCount\n'''
    new_args = '''        brandedCount,\n        brandableCount,\n        placeableCount,\n        #world,\n        BRAND_GLOBAL_CAP_FRACTION * 100,\n        globalBrandCap,\n        targetBrandCount,\n        BRAND_SOFT_SPACING_CELLS,\n        BRAND_LOWER_TIER_BIAS,\n        geometryBlockedCount,\n        relaxedSpacingCount\n'''
    text = replace_once(text, old_args, new_args, "brand status arguments")

    BRANDING.write_text(text, encoding="utf-8")
    return True


def patch_docs():
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V18 dense branding with a global 40% ceiling"
    if marker in text:
        return False

    appendix = r'''

## V18 dense branding with a global 40% ceiling

The fixed 26% eligible-container target is retired. V18 attempts to brand every
full-surface, non-wayfinding container that can participate in the hard no-touching
independent set. Branding is then capped globally at 40% of *all* rendered container
instances, including clipped, marked, and otherwise ineligible containers.

The no-touching invariant remains absolute. Upper/lower partners on one logical wall
edge can never both carry company paint, and same-tier collinear neighbors sharing an
endpoint can never both carry paint. V17's blue-noise ordering is retained: broad
spacing is attempted first, then the soft spacing cushion may relax while physical
contact remains forbidden. This produces the densest believable placement without
turning the maze into repeated logo wallpaper.

When the 40% global ceiling binds, the available brand budget is distributed across
floors with a one-per-floor baseline when possible, then proportionally by each floor's
remaining placeable capacity. Each floor keeps a prefix of its blue-noise selection, so
coverage remains broad and deterministic even under the cap.
'''
    DOCS.write_text(text.rstrip() + appendix + "\n", encoding="utf-8")
    return True


def main():
    changed = {
        "branding": patch_branding(),
        "docs": patch_docs(),
    }
    print("V18 brand cap patch:", changed)


if __name__ == "__main__":
    main()
