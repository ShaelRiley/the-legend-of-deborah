LOD = LOD or {}
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["meshes"] = "generator-jit-20260917-01"
LOD.TexturedBox = LOD.TexturedBox or {}

local TexturedBox = LOD.TexturedBox
-- Reclaim owned native meshes on Lua refresh, map cleanup and shutdown.
if TexturedBox.ClearMeshCache then TexturedBox:ClearMeshCache() end
local meshCache, cacheCount, clock = {}, 0, 0
local drawCache = setmetatable({}, {__mode = "k"})
local MAX_MESHES = 256
function TexturedBox:ClearMeshCache()
    for _, entry in pairs(meshCache) do
        entry.mesh:Destroy()
        entry.mesh = nil -- invalidate borrowed handles before the next draw
    end
    meshCache, cacheCount = {}, 0
    drawCache = setmetatable({}, {__mode = "k"})
end
function TexturedBox:MeshCacheCount() return cacheCount end
hook.Add("PostCleanupMap", "LOD_TexturedBoxMeshes", function() TexturedBox:ClearMeshCache() end)
hook.Add("ShutDown", "LOD_TexturedBoxMeshes", function() TexturedBox:ClearMeshCache() end)
local DEFAULT_TILE = 384

function TexturedBox:GetIndustrialMaterial(fallbackPath)
    local GC = LOD and LOD.Config and LOD.Config.Geometry or {}
    local primary = GC.FloorMaterial or "models/props_wasteland/metal_tram001a"
    local mat = Material(primary)
    local texture = mat and not mat:IsError() and mat:GetTexture("$basetexture")
    if texture and not texture:IsError() then return mat, false end
    return Material(fallbackPath or GC.FloorMaterialFallback or "models/props_c17/FurnitureMetal001a"), true
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

-- UVs are world-planar for slabs, including partial/rotated stair aprons.
local function slabQuad(a,b,c,d,normal,tangentS,tangentT,tile,uv)
    for _,p in ipairs({a,b,c,d}) do
        local x=p.x*uv[1]-p.y*uv[2]+uv[3]
        local y=p.x*uv[2]+p.y*uv[1]+uv[4]
        pushVertex(p,normal,tangentS,tangentT,x/tile,y/tile)
    end
end
local function addTopBottom(mins, maxs, tile, uv)
    if uv then
        slabQuad(Vector(mins.x,mins.y,maxs.z),Vector(maxs.x,mins.y,maxs.z),
            Vector(maxs.x,maxs.y,maxs.z),Vector(mins.x,maxs.y,maxs.z),
            Vector(0,0,1),Vector(1,0,0),Vector(0,1,0),tile,uv)
        slabQuad(Vector(mins.x,maxs.y,mins.z),Vector(maxs.x,maxs.y,mins.z),
            Vector(maxs.x,mins.y,mins.z),Vector(mins.x,mins.y,mins.z),
            Vector(0,0,-1),Vector(1,0,0),Vector(0,-1,0),tile,uv)
        return
    end
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

local function emitBox(mins,maxs,tile)
    local dx,dy,dz=maxs.x-mins.x,maxs.y-mins.y,maxs.z-mins.z
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

end

local function buildBoxMesh(mins, maxs, tile)
    tile = math.max(1, tile or DEFAULT_TILE)
    local dx = math.abs(maxs.x - mins.x)
    local dy = math.abs(maxs.y - mins.y)
    local dz = math.abs(maxs.z - mins.z)

    local obj = Mesh()
    mesh.Begin(obj, MATERIAL_QUADS, 6)

    emitBox(mins,maxs,tile)
    mesh.End()
    return obj
end

local function buildSlabMesh(mins, maxs, tile, uv)
    tile = math.max(1, tile or DEFAULT_TILE)
    local obj = Mesh()
    mesh.Begin(obj, MATERIAL_QUADS, 2)
    addTopBottom(mins, maxs, tile, uv)
    mesh.End()
    return obj
end

