LOD = LOD or {}
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["meshes"] = "stability-20260915-03"
LOD.TexturedBox = LOD.TexturedBox or {}

local TexturedBox = LOD.TexturedBox
-- Reclaim owned native meshes on Lua refresh, map cleanup and shutdown.
if TexturedBox.ClearMeshCache then TexturedBox:ClearMeshCache() end
local meshCache, cacheCount, clock = {}, 0, 0
local MAX_MESHES = 256
function TexturedBox:ClearMeshCache()
    for _, entry in pairs(meshCache) do entry.mesh:Destroy() end
    meshCache, cacheCount = {}, 0
end
function TexturedBox:MeshCacheCount() return cacheCount end
hook.Add("PostCleanupMap", "LOD_TexturedBoxMeshes", function() TexturedBox:ClearMeshCache() end)
hook.Add("ShutDown", "LOD_TexturedBoxMeshes", function() TexturedBox:ClearMeshCache() end)
local DEFAULT_TILE = 384

function TexturedBox:GetIndustrialMaterial(fallbackPath)
    local GC = LOD and LOD.Config and LOD.Config.Geometry or {}
    local primary = GC.FloorMaterial or "models/props_wasteland/metal_tram001a"
    local mat = Material(primary)
    if mat and not mat:IsError() then return mat end
    return Material(fallbackPath or GC.FloorMaterialFallback or "models/props_c17/FurnitureMetal001a")
end

local function cacheKey(prefix, mins, maxs, tile)
    return string.format("%s|%.3f,%.3f,%.3f|%.3f,%.3f,%.3f|%.3f",
        prefix, mins.x, mins.y, mins.z, maxs.x, maxs.y, maxs.z, tile)
end

local function pushVertex(pos, normal, tangentS, tangentT, u, v)
    mesh.Position(pos)
    mesh.Normal(normal)
    mesh.TangentS(tangentS)
    mesh.TangentT(tangentT)
    mesh.UserData(tangentS.x, tangentS.y, tangentS.z, 1)
    mesh.TexCoord(0, u, v)
    mesh.Color(255, 255, 255, 255)
    mesh.AdvanceVertex()
end

local function addQuad(a, b, c, d, normal, tangentS, tangentT, uMax, vMax)
    pushVertex(a, normal, tangentS, tangentT, 0, 0)
    pushVertex(b, normal, tangentS, tangentT, uMax, 0)
    pushVertex(c, normal, tangentS, tangentT, uMax, vMax)
    pushVertex(d, normal, tangentS, tangentT, 0, vMax)
end

local function addTopBottom(mins, maxs, tile)
    local dx = math.abs(maxs.x - mins.x)
    local dy = math.abs(maxs.y - mins.y)

    addQuad(
        Vector(mins.x, mins.y, maxs.z), Vector(maxs.x, mins.y, maxs.z),
        Vector(maxs.x, maxs.y, maxs.z), Vector(mins.x, maxs.y, maxs.z),
        Vector(0, 0, 1), Vector(1, 0, 0), Vector(0, 1, 0), dx / tile, dy / tile
    )
    addQuad(
        Vector(mins.x, maxs.y, mins.z), Vector(maxs.x, maxs.y, mins.z),
        Vector(maxs.x, mins.y, mins.z), Vector(mins.x, mins.y, mins.z),
        Vector(0, 0, -1), Vector(1, 0, 0), Vector(0, -1, 0), dx / tile, dy / tile
    )
end

