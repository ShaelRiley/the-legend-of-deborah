-- Reduced Effects extends the canonical wall manifest/appearance owner. Stock
-- hull triangles, UVs, two-container stacks and overlays remain exact; spatial
-- chunks replace thousands of native model submissions with simpler lighting.
-- Native models remain as transform/overlay handles and a transactional fallback.
local Wall, MC, GC = LOD.WallVisualsClient, LOD.Config.Maze, LOD.Config.Geometry
if Wall.ClearBatches then Wall:ClearBatches() end
local C = LOD.CrateVisuals
local TILE_CELLS, MAX_VERTICES, MAX_CHUNKS, MAX_TOTAL_VERTICES = 4, 60000, 512, 4000000
local state, source, sourceError
-- GMod keeps CreateMaterial names across Lua refresh. Retain texture-to-shader
-- ownership too, so a changed candidate/fallback order cannot reuse a shader
-- name with another texture. Two shared shaders, never per wall/section/chunk.
local materials = Wall.batchMaterials or {}
Wall.batchMaterials = materials
local function enabled()
    local cv = GetConVar("lod_reduced_effects")
    return cv and cv:GetBool() or false
end
local function finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end

function Wall:ClearBatches()
    for _, chunk in ipairs(state and state.chunks or {}) do
        if chunk.mesh then chunk.mesh:Destroy(); chunk.mesh=nil end
        for _, index in ipairs(chunk.indices) do
            local model = state.models[index]
            if IsValid(model) then model:SetNoDraw(false) end
        end
    end
    state = nil
    self.batchStats = {status="off", chunks=0, hidden=0, draws=0, visits=0, vertices=0}
end
Wall:ClearBatches()

local function modelSource()
    if source or sourceError then return source end
    if not util.GetModelMeshes or not Mesh then sourceError="mesh-api-unavailable"; return end
    local ok, meshes = pcall(util.GetModelMeshes, GC.ContainerModel, 0, 0, GC.Skin or 0)
    if not ok or not meshes or #meshes~=1 then sourceError="unsupported-model"; return end
    local triangles = meshes[1].triangles
    if not triangles or #triangles==0 or #triangles%3~=0 or #triangles>MAX_VERTICES then
        sourceError="invalid-triangles"; return
    end
    local lo,hi=Vector(math.huge,math.huge,math.huge),Vector(-math.huge,-math.huge,-math.huge)
    for _,v in ipairs(triangles) do
        if not v.pos or not v.normal or not finite(v.u) or not finite(v.v) then sourceError="invalid-vertex"; return end
        for _,axis in ipairs({"x","y","z"}) do
            if not finite(v.pos[axis]) or not finite(v.normal[axis]) then sourceError="invalid-vertex"; return end
            lo[axis]=math.min(lo[axis],v.pos[axis]);hi[axis]=math.max(hi[axis],v.pos[axis])
        end
    end
    -- A changed/rigged/missing stock model must use native rendering, never a
    -- guessed bone transform or bounding-box substitute. These are verified VVD
    -- bounds of the mounted stock cargo mesh used by branding and collision QA.
    for _,axis in ipairs({"x","y","z"}) do
        if math.abs(lo[axis]-C.CargoMins[axis])>1 or math.abs(hi[axis]-C.CargoMaxs[axis])>1 then
            sourceError="stock-bounds-mismatch"; return
        end
    end
    source=triangles
    return source
end

