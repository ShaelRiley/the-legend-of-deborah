LOD = LOD or {}
LOD.MinimapPlayerContrast = LOD.MinimapPlayerContrast or {}

local Contrast = LOD.MinimapPlayerContrast
local Map = LOD.Minimap
local MC = LOD.Config and LOD.Config.Maze
if not Map or not MC then return end

-- The breadcrumb is a warm gold (~48 degrees). A saturated blue near the
-- complementary side of the color wheel gives the player marker immediate
-- figure/ground separation during the map's deliberately short viewing window.
local PLAYER_BLUE = Color(72, 132, 255, 255)
local PLAYER_OUTLINE = Color(7, 12, 24, 245)
local MARKER_RADIUS = 3
local NEEDLE_LENGTH = 12

Contrast.PlayerColor = PLAYER_BLUE
Contrast.OutlineColor = PLAYER_OUTLINE

local function cellKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function currentGridPosition(ply)
    local pos = ply:GetPos()
    local x = math.floor(((pos.x - MC.Origin.x) / MC.CellSize)
        + ((MC.Width + 1) * 0.5) + 0.5)
    local y = math.floor(((pos.y - MC.Origin.y) / MC.CellSize)
        + ((MC.Height + 1) * 0.5) + 0.5)
    local z = math.floor(((pos.z - MC.Origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(x, 1, MC.Width), math.Clamp(y, 1, MC.Height), math.max(0, z)
end

local function drawNeedle(px, py, dx, dy)
    local ex = px + dx * NEEDLE_LENGTH
    local ey = py + dy * NEEDLE_LENGTH

    -- Four dark strokes form a cheap one-pixel silhouette around the blue
    -- needle. The final blue stroke is always drawn last, covering the legacy
    -- gold marker and any coincident breadcrumb segment.
    surface.SetDrawColor(PLAYER_OUTLINE)
    surface.DrawLine(px - 1, py, ex - 1, ey)
    surface.DrawLine(px + 1, py, ex + 1, ey)
    surface.DrawLine(px, py - 1, ex, ey - 1)
    surface.DrawLine(px, py + 1, ex, ey + 1)
    surface.SetDrawColor(PLAYER_BLUE)
    surface.DrawLine(px, py, ex, ey)
end

-- PostDrawHUD is deliberately later than the core minimap's HUDPaint pass.
-- This keeps the mature map renderer untouched while guaranteeing that the
-- player direction marker wins every overlap with the gold breadcrumb.
hook.Add("PostDrawHUD", "LOD_MinimapComplementaryPlayerMarker", function()
    if not Map.open then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if not Map.cache or Map.cache.indexedRevision ~= Map.cache.revision then return end

    local gx, gy, gz = currentGridPosition(ply)
    gz = math.Clamp(gz, 0, math.max(0, (Map.layers or 1) - 1))
    if not Map.byKey or not Map.byKey[cellKey(gx, gy, gz)] then return end

    local panelW = 336
    local panelX = ScrW() - panelW - 20
    local panelY = 96
    local gridX, gridY = panelX + 26, panelY + 68
    local gridSize = 284
    local cellSize = gridSize / math.max(MC.Width, MC.Height)
    local px = gridX + (gx - 0.5) * cellSize
    local py = gridY + (MC.Height - gy + 0.5) * cellSize

    local yaw = math.rad(EyeAngles().y)
    local dx = math.cos(yaw)
    local dy = -math.sin(yaw)

    surface.SetDrawColor(PLAYER_OUTLINE)
    surface.DrawCircle(px, py, MARKER_RADIUS + 2,
        PLAYER_OUTLINE.r, PLAYER_OUTLINE.g, PLAYER_OUTLINE.b, PLAYER_OUTLINE.a)
    surface.SetDrawColor(PLAYER_BLUE)
    surface.DrawCircle(px, py, MARKER_RADIUS,
        PLAYER_BLUE.r, PLAYER_BLUE.g, PLAYER_BLUE.b, PLAYER_BLUE.a)
    drawNeedle(px, py, dx, dy)
end)

concommand.Add("lod_minimap_player_color_status", function()
    print(string.format(
        "[LOD:MINIMAP-PLAYER] rgb=%d,%d,%d breadcrumbContrast=complementary overlay=PostDrawHUD result=ARMED",
        PLAYER_BLUE.r, PLAYER_BLUE.g, PLAYER_BLUE.b))
end)