local function buildBoxMesh(mins, maxs, tile)
    tile = math.max(1, tile or DEFAULT_TILE)
    local dx = math.abs(maxs.x - mins.x)
    local dy = math.abs(maxs.y - mins.y)
    local dz = math.abs(maxs.z - mins.z)

    local obj = Mesh()
    mesh.Begin(obj, MATERIAL_QUADS, 6)

    addTopBottom(mins, maxs, tile)

    addQuad(
        Vector(maxs.x, mins.y, mins.z), Vector(maxs.x, maxs.y, mins.z),
        Vector(maxs.x, maxs.y, maxs.z), Vector(maxs.x, mins.y, maxs.z),
        Vector(1, 0, 0), Vector(0, 1, 0), Vector(0, 0, 1), dy / tile, dz / tile
    )
    addQuad(
        Vector(mins.x, maxs.y, mins.z), Vector(mins.x, mins.y, mins.z),
        Vector(mins.x, mins.y, maxs.z), Vector(mins.x, maxs.y, maxs.z),
        Vector(-1, 0, 0), Vector(0, -1, 0), Vector(0, 0, 1), dy / tile, dz / tile
    )
    addQuad(
        Vector(maxs.x, maxs.y, mins.z), Vector(mins.x, maxs.y, mins.z),
        Vector(mins.x, maxs.y, maxs.z), Vector(maxs.x, maxs.y, maxs.z),
        Vector(0, 1, 0), Vector(-1, 0, 0), Vector(0, 0, 1), dx / tile, dz / tile
    )
    addQuad(
        Vector(mins.x, mins.y, mins.z), Vector(maxs.x, mins.y, mins.z),
        Vector(maxs.x, mins.y, maxs.z), Vector(mins.x, mins.y, maxs.z),
        Vector(0, -1, 0), Vector(1, 0, 0), Vector(0, 0, 1), dx / tile, dz / tile
    )

    mesh.End()
    return obj
end

local function buildSlabMesh(mins, maxs, tile)
    tile = math.max(1, tile or DEFAULT_TILE)
    local obj = Mesh()
    mesh.Begin(obj, MATERIAL_QUADS, 2)
    addTopBottom(mins, maxs, tile)
    mesh.End()
    return obj
end

local function finite(n)
    return type(n) == "number" and n == n and n > -math.huge and n < math.huge
end
local function getMesh(prefix, mins, maxs, tile, build)
    tile = tonumber(tile) or DEFAULT_TILE
    if not mins or not maxs or not finite(tile) then return nil end
    for _, axis in ipairs({"x", "y", "z"}) do
        if not finite(mins[axis]) or not finite(maxs[axis]) or maxs[axis] < mins[axis] then return nil end
    end
    if maxs.x == mins.x or maxs.y == mins.y then return nil end
    tile = math.max(1, tile)
    local key = cacheKey(prefix, mins, maxs, tile)
    clock = clock + 1
    local entry = meshCache[key]
    if entry then entry.used = clock; return entry.mesh end
    if cacheCount >= MAX_MESHES then
        local oldest, age
        for k, v in pairs(meshCache) do
            if not age or v.used < age then oldest, age = k, v.used end
        end
        meshCache[oldest].mesh:Destroy()
        meshCache[oldest] = nil
        cacheCount = cacheCount - 1
    end
    local obj = build(mins, maxs, tile)
    meshCache[key] = {mesh=obj, used=clock}
    cacheCount = cacheCount + 1
    return obj
end
function TexturedBox:GetMesh(mins, maxs, tile)
    return getMesh("box", mins, maxs, tile, buildBoxMesh)
end
function TexturedBox:GetSlabMesh(mins, maxs, tile)
    return getMesh("slab", mins, maxs, tile, buildSlabMesh)
end

local function drawMesh(obj, position, angles, material, color)
    if not obj or not position or not material then return end

    render.SetMaterial(material)
    local c = color or color_white
    render.SetColorModulation(c.r / 255, c.g / 255, c.b / 255)
    render.SetBlend((c.a or 255) / 255)

    local matrix = Matrix()
    matrix:Translate(position)
    if angles and angles ~= angle_zero then matrix:Rotate(angles) end

    cam.PushModelMatrix(matrix)
    obj:Draw()
    cam.PopModelMatrix()

    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
end

function TexturedBox:Draw(position, angles, mins, maxs, material, color, tile)
    if not position or not mins or not maxs or not material then return end
    drawMesh(self:GetMesh(mins, maxs, tile), position, angles, material, color)
end

-- Ordinary floor runs are visually one continuous horizontal deck. Rendering the
-- vertical side faces of every row-run box exposed internal seams at low camera
-- angles and made a mathematically flat floor look like a staircase. Slab mode
-- intentionally draws only the walkable top and ceiling underside. Real stair
-- geometry and the gate continue to use the full six-face renderer.
function TexturedBox:DrawSlab(position, angles, mins, maxs, material, color, tile)
    if not position or not mins or not maxs or not material then return end
    drawMesh(self:GetSlabMesh(mins, maxs, tile), position, angles, material, color)
end
