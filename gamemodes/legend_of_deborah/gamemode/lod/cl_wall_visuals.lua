LOD = LOD or {}
LOD.WallVisualsClient = LOD.WallVisualsClient or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local MESSAGE = "LOD_WallVisuals"
local PROTOCOL = 1
local CONTAINER_VISUAL_EMBED = 16
local MODEL_BATCH_SIZE = 128

Wall.logical = Wall.logical or {}
Wall.world = Wall.world or {}
Wall.models = Wall.models or {}
Wall.dirty = Wall.dirty ~= false
Wall.nextModel = Wall.nextModel or 1

local DIRS = {
    {dx = 0, dy = 1, yaw = 90},
    {dx = 1, dy = 0, yaw = 0},
    {dx = 0, dy = -1, yaw = 90},
    {dx = -1, dy = 0, yaw = 0}
}

local function removeModels()
    for _, model in pairs(Wall.models or {}) do
        if IsValid(model) then model:Remove() end
    end
    Wall.models = {}
    Wall.nextModel = 1
end

local function clearManifest()
    removeModels()
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

    removeModels()
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
    if not Wall.dirty and not originChanged(origin) then return false end

    removeModels()
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
    Wall.nextModel = 1
    return true
end

local function spawnModel(instance)
    local model = ClientsideModel(GC.ContainerModel, RENDERGROUP_OPAQUE)
    if not IsValid(model) then return nil end

    -- Keep construction invisible until the transform is complete. Each wall
    -- instance then follows the engine's ordinary, proven model-rendering path;
    -- no server entity or manual repeated DrawModel call is required.
    model:SetNoDraw(true)
    model:SetPos(instance.pos)
    model:SetAngles(instance.ang)
    model:SetSkin(GC.Skin or 0)
    model:DrawShadow(false)
    model:SetNoDraw(false)
    return model
end

local function buildModelBatch()
    rebuildWorldCache()
    local total = #(Wall.world or {})
    local first = Wall.nextModel or 1
    if first > total then return end

    local last = math.min(total, first + MODEL_BATCH_SIZE - 1)
    for index = first, last do
        Wall.models[index] = spawnModel(Wall.world[index])
    end
    Wall.nextModel = last + 1
end

hook.Add("Think", "LOD_BuildProceduralContainerWalls", function()
    if not Wall.logical or #Wall.logical == 0 then return end
    buildModelBatch()
end)

hook.Add("ShutDown", "LOD_WallVisualsClientCleanup", removeModels)

concommand.Add("lod_wall_visuals_status", function()
    rebuildWorldCache()
    local active = 0
    for _, model in pairs(Wall.models or {}) do
        if IsValid(model) then active = active + 1 end
    end
    local total = #(Wall.world or {})
    print(string.format(
        "[LOD:WALL-VISUALS] logical=%d instances=%d clientModels=%d pending=%d",
        #(Wall.logical or {}), total, active, math.max(0, total - active)
    ))
end)