local function appearance(instance)
    local name=instance.sectionMaterialName
    if not name or instance.appliedSectionMode~="file-backed-global" then return end
    local original=Material(name)
    if not original or original:IsError() then return end
    local texture=original:GetTexture("$basetexture")
    if not texture or texture:IsError() then return end
    local path=texture:GetName()
    local slot=materials[path]
    if not slot then
        local n=0;for _ in pairs(materials) do n=n+1 end
        if n>=2 then return end
        local mat=CreateMaterial("lod_wall_batch_diffuse_"..(n+1),"UnlitGeneric",{
            ["$basetexture"]=path,["$vertexcolor"]="1",["$vertexalpha"]="1"})
        if not mat or mat:IsError() then return end
        slot={material=mat};materials[path]=slot
    end
    -- Exactly the section shader's tint, baked per vertex so adjacent sections
    -- share one submission. Reduced mode intentionally omits model bump lighting.
    local tint=original:GetVector("$color2") or Vector(1,1,1)
    return slot.material, Color(math.Clamp(math.floor(tint.x*255+.5),0,255),
        math.Clamp(math.floor(tint.y*255+.5),0,255),math.Clamp(math.floor(tint.z*255+.5),0,255))
end

local function rotated(v,co,si)
    return Vector(v.x*co-v.y*si,v.x*si+v.y*co,v.z)
