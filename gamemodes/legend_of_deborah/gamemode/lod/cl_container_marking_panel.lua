LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Final presentation authority for sparse floor/quadrant plates. The stock NP logo
-- is asymmetrically placed on each broad side of cargo_container01; the UV layout
-- mirrors that position across the opposite face. The earlier renderer always used
-- the same physical +Y position, so a plate could miss the logo on the reverse face.
-- This pass mirrors the longitudinal anchor with the viewed side and uses an opaque,
-- oversized plywood board so every marked container genuinely covers the branding.
local DRAW_DISTANCE = 1800
local DRAW_DISTANCE_SQR = DRAW_DISTANCE * DRAW_DISTANCE
local BUCKET_CELLS = 4
local PANEL_SCALE = 0.22
local SURFACE_OFFSET = 2.1

-- Empirically aligned to the stock Northern Petrol side-branding zone. The reverse
-- face uses 1 - LOGO_Y_FRACTION, matching the mirrored texture placement.
local LOGO_Y_FRACTION = 0.69
local LOGO_Z_FRACTION = 0.58
local PANEL_WIDTH = 500
local PANEL_HEIGHT = 216
local PANEL_BORDER = 11
local PANEL_COLOR = Color(198, 168, 120, 255)
local PANEL_EDGE = Color(69, 51, 35, 245)
local PANEL_SHADOW = Color(15, 12, 10, 235)
local PANEL_MATERIAL = Material("models/props_c17/FurnitureWood001a")

local function bucketKey(x, y)
    return math.floor((x - 1) / BUCKET_CELLS), math.floor((y - 1) / BUCKET_CELLS)
end