local function finite(n)
    return type(n) == "number" and n == n and n > -math.huge and n < math.huge
end
local function getMesh(prefix, mins, maxs, tile, build, uv)
    tile = tonumber(tile) or DEFAULT_TILE
    if not mins or not maxs or not finite(tile) then return nil end
    for _, axis in ipairs({"x", "y", "z"}) do
        if not finite(mins[axis]) or not finite(maxs[axis]) or maxs[axis] < mins[axis] then return nil end
    end
    if maxs.x == mins.x or maxs.y == mins.y then return nil end
    tile = math.max(1, tile)
    local key = cacheKey(prefix, mins, maxs, tile)
    if uv then
        for _,v in ipairs(uv) do if not finite(v) then return nil end end
        key=key..string.format("|%.5f,%.5f,%.5f,%.5f",uv[1],uv[2],uv[3],uv[4])
    end
    clock = clock + 1
    local entry = meshCache[key]
    if entry then entry.used = clock; return entry.mesh, entry end
    if cacheCount >= MAX_MESHES then
        local oldest, age
        for k, v in pairs(meshCache) do
            if not age or v.used < age then oldest, age = k, v.used end
        end
        meshCache[oldest].mesh:Destroy()
        meshCache[oldest].mesh = nil
        meshCache[oldest] = nil
        cacheCount = cacheCount - 1
    end
    local obj = build(mins, maxs, tile, uv)
    entry = {mesh=obj, used=clock}
    meshCache[key] = entry
    cacheCount = cacheCount + 1
    return obj, entry
end
function TexturedBox:GetMesh(mins, maxs, tile)
    return getMesh("box", mins, maxs, tile, buildBoxMesh)
end
function TexturedBox:GetSlabMesh(mins, maxs, tile, position, angles)
    local uv
    if position then
        local yaw=math.rad(angles and angles.y or 0)
        local t=math.max(1,tile or DEFAULT_TILE)
        uv={math.cos(yaw),math.sin(yaw),position.x%t,position.y%t}
    end
    return getMesh("slab", mins, maxs, tile, buildSlabMesh, uv)
end

-- Static entities repeatedly draw identical local geometry. Borrow the existing
-- bounded cache entry instead of rebuilding its string key/UV inputs each frame.
-- Scalar copies detect in-place native vector/angle updates. Weak keys do not
-- retain removed entities; eviction clears entry.mesh so a borrow cannot outlive
-- its native resource. Each hit still renews the canonical LRU clock.
local function resolveDrawMesh(prefix, position, angles, mins, maxs, tile, build)
    if prefix == "slab" then return TexturedBox:GetSlabMesh(mins, maxs, tile, position, angles) end
    return getMesh(prefix, mins, maxs, tile, build)
end
local function cachedDraw(owner, prefix, position, angles, mins, maxs, tile, build)
    if not owner then
        local obj = resolveDrawMesh(prefix, position, angles, mins, maxs, tile, build)
        return obj -- the second getMesh return is a cache entry, not a matrix
    end
    local row = drawCache[owner]
    if not row then row = {}; drawCache[owner] = row end
    local yaw = angles and angles.y or 0
    local entry = row.entry
    if not entry or not entry.mesh or row.prefix ~= prefix or row.tile ~= tile
        or row.x0 ~= mins.x or row.y0 ~= mins.y or row.z0 ~= mins.z
        or row.x1 ~= maxs.x or row.y1 ~= maxs.y or row.z1 ~= maxs.z
        or (prefix == "slab" and (row.uvX ~= position.x or row.uvY ~= position.y or row.uvYaw ~= yaw)) then
        local obj
        obj, entry = resolveDrawMesh(prefix, position, angles, mins, maxs, tile, build)
        row.entry = entry
        if not obj then return nil end
        row.prefix, row.tile = prefix, tile
        row.x0, row.y0, row.z0 = mins.x, mins.y, mins.z
        row.x1, row.y1, row.z1 = maxs.x, maxs.y, maxs.z
        row.uvX, row.uvY, row.uvYaw = position.x, position.y, yaw
    else
        clock = clock + 1
        entry.used = clock
    end
    local pitch, roll = angles and angles.p or 0, angles and angles.r or 0
    if not row.matrix or row.px ~= position.x or row.py ~= position.y or row.pz ~= position.z
        or row.pitch ~= pitch or row.yaw ~= yaw or row.roll ~= roll then
        local matrix = Matrix()
        matrix:Translate(position)
        if angles and angles ~= angle_zero then matrix:Rotate(angles) end
        row.matrix = matrix
        row.px, row.py, row.pz = position.x, position.y, position.z
        row.pitch, row.yaw, row.roll = pitch, yaw, roll
    end
    return entry.mesh, row.matrix
