#!/usr/bin/env python3
"""Apply V16 one-in-three, non-touching company-brand placement.

V16 retains V15's conservative full-face eligibility rule, then targets one company
stencil per three eligible ordinary containers while treating physical face contact
as a hard conflict. Vertical partners in the same two-container wall stack conflict,
and collinear neighbors in the same stack tier conflict when their wall edges share
an endpoint. Separation always wins if a pathological layout cannot reach the target.
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
    if "overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil" in text:
        return False

    text = replace_once(
        text,
        '''        local direction = DIRS[segment[4]]\n        if direction then\n            local baseX =''',
        '''        local direction = DIRS[segment[4]]\n        if direction then\n            local faceInfo = segmentFaceInfo(segment)\n            local baseX =''',
        "face metadata lookup",
    )

    text = replace_once(
        text,
        '''                    stackIndex = stack,\n                    stackCount = stackCount,\n                    fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true\n''',
        '''                    stackIndex = stack,\n                    stackCount = stackCount,\n                    fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true,\n                    overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil,\n                    overlayEndpointA = faceInfo and faceInfo.endpointA or nil,\n                    overlayEndpointB = faceInfo and faceInfo.endpointB or nil,\n                    overlayOrientation = faceInfo and faceInfo.orientation or nil\n''',
        "touching metadata",
    )

    WALLS.write_text(text, encoding="utf-8")
    return True


def patch_branding():
    text = BRANDING.read_text(encoding="utf-8")
    if "container-brand-placement:v2:trial:" in text and "BRANDING_DENOMINATOR = 3" in text:
        return False

    text = text.replace("local BRANDING_DENOMINATOR = 5", "local BRANDING_DENOMINATOR = 3", 1)

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
local placementAttempts = 0

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

-- Physical contact graph for company paint. Both containers in one logical wall
-- stack share a horizontal face, so only one of them may be branded. Collinear
-- neighbors in the same stack tier share a vertical end face, so they also conflict.
-- Diagonal point/edge contact between different tiers is not treated as adjacency.
local function candidateConflicts(instance, occupiedEdges, occupiedEndpoints)
    local edgeKey = instance.overlayEdgeKey
    local endpointA = instance.overlayEndpointA
    local endpointB = instance.overlayEndpointB
    local orientation = instance.overlayOrientation
    if not edgeKey or not endpointA or not endpointB or not orientation then return true end

    -- Same logical wall edge means the upper/lower stack partner is already branded.
    if occupiedEdges[edgeKey] then return true end

    -- Same-tier collinear wall edges that share either endpoint are directly adjacent.
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

local function independentSelection(candidates, seed, trial, target)
    local order = {}
    for index = 1, #candidates do order[index] = index end

    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed,
        "container-brand-placement:v2:trial:" .. tostring(trial)))
    rng:Shuffle(order)

    local occupiedEdges = {}
    local occupiedEndpoints = {}
    local chosen = {}
    for _, candidateIndex in ipairs(order) do
        if #chosen >= target then break end
        local candidate = candidates[candidateIndex]
        local instance = candidate and candidate.instance
        if instance and not candidateConflicts(instance, occupiedEdges, occupiedEndpoints) then
            reserveCandidate(instance, occupiedEdges, occupiedEndpoints)
            chosen[#chosen + 1] = candidate
        end
    end
    return chosen
end

local function rebuildBrandPlacement(world)
    brandedCount = 0
    brandableCount = 0
    geometryBlockedCount = 0
    targetBrandCount = 0
    placementAttempts = 0
    local candidates = {}

    for index, instance in ipairs(world or {}) do
        instance.companyBranded = false
        if instance.fullSurfaceEligible ~= true then
            geometryBlockedCount = geometryBlockedCount + 1
        elseif not instance.marked then
            candidates[#candidates + 1] = {index = index, instance = instance}
        end
    end

    table.sort(candidates, placementSort)
    brandableCount = #candidates
    targetBrandCount = math.floor(#candidates / BRANDING_DENOMINATOR)

    local seed = tonumber(Wall.seed) or 1
    local best = {}
    local maxAttempts = targetBrandCount > 0 and 24 or 0
    for trial = 1, maxAttempts do
        placementAttempts = trial
        local chosen = independentSelection(candidates, seed, trial, targetBrandCount)
        if #chosen > #best then best = chosen end
        if #best >= targetBrandCount then break end
    end

    -- Separation is the hard invariant. In normal wall runs the independent set has
    -- ample capacity for one in three; should a pathological layout fall short, it
    -- remains safely under target rather than ever branding touching containers.
    for _, chosen in ipairs(best) do
        if chosen.instance then
            chosen.instance.companyBranded = true
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

    old_status = "placement=%d/%d target=1/%d geometryBlocked=%d"
    new_status = "placement=%d/%d target=1/%d targetCount=%d separation=touching-never geometryBlocked=%d attempts=%d"
    if old_status not in text:
        raise SystemExit("brand status format not found")
    text = text.replace(old_status, new_status, 1)

    old_args = '''        brandedCount,\n        brandableCount,\n        BRANDING_DENOMINATOR,\n        geometryBlockedCount\n'''
    new_args = '''        brandedCount,\n        brandableCount,\n        BRANDING_DENOMINATOR,\n        targetBrandCount,\n        geometryBlockedCount,\n        placementAttempts\n'''
    if old_args not in text:
        raise SystemExit("brand status arguments not found")
    text = text.replace(old_args, new_args, 1)

    BRANDING.write_text(text, encoding="utf-8")
    return True


def patch_docs():
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V16 one-in-three non-touching company branding"
    if marker in text:
        return False

    appendix = r'''

## V16 one-in-three non-touching company branding

After V15 removes clipped geometry and reserves wayfinding containers, company paint now
targets one third of the remaining eligible ordinary containers. Selection is seeded and
deterministic for a labyrinth. The target count is `floor(eligible / 3)`.

Brand separation is a hard invariant. The upper and lower containers in the same logical
wall stack may never both carry company paint, because they directly touch. In addition,
two collinear containers in the same stack tier may never both carry company paint when
their wall edges share an endpoint. The selector searches deterministic shuffled orders
for an independent set up to the one-third target. If an unusual topology cannot reach
the target, separation wins and the run remains slightly under one third rather than ever
placing two branded containers next to or directly touching one another.

V15 full-surface eligibility remains authoritative: clipped corners, T-junctions, short
dead-end edge cases, duplicate logical faces, and wayfinding-marked containers are excluded
before the one-third target is calculated.
'''
    DOCS.write_text(text.rstrip() + appendix + "\n", encoding="utf-8")
    return True


def main():
    changed = {
        "walls": patch_walls(),
        "branding": patch_branding(),
        "docs": patch_docs(),
    }
    print("V16 brand spacing patch:", changed)


if __name__ == "__main__":
    main()
