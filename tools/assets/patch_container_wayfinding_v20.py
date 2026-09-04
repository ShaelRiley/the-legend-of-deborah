#!/usr/bin/env python3
"""Apply V20 coverage-first, non-touching container wayfinding selection.

V20 modestly raises locator-sign density from ~1/6 to ~22% of strictly eligible
full-face containers, raises the per-section baseline from three to four when possible,
and replaces stratified random sampling with deterministic coverage-first placement.
The selector prefers candidates that expose the current floor/quadrant code to the most
nearby maze cells while preserving an absolute no-touching invariant for stacked and
same-tier end-to-end neighboring signs.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WAYFINDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one occurrence, found {count}")
    return text.replace(old, new, 1)


def patch_wayfinding():
    text = WAYFINDING.read_text(encoding="utf-8")
    if "container-wayfinding-coverage:v20" in text:
        return False

    text = replace_once(
        text,
        "local MARKING_DENSITY = 1 / 6\nlocal MIN_MARKS_PER_SECTION = 3",
        "local MARKING_DENSITY = 0.22\nlocal MIN_MARKS_PER_SECTION = 4\nlocal SIGN_COVERAGE_RADIUS_CELLS = 3",
        "wayfinding density constants",
    )

    start = text.find("-- Build an exact-size, deterministic stratified sample.")
    end = text.find("\n-- Restore the stock Northern Petrol appearance", start)
    if start < 0 or end < 0:
        raise SystemExit("wayfinding selection block boundaries not found")

    replacement = r'''-- V20 treats locator visibility as a coverage problem rather than a lottery. Signs
-- remain section-balanced, but candidates that expose a floor/quadrant code to more
-- nearby walkable cells are preferred. Stacked or directly touching signs are always
-- forbidden, even if a section cannot otherwise reach its desired count.
local selectionWorldRef = nil
local markedCount = 0
local markedBySection = {}
local signTargetCount = 0
local signPlaceableCount = 0
local signCoverageObserved = 0
local signCoverageCovered = 0

local DIR_DELTA = {
    [1] = {0, 1},
    [2] = {1, 0},
    [3] = {0, -1},
    [4] = {-1, 0}
}

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
        if current.distance < SIGN_COVERAGE_RADIUS_CELLS then
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

local function signConflicts(instance, occupiedEdges, occupiedEndpoints)
    local edgeKey = instance.overlayEdgeKey
    local endpointA = instance.overlayEndpointA
    local endpointB = instance.overlayEndpointB
    local orientation = instance.overlayOrientation
    if not edgeKey or not endpointA or not endpointB or not orientation then return true end

    -- Upper/lower partners share one logical edge and therefore physically touch.
    if occupiedEdges[edgeKey] then return true end

    -- Same-tier collinear neighbors sharing an endpoint touch end-to-end.
    local stackKey = tostring(instance.stackIndex or 0) .. ":" .. orientation
    local endpoints = occupiedEndpoints[stackKey]
    return endpoints and (endpoints[endpointA] or endpoints[endpointB]) or false
end

local function reserveSign(instance, occupiedEdges, occupiedEndpoints)
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

local function coverageGain(candidate, covered)
    local gain = 0
    for key in pairs(candidate.coverage or {}) do
        if not covered[key] then gain = gain + 1 end
    end
    return gain
end

local function deterministicTieBreak(seed, candidate)
    local instance = candidate.instance
    local token = string.format(
        "container-wayfinding-coverage:v20:%d:%d:%d:%d:%d",
        candidate.index or 0,
        instance.floor or 0,
        instance.gridX or 0,
        instance.gridY or 0,
        instance.stackIndex or 0
    )
    local derived = tonumber(LOD.Seeds.Derive(seed, token)) or 0
    return derived % 100000
end

local function chooseBestCandidate(candidates, covered, occupiedEdges, occupiedEndpoints, seed)
    local best = nil
    local bestGain = -1
    local bestLower = -1
    local bestNoise = -1

    for _, candidate in ipairs(candidates) do
        local instance = candidate.instance
        if not candidate.selected and not signConflicts(instance, occupiedEdges, occupiedEndpoints) then
            local gain = coverageGain(candidate, covered)
            local lower = (instance.stackIndex or 0) == 0 and 1 or 0
            local noise = deterministicTieBreak(seed, candidate)
            if gain > bestGain
                or (gain == bestGain and lower > bestLower)
                or (gain == bestGain and lower == bestLower and noise > bestNoise)
            then
                best = candidate
                bestGain = gain
                bestLower = lower
                bestNoise = noise
            end
        end
    end
    return best
end

local function rebuildMarkedSelection(world)
    markedCount = 0
    markedBySection = {}
    signTargetCount = 0
    signPlaceableCount = 0
    signCoverageObserved = 0
    signCoverageCovered = 0

    local byKey = {}
    for index, instance in ipairs(world or {}) do
        instance.marked = false
        if instance.floor ~= nil and instance.quadrant
            and instance.fullSurfaceEligible == true
        then
            local key = sectionKey(instance)
            local group = byKey[key]
            if not group then
                group = {
                    key = key,
                    floor = instance.floor,
                    quadrant = instance.quadrant,
                    candidates = {}
                }
                byKey[key] = group
            end
            group.candidates[#group.candidates + 1] = {index = index, instance = instance}
        end
    end

    local groups = {}
    local capacity = 0
    for _, group in pairs(byKey) do
        table.sort(group.candidates, sortSectionCandidates)
        groups[#groups + 1] = group
        capacity = capacity + #group.candidates
    end
    table.sort(groups, function(a, b)
        if a.floor ~= b.floor then return a.floor < b.floor end
        return a.quadrant < b.quadrant
    end)
    if #groups == 0 or capacity == 0 then return end

    local desiredTotal = math.floor(capacity * MARKING_DENSITY + 0.5)
    local allocation = {}
    local allocated = 0

    -- Slightly stronger section baseline than V19: four signs where a section has
    -- enough safe surfaces, then distribute the remaining density evenly.
    for _, group in ipairs(groups) do
        local minimum = math.min(MIN_MARKS_PER_SECTION, #group.candidates)
        allocation[group.key] = minimum
        allocated = allocated + minimum
    end
    desiredTotal = math.min(capacity, math.max(desiredTotal, allocated))

    while allocated < desiredTotal do
        local progressed = false
        for _, group in ipairs(groups) do
            local current = allocation[group.key] or 0
            if current < #group.candidates then
                allocation[group.key] = current + 1
                allocated = allocated + 1
                progressed = true
                if allocated >= desiredTotal then break end
            end
        end
        if not progressed then break end
    end
    signTargetCount = desiredTotal

    local blocked = buildBlockedPassages()
    local seed = tonumber(Wall.seed) or 1
    local occupiedEdges = {}
    local occupiedEndpoints = {}
    local covered = {}

    for _, group in ipairs(groups) do
        for _, candidate in ipairs(group.candidates) do
            candidate.coverage = coverageForInstance(candidate.instance, blocked)
            candidate.selected = false
        end
    end

    -- Round-robin among floor/quadrant sections, but within each section choose the
    -- legal candidate with the greatest uncovered maze-cell gain. This preserves the
    -- semantic balance while eliminating the long sign deserts seen in playtests.
    local remaining = {}
    for _, group in ipairs(groups) do
        remaining[group.key] = math.min(allocation[group.key] or 0, #group.candidates)
    end

    while true do
        local progressed = false
        for _, group in ipairs(groups) do
            if (remaining[group.key] or 0) > 0 then
                local groupSeed = LOD.Seeds.Derive(seed, "container-wayfinding-coverage:v20:" .. group.key)
                local chosen = chooseBestCandidate(
                    group.candidates, covered, occupiedEdges, occupiedEndpoints, groupSeed
                )
                if chosen and chosen.instance then
                    chosen.selected = true
                    chosen.instance.marked = true
                    chosen.instance.markOrdinal = (allocation[group.key] or 0) - remaining[group.key] + 1
                    reserveSign(chosen.instance, occupiedEdges, occupiedEndpoints)
                    for key in pairs(chosen.coverage or {}) do covered[key] = true end
                    remaining[group.key] = remaining[group.key] - 1
                    markedCount = markedCount + 1
                    markedBySection[group.key] = (markedBySection[group.key] or 0) + 1
                    progressed = true
                else
                    -- No more legal non-touching surface exists in this section.
                    remaining[group.key] = 0
                end
            end
        end
        if not progressed then break end
    end

    signPlaceableCount = markedCount
    for floor = 0, 7 do
        local floorHasCandidates = false
        for _, group in ipairs(groups) do
            if group.floor == floor and #group.candidates > 0 then
                floorHasCandidates = true
                break
            end
        end
        if floorHasCandidates then signCoverageObserved = signCoverageObserved + MC.Width * MC.Height end
    end
    for _ in pairs(covered) do signCoverageCovered = signCoverageCovered + 1 end
end
'''
    text = text[:start] + replacement + text[end:]

    # Add a compact runtime diagnostic without disturbing existing rendering behavior.
    marker = 'local appearanceModelsRef = nil\n'
    diagnostic = r'''concommand.Add("lod_container_wayfinding_status", function()
    local world = Wall.world or {}
    if world ~= selectionWorldRef then
        selectionWorldRef = world
        rebuildMarkedSelection(world)
    end
    local percent = signCoverageObserved > 0 and (signCoverageCovered / signCoverageObserved) * 100 or 0
    print(string.format(
        "[LOD] container wayfinding: marked=%d target=%d density=%.0f%% minPerSection=%d separation=touching-never distribution=coverage-first radius=%dcells coverage=%d/%d(%.0f%%)",
        markedCount,
        signTargetCount,
        MARKING_DENSITY * 100,
        MIN_MARKS_PER_SECTION,
        SIGN_COVERAGE_RADIUS_CELLS,
        signCoverageCovered,
        signCoverageObserved,
        percent
    ))
end)

local appearanceModelsRef = nil
'''
    text = replace_once(text, marker, diagnostic, "wayfinding status command")

    WAYFINDING.write_text(text, encoding="utf-8")
    return True


def patch_docs():
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V20 wayfinding coverage"
    if marker in text:
        return False

    appendix = r'''

## V20 wayfinding coverage

Floor/quadrant plywood locator boards now target approximately 22% of strictly
full-face-eligible container surfaces, with a baseline of four boards per populated
floor/quadrant section where topology permits. Placement is coverage-first over a
three-cell corridor-aware neighborhood so ordinary movement should expose a locator
board most of the time instead of producing long informational deserts.

Wayfinding boards have an absolute no-touching invariant. Upper/lower containers on the
same wall edge can never both carry boards, and same-tier collinear neighbors that share
an endpoint can never both carry boards. If a section lacks enough non-touching surfaces,
coverage yields to this invariant rather than stacking or crowding signs. Company paint
continues to suppress itself on marked wayfinding containers.
'''
    DOCS.write_text(text.rstrip() + appendix + "\n", encoding="utf-8")
    return True


def main():
    changed = {
        "wayfinding": patch_wayfinding(),
        "docs": patch_docs(),
    }
    print("V20 wayfinding patch:", changed)


if __name__ == "__main__":
    main()
