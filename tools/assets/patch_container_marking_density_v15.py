#!/usr/bin/env python3
"""Apply V15 sparse/full-face-only container marking rules.

V15 is presentation-only. It adds a conservative topology classifier to the client
wall cache, excludes corner/junction-clipped containers from every overlay, and
samples exactly one company-branded container from each complete block of five
eligible ordinary containers.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
WAYFINDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua"
PANELS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_marking_panel.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one occurrence, found {count}")
    return text.replace(old, new, 1)


def patch_walls():
    text = WALLS.read_text(encoding="utf-8")
    if "buildFullSurfaceEligibility" in text:
        return False

    anchor = '''local function rebuildWorldCache()\n    local origin = Wall.origin or MC.Origin or vector_origin\n'''
    helper = r'''-- Overlay-safe containers must expose their entire long face. A perpendicular
-- wall meeting either endpoint clips some portion of that face in corners, T-junctions,
-- short dead ends and related maze edge cases. Classify those cases once from the
-- immutable logical wall manifest rather than tracing visibility every render frame.
local function segmentFaceInfo(segment)
    if not segment then return nil end
    local x = math.floor(tonumber(segment[1]) or 0)
    local y = math.floor(tonumber(segment[2]) or 0)
    local z = math.floor(tonumber(segment[3]) or -1)
    local direction = math.floor(tonumber(segment[4]) or -1)
    if z < 0 or not DIRS[direction] then return nil end

    local ax, ay, bx, by, orientation
    if direction == 0 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y + 1, 2 * x + 1, 2 * y + 1, "h"
    elseif direction == 2 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y - 1, 2 * x + 1, 2 * y - 1, "h"
    elseif direction == 1 then
        ax, ay, bx, by, orientation = 2 * x + 1, 2 * y - 1, 2 * x + 1, 2 * y + 1, "v"
    else
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y - 1, 2 * x - 1, 2 * y + 1, "v"
    end

    local a = string.format("%d:%d:%d", z, ax, ay)
    local b = string.format("%d:%d:%d", z, bx, by)
    local first, second = a < b and a or b, a < b and b or a
    return {
        endpointA = a,
        endpointB = b,
        orientation = orientation,
        edgeKey = first .. ">" .. second
    }
end

local function buildFullSurfaceEligibility(logical)
    local infoByIndex = {}
    local endpointUse = {}
    local edgeCounts = {}

    for index, segment in ipairs(logical or {}) do
        local info = segmentFaceInfo(segment)
        infoByIndex[index] = info
        if info then
            edgeCounts[info.edgeKey] = (edgeCounts[info.edgeKey] or 0) + 1
            for _, endpoint in ipairs({info.endpointA, info.endpointB}) do
                local use = endpointUse[endpoint]
                if not use then
                    use = {h = 0, v = 0}
                    endpointUse[endpoint] = use
                end
                use[info.orientation] = use[info.orientation] + 1
            end
        end
    end

    local eligible = {}
    for index, info in ipairs(infoByIndex) do
        if info and edgeCounts[info.edgeKey] == 1 then
            local perpendicular = info.orientation == "h" and "v" or "h"
            local a = endpointUse[info.endpointA]
            local b = endpointUse[info.endpointB]
            eligible[index] = a and b and a[perpendicular] == 0 and b[perpendicular] == 0
        else
            eligible[index] = false
        end
    end
    return eligible
end

local function rebuildWorldCache()
    local origin = Wall.origin or MC.Origin or vector_origin
'''
    text = replace_once(text, anchor, helper, "full-face helper insertion")

    text = replace_once(
        text,
        '''    for _, segment in ipairs(Wall.logical or {}) do\n        local direction = DIRS[segment[4]]\n''',
        '''    local fullSurfaceEligibility = buildFullSurfaceEligibility(Wall.logical or {})\n    for segmentIndex, segment in ipairs(Wall.logical or {}) do\n        local direction = DIRS[segment[4]]\n''',
        "logical segment loop",
    )

    text = replace_once(
        text,
        '''                    stackIndex = stack,\n                    stackCount = stackCount\n''',
        '''                    stackIndex = stack,\n                    stackCount = stackCount,\n                    fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true\n''',
        "instance eligibility metadata",
    )
    WALLS.write_text(text, encoding="utf-8")
    return True


def patch_wayfinding():
    text = WAYFINDING.read_text(encoding="utf-8")
    old = '''        if instance.floor ~= nil and instance.quadrant then\n'''
    new = '''        if instance.floor ~= nil and instance.quadrant\n            and instance.fullSurfaceEligible == true\n        then\n'''
    if new in text:
        return False
    text = replace_once(text, old, new, "wayfinding candidate eligibility")
    WAYFINDING.write_text(text, encoding="utf-8")
    return True


def patch_panels():
    text = PANELS.read_text(encoding="utf-8")
    old = '''local function drawMarkedContainer(model, instance, eyePos)\n    if not instance or not instance.marked or not IsValid(model) then return end\n'''
    new = '''local function drawMarkedContainer(model, instance, eyePos)\n    if not instance or not instance.marked\n        or instance.fullSurfaceEligible ~= true or not IsValid(model)\n    then\n        return\n    end\n'''
    if new in text:
        return False
    text = replace_once(text, old, new, "panel draw guard")
    PANELS.write_text(text, encoding="utf-8")
    return True


def patch_branding():
    text = BRANDING.read_text(encoding="utf-8")
    if "BRANDING_DENOMINATOR = 5" in text:
        return False

    text = replace_once(
        text,
        '''local SIDE_HEIGHT_FRACTION = 0.66\n\nlocal BRAND_COUNT = 256\n''',
        '''local SIDE_HEIGHT_FRACTION = 0.66\nlocal BRANDING_DENOMINATOR = 5\n\nlocal BRAND_COUNT = 256\n''',
        "branding density constant",
    )

    anchor = '''local function sprayPaintColor(instance)\n'''
    selection = r'''local placementWorldRef = nil
local placementSeed = nil
local placementMarkedCount = -1
local brandedCount = 0
local brandableCount = 0
local geometryBlockedCount = 0

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

local function rebuildBrandPlacement(world)
    brandedCount = 0
    brandableCount = 0
    geometryBlockedCount = 0
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
    local seed = tonumber(Wall.seed) or 1
    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed, "container-brand-placement:v1"))

    -- One deterministic choice from every complete spatial block of five. Leftover
    -- candidates are intentionally unbranded, so density can never exceed 20%.
    local fullBlocks = math.floor(#candidates / BRANDING_DENOMINATOR)
    for block = 0, fullBlocks - 1 do
        local first = block * BRANDING_DENOMINATOR + 1
        local last = first + BRANDING_DENOMINATOR - 1
        local chosen = candidates[rng:Int(first, last)]
        if chosen and chosen.instance then
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

local function sprayPaintColor(instance)
'''
    text = replace_once(text, anchor, selection, "brand placement selection")

    old_condition = '''                    if instance and not instance.marked and IsValid(model)\n                        and eyePos:DistToSqr(model:GetPos()) <= DRAW_DISTANCE_SQR\n'''
    new_condition = '''                    if instance and instance.companyBranded == true\n                        and instance.fullSurfaceEligible == true and not instance.marked\n                        and IsValid(model)\n                        and eyePos:DistToSqr(model:GetPos()) <= DRAW_DISTANCE_SQR\n'''
    text = replace_once(text, old_condition, new_condition, "brand render guard")

    old_status = '''concommand.Add("lod_container_brand_status", function()\n    local ok = ensureSelection()\n    print(string.format(\n        "[LOD] container brand: seed=%s brand=%s atlas=%s cell=%s,%s material=%s path=%s mode=vertexlit-spray-v8-alphatest-dither width=%.2f height=%.2f",\n'''
    new_status = '''concommand.Add("lod_container_brand_status", function()\n    local world = Wall.world or {}\n    if #world > 0 then ensureBrandPlacement(world) end\n    local ok = ensureSelection()\n    print(string.format(\n        "[LOD] container brand: seed=%s brand=%s atlas=%s cell=%s,%s material=%s path=%s mode=vertexlit-spray-v8-alphatest-dither width=%.2f height=%.2f placement=%d/%d target=1/%d geometryBlocked=%d",\n'''
    text = replace_once(text, old_status, new_status, "brand status header")

    old_tail = '''        tostring(selectedPath or "none"),\n        SIDE_WIDTH_FRACTION,\n        SIDE_HEIGHT_FRACTION\n    ))\nend)'''
    new_tail = '''        tostring(selectedPath or "none"),\n        SIDE_WIDTH_FRACTION,\n        SIDE_HEIGHT_FRACTION,\n        brandedCount,\n        brandableCount,\n        BRANDING_DENOMINATOR,\n        geometryBlockedCount\n    ))\nend)'''
    text = replace_once(text, old_tail, new_tail, "brand status counts")
    BRANDING.write_text(text, encoding="utf-8")
    return True


def patch_docs():
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V15 sparse full-face-only overlays"
    if marker in text:
        return False
    appendix = r'''

## V15 sparse full-face-only overlays

Company identity is intentionally sparse. After wayfinding containers are reserved,
ordinary overlay-safe containers are sorted deterministically and divided into complete
blocks of five; exactly one container from each block receives the run's selected
company stencil. Incomplete trailing blocks receive no company paint, so branding can
never exceed 20% of eligible ordinary containers.

Every overlay now shares a conservative full-surface eligibility rule. The client wall
cache classifies each logical wall edge from its grid endpoints. If a perpendicular wall
meets either endpoint, the container is treated as geometrically clipped (corner,
T-junction, short dead end, or related edge case) and receives neither company paint nor
a plywood wayfinding plate. Duplicate logical edges are also ineligible. Collinear
end-to-end walls remain eligible because they do not occlude the broad face.

This classification is presentation-only and is computed once when the immutable wall
manifest is expanded. It does not alter collision, maze topology or navigation.
'''
    DOCS.write_text(text.rstrip() + appendix + "\n", encoding="utf-8")
    return True


def main():
    changed = {
        "walls": patch_walls(),
        "wayfinding": patch_wayfinding(),
        "panels": patch_panels(),
        "branding": patch_branding(),
        "docs": patch_docs(),
    }
    print("V15 marking patch:", changed)


if __name__ == "__main__":
    main()
