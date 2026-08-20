LOD = LOD or {}
LOD.TexturedBox = LOD.TexturedBox or {}

local TexturedBox = LOD.TexturedBox
local meshCache = meshCache or {}
local DEFAULT_TILE = 128

local function cacheKey(mins, maxs, tile)
    return string.format("%.3f,%.3f,%.3f|%.3f,%.3f,%.3f|%.3f",
        mins.x, mins.y, mins.z, maxs.x, maxs.y, maxs.z, tile)
end

local function pushVertex(pos, normal, tangentS, tangentT, u, v)
    mesh.Position(pos)
    mesh.Normal(normal)
    mesh.TangentS(tangentS)
    mesh.TangentT(tangentT)
    -- Some Source bump-mapped shaders consume tangent data through USERDATA.
    -- Supplying it as well as TangentS/T keeps stock materials well behaved.
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

local function buildMesh(mins, maxs, tile)
    tile = math.max(1, tile or DEFAULT_TILE)
    local dx = math.abs(maxs.x - mins.x)
    local dy = math.abs(maxs.y - mins.y)
    local dz = math.abs(maxs.z - mins.z)

    local obj = Mesh()
    mesh.Begin(obj, MATERIAL_QUADS, 6)

    -- Top / bottom.
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

    -- +/- X faces.
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

    -- +/- Y faces.
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

function TexturedBox:GetMesh(mins, maxs, tile)
    tile = tile or DEFAULT_TILE
    local key = cacheKey(mins, maxs, tile)
    if not meshCache[key] then
        meshCache[key] = buildMesh(mins, maxs, tile)
    end
    return meshCache[key]
end

function TexturedBox:Draw(position, angles, mins, maxs, material, color, tile)
    if not position or not mins or not maxs or not material then return end

    local obj = self:GetMesh(mins, maxs, tile)
    if not obj then return end

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
