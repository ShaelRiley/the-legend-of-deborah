LOD = LOD or {}
LOD.TexturedBox = LOD.TexturedBox or {}

local TexturedBox = LOD.TexturedBox
local boxMeshCache = boxMeshCache or {}
local slabMeshCache = slabMeshCache or {}
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

function TexturedBox:GetMesh(mins, maxs, tile)
    tile = tile or DEFAULT_TILE
    local key = cacheKey("box", mins, maxs, tile)
    if not boxMeshCache[key] then
        boxMeshCache[key] = buildBoxMesh(mins, maxs, tile)
    end
    return boxMeshCache[key]
end

function TexturedBox:GetSlabMesh(mins, maxs, tile)
    tile = tile or DEFAULT_TILE
    local key = cacheKey("slab", mins, maxs, tile)
    if not slabMeshCache[key] then
        slabMeshCache[key] = buildSlabMesh(mins, maxs, tile)
    end
    return slabMeshCache[key]
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