end
local function buildChunk(chunk)
    local vertices={}
    local lo,hi=Vector(math.huge,math.huge,math.huge),Vector(-math.huge,-math.huge,-math.huge)
    for _,index in ipairs(chunk.indices) do
        local instance,model=state.world[index],state.models[index]
        if not IsValid(model) then return false,"missing-model" end
        local material,color=appearance(instance)
        if not material or material~=chunk.material then return false,"appearance-changed" end
        local yaw=math.rad(instance.ang.y)
        local co,si=math.cos(yaw),math.sin(yaw)
        for _,v in ipairs(source) do
            local pos=rotated(v.pos,co,si)+instance.pos
            local row={pos=pos,normal=rotated(v.normal,co,si),u=v.u,v=v.v,color=color}
            if v.tangent then row.tangent=rotated(v.tangent,co,si) end
            if v.binormal then row.binormal=rotated(v.binormal,co,si) end
            vertices[#vertices+1]=row
            for _,axis in ipairs({"x","y","z"}) do
                lo[axis]=math.min(lo[axis],pos[axis]);hi[axis]=math.max(hi[axis],pos[axis])
            end
        end
    end
    chunk.mesh=Mesh(chunk.material)
    chunk.mesh:BuildFromTriangles(vertices)
    chunk.center=(lo+hi)*.5
    local delta=hi-chunk.center
    chunk.radius=math.sqrt(delta.x*delta.x+delta.y*delta.y+delta.z*delta.z)+1
    chunk.vertices=#vertices
    -- Commit only after complete native mesh construction. Until this point,
    -- the original models continue drawing: build errors cannot erase a wall.
    for _,index in ipairs(chunk.indices) do state.models[index]:SetNoDraw(true) end
    return true
end

local function begin()
    state={world=Wall.world,models=Wall.models,seed=Wall.seed,chunks={},cursor=1}
    if not modelSource() then Wall.batchStats.status="fallback";Wall.batchStats.reason=sourceError;return end
    local groups={}
    local appearances={}
    local reservedVertices=0
    for index,instance in ipairs(state.world) do
        if IsValid(state.models[index]) and reservedVertices+#source<=MAX_TOTAL_VERTICES then
            local name=instance.sectionMaterialName
            local material=appearances[name]
            if not material then material=appearance(instance);if name then appearances[name]=material end end
            if material then
                local key=math.floor((instance.gridX-1)/TILE_CELLS)..":"..
                    math.floor((instance.gridY-1)/TILE_CELLS)..":"..instance.floor..":"..instance.stackIndex..":"..tostring(material)
                local chunk=groups[key]
                if not chunk or (#chunk.indices+1)*#source>MAX_VERTICES then
                    if #state.chunks<MAX_CHUNKS then
                        chunk={indices={},material=material};groups[key]=chunk
                        state.chunks[#state.chunks+1]=chunk
                    else chunk=nil end
                end
                if chunk then chunk.indices[#chunk.indices+1]=index;reservedVertices=reservedVertices+#source end
            end
        end
    end
    Wall.batchStats.status=#state.chunks>0 and "building" or "fallback"
    Wall.batchStats.chunks=#state.chunks
    Wall.batchStats.reserved_vertices=reservedVertices
end

hook.Add("Think","LOD_BuildContainerBatches",function()
    if not enabled() then if state then Wall:ClearBatches() end;return end
    if not Wall.sectionMaterialsReady or (state and (state.world~=Wall.world or state.models~=Wall.models or state.seed~=Wall.seed)) then
        if state then Wall:ClearBatches() end
        return
    end
    if not state then
        if not Wall.world or #Wall.world==0 then return end
        begin()
    end
    while state.cursor<=#state.chunks do
        local chunk=state.chunks[state.cursor]
        local ok,result,why=pcall(buildChunk,chunk)
        if ok and result then
            Wall.batchStats.hidden=Wall.batchStats.hidden+#chunk.indices
            Wall.batchStats.vertices=Wall.batchStats.vertices+chunk.vertices
        else
            if chunk.mesh then chunk.mesh:Destroy();chunk.mesh=nil end
            for _,index in ipairs(chunk.indices) do
                local model=state.models[index];if IsValid(model) then model:SetNoDraw(false) end
            end
            Wall.batchStats.reason=tostring(ok and why or result)
        end
        state.cursor=state.cursor+1
        -- At most ONE native upload per Think; a slow upload never causes a
        -- catch-up burst. No whole-maze rebuild in the render hook.
        break
    end
    if state.cursor>#state.chunks and Wall.batchStats.status=="building" then Wall.batchStats.status="ready" end
end)

local function perspective(view)
    if not view or view.ortho or view.offcenter or not view.origin or not view.angles
        or not finite(view.fov) or view.fov<=0 or view.fov>=180 or not finite(view.aspect) or view.aspect<=0
        or not finite(view.znear) or view.znear<0
        or not view.angles.Forward or not view.angles.Right or not view.angles.Up then return end
    local f,r,u=view.angles:Forward(),view.angles:Right(),view.angles:Up()
    for _,v in ipairs({view.origin,f,r,u}) do
        if not v or not finite(v.x) or not finite(v.y) or not finite(v.z) then return end
    end
    local tx=math.tan(math.rad(view.fov)*.5);local ty=tx/view.aspect
    return view.origin,f,r,u,tx,ty,math.sqrt(1+tx*tx),math.sqrt(1+ty*ty)
end
local function visible(chunk,eye,f,r,u,tx,ty,nx,ny)
    if not eye then return true end
    local p=chunk.center
    local x,y,z=p.x-eye.x,p.y-eye.y,p.z-eye.z
    local depth=x*f.x+y*f.y+z*f.z
    local radius=chunk.radius
    if depth < -radius then return false end
    return math.abs(x*r.x+y*r.y+z*r.z)-depth*tx<=radius*nx
        and math.abs(x*u.x+y*u.y+z*u.z)-depth*ty<=radius*ny
end

hook.Add("PostDrawOpaqueRenderables","LOD_DrawContainerBatches",function(depth,sky,sky3d)
    if depth or sky or sky3d or not state then return end
    local stats=Wall.batchStats;stats.draws,stats.visits=0,0
    local view=render.GetViewSetup and render.GetViewSetup(true)
    local eye,f,r,u,tx,ty,nx,ny=perspective(view)
    render.SetColorModulation(1,1,1);render.SetBlend(1)
    for _,chunk in ipairs(state.chunks) do
        if chunk.mesh then
            stats.visits=stats.visits+1
            if visible(chunk,eye,f,r,u,tx,ty,nx,ny) then
                render.SetMaterial(chunk.material);chunk.mesh:Draw();stats.draws=stats.draws+1
            end
        end
    end
end)
cvars.AddChangeCallback("lod_reduced_effects",function() Wall:ClearBatches() end,"LOD_WallBatchPreference")
hook.Add("PostCleanupMap","LOD_ClearContainerBatches",function() Wall:ClearBatches() end)
hook.Add("ShutDown","LOD_ClearContainerBatches",function() Wall:ClearBatches() end)