end

local function drawMesh(obj, position, angles, material, color, matrix)
    if not obj or not position or not material then return end

    render.SetMaterial(material)
    local c = color or color_white
    render.SetColorModulation(c.r / 255, c.g / 255, c.b / 255)
    render.SetBlend((c.a or 255) / 255)

    if not matrix then
        matrix = Matrix()
        matrix:Translate(position)
        if angles and angles ~= angle_zero then matrix:Rotate(angles) end
    end

    cam.PushModelMatrix(matrix)
    obj:Draw()
    cam.PopModelMatrix()

    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
end

function TexturedBox:Draw(position, angles, mins, maxs, material, color, tile, owner)
    if not position or not mins or not maxs or not material then return end
    local obj, matrix = cachedDraw(owner, "box", position, angles, mins, maxs, tile,
        buildBoxMesh)
    drawMesh(obj, position, angles, material, color, matrix)
end

-- Ordinary floor runs are visually one continuous horizontal deck. Rendering the
-- vertical side faces of every row-run box exposed internal seams at low camera
-- angles and made a mathematically flat floor look like a staircase. Slab mode
-- intentionally draws only the walkable top and ceiling underside. Real stair
-- geometry and the gate continue to use the full six-face renderer.
function TexturedBox:DrawSlab(position, angles, mins, maxs, material, color, tile, owner)
    if not position or not mins or not maxs or not material then return end
    local obj, matrix = cachedDraw(owner, "slab", position, angles, mins, maxs, tile)
    drawMesh(obj, position, angles, material, color, matrix)
end

-- Six-sided steel bars and rim give credible undersides. The original 32-unit
-- collision slab stays solid: sight only, never a shot/drop/progression bypass.
local function buildGrateMesh(mins,maxs,tile)
    local C=LOD.CrateVisuals
    local inset,pitch,bar=C.GrateInset,C.GratePitch,C.GrateBarWidth
    local x0,x1,y0,y1=mins.x+inset,maxs.x-inset,mins.y+inset,maxs.y-inset
    local boxes={{mins.x,mins.y,x0,maxs.y},{x1,mins.y,maxs.x,maxs.y},
        {x0,mins.y,x1,y0},{x0,y1,x1,maxs.y}}
    for x=x0,x1-bar,pitch do boxes[#boxes+1]={x,y0,math.min(x+bar,x1),y1} end
    for y=y0,y1-bar,pitch do boxes[#boxes+1]={x0,y,x1,math.min(y+bar,y1)} end
    local obj=Mesh()
    mesh.Begin(obj,MATERIAL_QUADS,#boxes*6)
    for _,b in ipairs(boxes) do
        emitBox(Vector(b[1],b[2],maxs.z-8),Vector(b[3],b[4],maxs.z),tile)
    end
    mesh.End()
    return obj
end
function TexturedBox:DrawGrate(position,angles,mins,maxs,owner)
    local material=Material("models/props_c17/FurnitureMetal001a")
    local obj, matrix = cachedDraw(owner, "crate-grate", position, angles, mins, maxs, 128,
        buildGrateMesh)
    drawMesh(obj,position,angles,material,Color(105,110,112),matrix)
end
