LOD = LOD or {}
LOD.WallVisualsClient = LOD.WallVisualsClient or {
    logical = {},
    world = {},
    dirty = true
}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local MESSAGE = "LOD_WallVisuals"
local PROTOCOL = 1
local CONTAINER_VISUAL_EMBED = 16

local DIRS = {
    {dx = 0, dy = 1, yaw = 90},
    {dx = 1, dy = 0, yaw = 0},
    {dx = 0, dy = -1, yaw = 90},
    {dx = -1, dy = 0, yaw = 0}
}

local drawDistance = CreateClientConVar(
    "lod_wall_draw_distance",
    "8704",
    true,
    false,
    "Maximum distance for procedural container-wall rendering. Default covers a complete straight 21-cell corridor."
)

local function removeModel()
    if IsValid(Wall.model) then Wall.model:Remove() end
    Wall.model = nil
end

local function ensureModel()
    if IsValid(Wall.model) then return Wall.model end
    local model = ClientsideModel(GC.ContainerModel, RENDERGROUP_OPAQUE)
    if not IsValid(model) then return nil end
    model:SetNoDraw(true)
    model:SetSkin(GC.Skin or 0)
    model:DrawShadow(false)
    Wall.model = model
    return model
end

local function clearManifest()
    Wall.logical = {}
    Wall.world = {}
    Wall.dirty = true
    Wall.lastOrigin = nil
end

net.Receive(MESSAGE, function()
    local byteCount = net.ReadUInt(16)
    if byteCount <= 0 then
        clearManifest()
        return
    end

    local compressed = net.ReadData(byteCount)
    local json = compressed and util.Decompress(compressed) or nil
    local data = json and util.JSONToTable(json) or nil
    if not istable(data) or tonumber(data.v) ~= PROTOCOL or not istable(data.segments) then
        ErrorNoHalt("[LOD] rejected invalid wall visual manifest\n")
        clearManifest()
        return
    end

    local logical = {}
    for _, segment in ipairs(data.segments) do
        if istable(segment) then
            local x = math.floor(tonumber(segment[1]) or 0)
            local y = math.floor(tonumber(segment[2]) or 0)
            local z = math.floor(tonumber(segment[3]) or -1)
            local direction = math.floor(tonumber(segment[4]) or 0)
            if x >= 1 and x <= MC.Width
                and y >= 1 and y <= MC.Height
                and z >= 0 and z < 8
                and DIRS[direction]
            then
                logical[#logical + 1] = {x, y, z, direction}
            end
        end
    end

    Wall.logical = logical
    Wall.world = {}
    Wall.dirty = true
    Wall.lastOrigin = nil
end)

local function originChanged(origin)
    local previous = Wall.lastOrigin
    return not previous or previous:DistToSqr(origin) > 0.0001
end

local function rebuildWorldCache()
    local origin = MC.Origin or vector_origin
    if not Wall.dirty and not originChanged(origin) then return end

    local out = {}
    local halfWidth = (MC.Width + 1) * 0.5
    local halfHeight = (MC.Height + 1) * 0.5
    local stackCount = math.max(1, GC.WallStack or 2)

    for _, segment in ipairs(Wall.logical or {}) do
        local direction = DIRS[segment[4]]
        if direction then
            local baseX = (segment[1] - halfWidth) * MC.CellSize
                + direction.dx * MC.CellSize * 0.5
            local baseY = (segment[2] - halfHeight) * MC.CellSize
                + direction.dy * MC.CellSize * 0.5
            local baseZ = segment[3] * MC.LevelHeight
            local angle = Angle(0, direction.yaw, 0)

            for stack = 0, stackCount - 1 do
                out[#out + 1] = {
                    pos = origin + Vector(
                        baseX,
                        baseY,
                        baseZ + GC.ContainerHeight * 0.5
                            + stack * GC.ContainerHeight
                            - CONTAINER_VISUAL_EMBED
                    ),
                    ang = angle
                }
            end
        end
    end

    Wall.world = out
    Wall.lastOrigin = Vector(origin.x, origin.y, origin.z)
    Wall.dirty = false
end

hook.Add("PostDrawOpaqueRenderables", "LOD_DrawProceduralContainerWalls", function(drawingDepth, drawingSkybox, drawing3DSkybox)
    if drawingDepth or drawingSkybox or drawing3DSkybox then return end
    if not Wall.logical or #Wall.logical == 0 then return end

    rebuildWorldCache()
    local model = ensureModel()
    if not IsValid(model) then return end

    local eye = EyePos()
    local forward = EyeVector()
    local maximum = math.max(MC.CellSize * 4, drawDistance:GetFloat())
    local maximumSqr = maximum * maximum
    local nearSqr = (MC.CellSize * 1.5) ^ 2

    for _, instance in ipairs(Wall.world or {}) do
        local delta = instance.pos - eye
        local distanceSqr = delta:LengthSqr()
        -- A generous plane behind the camera removes work the player cannot see
        -- without clipping models at the peripheral edge. The default distance
        -- still covers an end-to-end straight corridor.
        if distanceSqr <= maximumSqr
            and (distanceSqr <= nearSqr or delta:Dot(forward) >= -MC.CellSize)
        then
            model:SetPos(instance.pos)
            model:SetAngles(instance.ang)
            -- DrawModel retains the first transform when one entity is drawn
            -- repeatedly in a frame unless its bone matrices are rebuilt.
            model:SetupBones()
            model:DrawModel()
        end
    end
end)

hook.Add("ShutDown", "LOD_WallVisualsClientCleanup", removeModel)

concommand.Add("lod_wall_visuals_status", function()
    rebuildWorldCache()
    print(string.format(
        "[LOD:WALL-VISUALS] logical=%d instances=%d drawDistance=%.0f model=%s",
        #(Wall.logical or {}), #(Wall.world or {}), drawDistance:GetFloat(),
        IsValid(Wall.model) and "ready" or "not-created"
    ))
end)