local function gridPosition(pos)
    local origin = Wall.origin or MC.Origin or vector_origin
    local gx = math.floor(((pos.x - origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local gy = math.floor(((pos.y - origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local gz = math.floor(((pos.z - origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(gx, 1, MC.Width), math.Clamp(gy, 1, MC.Height), math.Clamp(gz, 0, 7)
end

local function drawBoard()
    -- Deep edge first: even if the baked NP art is unusually bright after tinting,
    -- no part of it can read through the replacement board.
    surface.SetDrawColor(PANEL_SHADOW)
    surface.DrawRect(
        -PANEL_WIDTH * 0.5 - PANEL_BORDER,
        -PANEL_HEIGHT * 0.5 - PANEL_BORDER,
        PANEL_WIDTH + PANEL_BORDER * 2,
        PANEL_HEIGHT + PANEL_BORDER * 2
    )

    if PANEL_MATERIAL and not PANEL_MATERIAL:IsError() then
        surface.SetMaterial(PANEL_MATERIAL)
        surface.SetDrawColor(PANEL_COLOR)
        surface.DrawTexturedRect(
            -PANEL_WIDTH * 0.5,
            -PANEL_HEIGHT * 0.5,
            PANEL_WIDTH,
            PANEL_HEIGHT
        )
    else
        surface.SetDrawColor(PANEL_COLOR)
        surface.DrawRect(
            -PANEL_WIDTH * 0.5,
            -PANEL_HEIGHT * 0.5,
            PANEL_WIDTH,
            PANEL_HEIGHT
        )
    end

    surface.SetDrawColor(PANEL_EDGE)
    surface.DrawRect(-PANEL_WIDTH * 0.5, -PANEL_HEIGHT * 0.5, PANEL_WIDTH, 5)
    surface.DrawRect(-PANEL_WIDTH * 0.5, PANEL_HEIGHT * 0.5 - 5, PANEL_WIDTH, 5)
    surface.DrawRect(-PANEL_WIDTH * 0.5, -PANEL_HEIGHT * 0.5, 5, PANEL_HEIGHT)
    surface.DrawRect(PANEL_WIDTH * 0.5 - 5, -PANEL_HEIGHT * 0.5, 5, PANEL_HEIGHT)

    -- Four square fasteners make the board read as a field-installed retrofit rather
    -- than a floating HUD element.
    local bolt = 11
    local inset = 24
    for _, x in ipairs({-PANEL_WIDTH * 0.5 + inset, PANEL_WIDTH * 0.5 - inset - bolt}) do
        for _, y in ipairs({-PANEL_HEIGHT * 0.5 + inset, PANEL_HEIGHT * 0.5 - inset - bolt}) do
            surface.DrawRect(x, y, bolt, bolt)
        end
    end
end

local STENCIL_BRIDGE_CHARS = {
    ["A"] = true, ["B"] = true, ["D"] = true,
    ["6"] = true, ["8"] = true, ["9"] = true, ["0"] = true
}

local function drawStencil(code, color)
    code = tostring(code or "?")
    color = color or Color(30, 30, 30, 255)

    surface.SetFont("LOD_ContainerDINStencil")
    local totalW, totalH = surface.GetTextSize(code)

    draw.SimpleText(code, "LOD_ContainerDINStencil", 5, 6,
        Color(18, 18, 17, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(code, "LOD_ContainerDINStencil", 0, 0,
        color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Cut narrow bridges through enclosed counters to preserve the physical-stencil
    -- appearance while using GMod's bundled condensed industrial surrogate font.
    local charW = totalW / math.max(1, #code)
    for index = 1, #code do
        local ch = string.sub(code, index, index)
        if STENCIL_BRIDGE_CHARS[ch] then
            local cx = -totalW * 0.5 + (index - 0.5) * charW
            local bridgeW = math.max(8, math.floor(charW * 0.10))
            local bridgeH = math.max(18, math.floor(totalH * 0.16))
            local bridgeX = cx - bridgeW * 0.5
            local bridgeY = -bridgeH * 0.15

            if PANEL_MATERIAL and not PANEL_MATERIAL:IsError() then
                surface.SetMaterial(PANEL_MATERIAL)
                surface.SetDrawColor(PANEL_COLOR)
                surface.DrawTexturedRect(bridgeX, bridgeY, bridgeW, bridgeH)
            else
                surface.SetDrawColor(PANEL_COLOR)
                surface.DrawRect(bridgeX, bridgeY, bridgeW, bridgeH)
            end
        end
    end

    surface.SetDrawColor(color.r, color.g, color.b, 225)
    surface.DrawRect(-totalW * 0.5, totalH * 0.44, math.floor(totalW * 0.22), 5)
    surface.DrawRect(totalW * 0.28, totalH * 0.44, math.floor(totalW * 0.22), 5)
end

local function drawMarkedContainer(model, instance, eyePos)
    if not instance or not instance.marked or not IsValid(model) then return end

    local mins, maxs = model:GetRenderBounds()
    local spanY = maxs.y - mins.y
    local spanZ = maxs.z - mins.z

    -- Broad-side normal is local X. The NP logo's longitudinal position is mirrored
    -- between the two broad UV faces, so mirror the Y fraction as the viewed face
    -- changes. This is the key difference from the previous placement routine.
    local forward = model:GetForward()
    local side = forward:Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + SURFACE_OFFSET)
        or (mins.x - SURFACE_OFFSET)
    local yFraction = side > 0 and LOGO_Y_FRACTION or (1 - LOGO_Y_FRACTION)
    local localY = mins.y + spanY * yFraction
    local localZ = mins.z + spanZ * LOGO_Z_FRACTION
    local panelPos = model:LocalToWorld(Vector(localX, localY, localZ))

    local ang = model:GetAngles()
    ang = Angle(ang.p, ang.y, ang.r)
    ang:RotateAroundAxis(ang:Right(), side > 0 and -90 or 90)
    ang:RotateAroundAxis(ang:Up(), 90)
    if side < 0 then ang:RotateAroundAxis(ang:Up(), 180) end

    cam.Start3D2D(panelPos, ang, PANEL_SCALE)
        drawBoard()
        drawStencil(instance.code or "?", instance.stencilColor)
    cam.End3D2D()
end

-- Replace, rather than stack on, the older panel projection. Mark selection remains
-- owned by cl_container_wayfinding_projection.lua; this file owns only final board
-- placement/drawing.
hook.Remove("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding")
hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding", function()
    local world = Wall.world or {}
    if #world == 0 then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local eyePos = EyePos()
    local gx, gy, gz = gridPosition(eyePos)
    local floorBuckets = Wall.labelBuckets and Wall.labelBuckets[gz]
    if not floorBuckets then return end

    local bucketWorld = BUCKET_CELLS * MC.CellSize
    local bucketRadius = math.ceil(DRAW_DISTANCE / bucketWorld) + 1
    local centerBX, centerBY = bucketKey(gx, gy)

    for bx = centerBX - bucketRadius, centerBX + bucketRadius do
        for by = centerBY - bucketRadius, centerBY + bucketRadius do
            local bucket = floorBuckets[tostring(bx) .. ":" .. tostring(by)]
            if bucket then
                for _, index in ipairs(bucket) do
                    local instance = world[index]
                    local model = Wall.models and Wall.models[index]
                    if instance and instance.marked and IsValid(model)
                        and eyePos:DistToSqr(model:GetPos()) <= DRAW_DISTANCE_SQR
                    then
                        drawMarkedContainer(model, instance, eyePos)
                    end
                end
            end
        end
    end
end)
