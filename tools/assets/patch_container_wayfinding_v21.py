#!/usr/bin/env python3
"""Apply V21 orientation-first wayfinding and brand/sign coexistence.

V21 makes floor/quadrant boards serve moment-to-moment map orientation rather than
merely achieving a global density. It raises the nominal safe-surface density to 30%,
raises the per-section baseline to five, scores straight corridor sightlines out to six
cells, and favors junctions/turns where players naturally stop and look around. The
hard no-touching sign invariant remains absolute.

Company spray and a wayfinding board are now allowed on the same container. The board
is physically offset farther from the hull, so it remains legible over the company
stencil without consuming a separate branding slot.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WAYFINDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one occurrence, found {count}")
    return text.replace(old, new, 1)


def patch_wayfinding():
    text = WAYFINDING.read_text(encoding="utf-8")
    if "container-wayfinding-orientation:v21" in text:
        return False

    text = replace_once(
        text,
        "local MARKING_DENSITY = 0.22\nlocal MIN_MARKS_PER_SECTION = 4\nlocal SIGN_COVERAGE_RADIUS_CELLS = 3",
        "local MARKING_DENSITY = 0.30\nlocal MIN_MARKS_PER_SECTION = 5\nlocal SIGN_SIGHTLINE_RANGE_CELLS = 6",
        "V21 wayfinding constants",
    )

    old_header = '''-- V20 treats locator visibility as a coverage problem rather than a lottery. Signs\n-- remain section-balanced, but candidates that expose a floor/quadrant code to more\n-- nearby walkable cells are preferred. Stacked or directly touching signs are always\n-- forbidden, even if a section cannot otherwise reach its desired count.\n'''
    new_header = '''-- V21 treats locator visibility as a first-person orientation problem. Signs remain\n-- section-balanced, but candidates that cover long straight sightlines and decision\n-- points are preferred. Stacked or directly touching signs are always forbidden, even\n-- if a section cannot otherwise reach its desired count.\n'''
    text = replace_once(text, old_header, new_header, "V21 selection header")

    start = text.find("local function coverageForInstance(instance, blocked)")
    end = text.find("\nlocal function signConflicts(instance, occupiedEdges, occupiedEndpoints)", start)
    if start < 0 or end < 0:
        raise SystemExit("coverageForInstance block boundaries not found")

    visibility_block = r'''local function adjacentObservationCells(instance)
    local cells = {{instance.gridX or 0, instance.gridY or 0}}
    local delta = DIR_DELTA[instance.overlayDirection or 0]
    if delta then
        local nx = (instance.gridX or 0) + delta[1]
        local ny = (instance.gridY or 0) + delta[2]
        if inBounds(nx, ny) then cells[#cells + 1] = {nx, ny} end
    end
    return cells
end

local function openDirections(floor, x, y, blocked)
    local count = 0
    local horizontal = false
    local vertical = false
    for direction, move in pairs(DIR_DELTA) do
        local nx = x + move[1]
        local ny = y + move[2]
        if inBounds(nx, ny)
            and not blocked[passageKey(floor, x, y, nx, ny)]
        then
            count = count + 1
            if direction == 1 or direction == 3 then vertical = true else horizontal = true end
        end
    end
    return count, horizontal, vertical
end

-- Decision-point utility is a secondary score after raw sightline coverage. Junctions
-- are strongest, then ninety-degree turns, then dead ends/straight corridors. This
-- puts location information where a player is most likely to stop and consult the map.
local function orientationAnchorScore(instance, blocked)
    local best = 0
    local floor = instance.floor or 0
    for _, cell in ipairs(adjacentObservationCells(instance)) do
        local x, y = cell[1], cell[2]
        if inBounds(x, y) then
            local degree, horizontal, vertical = openDirections(floor, x, y, blocked)
            local score
            if degree >= 3 then
                score = 8 + degree
            elseif degree == 2 and horizontal and vertical then
                score = 7
            elseif degree == 1 then
                score = 4
            elseif degree == 2 then
                score = 3
            else
                score = 1
            end
            if score > best then best = score end
        end
    end
    return best
end

-- Model what the player can discover by stopping and looking around. Unlike V20's
-- corridor flood, these rays never turn corners: each adjacent side of the container
-- casts four cardinal sightlines until a wall, map edge, or six-cell range limit.
local function coverageForInstance(instance, blocked)
    local floor = instance.floor or 0
    local covered = {}

    for _, startCell in ipairs(adjacentObservationCells(instance)) do
        local sx, sy = startCell[1], startCell[2]
        if inBounds(sx, sy) then
            covered[observationKey(floor, sx, sy)] = true
            for _, move in pairs(DIR_DELTA) do
                local x, y = sx, sy
                for _ = 1, SIGN_SIGHTLINE_RANGE_CELLS do
                    local nx = x + move[1]
                    local ny = y + move[2]
                    if not inBounds(nx, ny)
                        or blocked[passageKey(floor, x, y, nx, ny)]
                    then
                        break
                    end
                    covered[observationKey(floor, nx, ny)] = true
                    x, y = nx, ny
                end
            end
        end
    end
    return covered
end
'''
    text = text[:start] + visibility_block + text[end:]

    # Change deterministic namespace so a new maze seed produces a fresh V21 layout.
    text = text.replace("container-wayfinding-coverage:v20:", "container-wayfinding-orientation:v21:")

    choose_start = text.find("local function chooseBestCandidate(candidates, covered, occupiedEdges, occupiedEndpoints, seed)")
    choose_end = text.find("\nlocal function rebuildMarkedSelection(world)", choose_start)
    if choose_start < 0 or choose_end < 0:
        raise SystemExit("chooseBestCandidate boundaries not found")

    choose_block = r'''local function chooseBestCandidate(candidates, covered, occupiedEdges, occupiedEndpoints, seed)
    local best = nil
    local bestGain = -1
    local bestAnchor = -1
    local bestLower = -1
    local bestNoise = -1

    for _, candidate in ipairs(candidates) do
        local instance = candidate.instance
        if not candidate.selected and not signConflicts(instance, occupiedEdges, occupiedEndpoints) then
            local gain = coverageGain(candidate, covered)
            local anchor = candidate.anchorScore or 0
            local lower = (instance.stackIndex or 0) == 0 and 1 or 0
            local noise = deterministicTieBreak(seed, candidate)
            if gain > bestGain
                or (gain == bestGain and anchor > bestAnchor)
                or (gain == bestGain and anchor == bestAnchor and lower > bestLower)
                or (gain == bestGain and anchor == bestAnchor
                    and lower == bestLower and noise > bestNoise)
            then
                best = candidate
                bestGain = gain
                bestAnchor = anchor
                bestLower = lower
                bestNoise = noise
            end
        end
    end
    return best
end
'''
    text = text[:choose_start] + choose_block + text[choose_end:]

    text = replace_once(
        text,
        '''            candidate.coverage = coverageForInstance(candidate.instance, blocked)\n            candidate.selected = false\n''',
        '''            candidate.coverage = coverageForInstance(candidate.instance, blocked)\n            candidate.anchorScore = orientationAnchorScore(candidate.instance, blocked)\n            candidate.selected = false\n''',
        "orientation anchor preprocessing",
    )

    # Status command: rename the selector and expose sightline semantics.
    text = text.replace(
        "distribution=coverage-first radius=%dcells",
        "distribution=orientation-coverage sightline=%dcells",
    )
    text = text.replace("SIGN_COVERAGE_RADIUS_CELLS,", "SIGN_SIGHTLINE_RANGE_CELLS,")

    WAYFINDING.write_text(text, encoding="utf-8")
    return True


def patch_branding():
    text = BRANDING.read_text(encoding="utf-8")
    if "coexistence=brand+wayfinding" in text:
        return False

    text = replace_once(
        text,
        "-- Marked wayfinding containers deliberately suppress company paint.",
        "-- Wayfinding boards may share a container with company paint; the physical board sits farther from the hull.",
        "branding coexistence comment",
    )
    text = replace_once(
        text,
        "        elseif not instance.marked then\n",
        "        else\n",
        "branding candidate coexistence",
    )
    text = replace_once(
        text,
        "                        and instance.brandSurfaceEligible == true and not instance.marked\n",
        "                        and instance.brandSurfaceEligible == true\n",
        "branding render coexistence",
    )
    text = replace_once(
        text,
        "distribution=coverage-first radius=%dcells coverage=",
        "distribution=coverage-first coexistence=brand+wayfinding radius=%dcells coverage=",
        "branding coexistence diagnostic",
    )
    BRANDING.write_text(text, encoding="utf-8")
    return True


def patch_docs():
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V21 orientation signage"
    if marker in text:
        return False

    appendix = r'''

## V21 orientation signage

Floor/quadrant boards are now optimized for moment-to-moment navigation rather than
raw spatial density. The nominal target rises to approximately 30% of strictly
full-face-safe sign surfaces, with a baseline of five boards per populated
floor/quadrant section where topology and the no-touching rule permit.

Visibility scoring models a player stopping and looking around. Each sign covers
straight cardinal sightlines from both sides of its wall out to six maze cells, stopping
at walls rather than unrealistically turning corners. Coverage gain is the primary
selection score; ties favor junctions and ninety-degree turns, then lower/eye-level
containers, then a deterministic seeded tiebreak. This places location information at
corridor decision points and across long readable vistas.

The wayfinding no-touching invariant remains absolute: signs may not stack vertically
or touch end-to-end on the same tier. Strict full-face eligibility also remains in
force for plywood boards.

Company branding and wayfinding are no longer mutually exclusive. A container selected
for both systems renders the company stencil on the hull and the bolted floor/quadrant
board farther out from the surface. This prevents wayfinding coverage from consuming
company-brand capacity while keeping the locator code visually dominant.
'''
    DOCS.write_text(text.rstrip() + appendix + "\n", encoding="utf-8")
    return True


def main():
    changed = {
        "wayfinding": patch_wayfinding(),
        "branding": patch_branding(),
        "docs": patch_docs(),
    }
    print("V21 orientation signage patch:", changed)


if __name__ == "__main__":
    main()
