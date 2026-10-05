-- Canonical reduced-wall production renderer. Source mesh/native calls doubled;
-- exact transformed vertices/UVs/tints, transactional fallback and lifetime QA.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
function IsValid(e) return e and e.valid~=false end
LOD={Config={Maze={CellSize=384},Geometry={ContainerModel='models/props_wasteland/cargo_container01.mdl',Skin=0}}}
dofile(root..'sh_crate_visuals.lua')
local C=LOD.CrateVisuals
local Wall={world={},models={},seed=10,sectionMaterialsReady=true};LOD.WallVisualsClient=Wall
local hooks,callbacks={},{ }
hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end}
cvars={AddChangeCallback=function(id,fn) callbacks[id]=fn end}
local on=true
GetConVar=function(name) assert(name=='lod_reduced_effects');return {GetBool=function() return on end} end
local clock=10;SysTime=function() clock=clock+.0001;return clock end
local textures={};local function texture(path)
    textures[path]=textures[path] or {IsError=function() return false end,GetName=function() return path end}
    return textures[path]
end
local materials={};local bad=false;local alternate=false
function Material(name)
    return {IsError=function() return bad end,GetTexture=function() return texture(alternate and name=='green' and 'other' or 'hull') end,
        GetVector=function() return name=='red' and Vector(.8,.144,.144) or Vector(.144,.8,.144) end}
end
local creations=0
function CreateMaterial(name,shader,args)
    -- Native CreateMaterial reuses an existing name after Lua refresh.
    if materials[name] then return materials[name] end
    creations=creations+1;assert(shader=='UnlitGeneric' and args['$vertexcolor']=='1')
    materials[name]={IsError=function() return false end,texture=args['$basetexture']};return materials[name]
end
local triangles={}
for i=1,1284 do
    local p=(i%3==0) and C.CargoMins or (i%3==1) and C.CargoMaxs or Vector(C.CargoMins.x,C.CargoMaxs.y,C.CargoMins.z)
    triangles[i]={pos=p,normal=Vector(0,0,1),u=(i%13)/13,v=(i%17)/17,tangent=Vector(1,0,0),binormal=Vector(0,1,0)}
end
local fetches=0
util={GetModelMeshes=function(path,lod,groups,skin)
    assert(path==LOD.Config.Geometry.ContainerModel and lod==0 and groups==0 and skin==0)
    fetches=fetches+1;return {{triangles=triangles}}
end}
local meshes,live,peak,uploads={ },0,0,0
local failUpload=false;local detailed=true
function Mesh(material)
    local m={material=material};meshes[#meshes+1]=m;live=live+1;peak=math.max(peak,live)
    function m:BuildFromTriangles(vertices)
        uploads=uploads+1;assert(#vertices<=60000 and #vertices%3==0)
        if failUpload then error('injected native upload failure') end
        self.count=#vertices
        if detailed then self.vertices=vertices end
    end
    function m:Destroy() assert(not self.dead,'double mesh destruction');self.dead=true;self.vertices=nil;live=live-1 end
    function m:Draw() assert(not self.dead);self.drawn=true end
    return m
end
local view=nil;local boundMaterial
render={GetViewSetup=function(current) assert(current);return view end,
    SetMaterial=function(m) boundMaterial=m end,SetBlend=function(v) assert(v==1) end,
    SetColorModulation=function(r,g,b) assert(r==1 and g==1 and b==1) end}
local function populate(n)
    Wall.world={};Wall.models={};Wall.sectionMaterialsReady=true
    for i=1,n do
        local x,y=(i-1)%21+1,math.floor((i-1)/21)%21+1
        local floor=math.floor((i-1)/441);local yaw=(i%4)*90
        local inst={gridX=x,gridY=y,floor=floor,stackIndex=i%2,
            pos=Vector(1000+x*384,y*384-4000,floor*384+i%2*132),ang={y=yaw},
            sectionMaterialName=i%2==0 and 'red' or 'green',appliedSectionMode='file-backed-global'}
        local m={hidden=false,GetPos=function() return inst.pos end}
        function m:SetNoDraw(hide) self.hidden=hide end
        Wall.world[i]=inst;Wall.models[i]=m
    end
end
local function fire(event,...) for _,fn in pairs(hooks[event] or {}) do fn(...) end end
local function tick()
    local before=uploads;fire('Think');assert(uploads-before<=1,'native upload burst')
end
local function settle()
    for _=1,520 do tick() end
end
local function hidden()
    local n=0;for _,m in pairs(Wall.models) do if m.hidden then n=n+1 end end;return n
end
populate(8);dofile(root..'cl_wall_batch.lua');settle()
assert(Wall.batchStats.status=='ready' and hidden()==8 and fetches==1 and creations==1)
local count=0
-- Independent full native model transform oracle for EVERY source vertex.
for _,m in ipairs(meshes) do if not m.dead then
    for _,row in ipairs(m.vertices) do
        local matched=false
        for _,inst in ipairs(Wall.world) do
            local j=count%1284+1;local v=triangles[j]
            local yaw=math.rad(inst.ang.y);local co,si=math.cos(yaw),math.sin(yaw)
            local x,y,z=v.pos.x*co-v.pos.y*si+inst.pos.x,v.pos.x*si+v.pos.y*co+inst.pos.y,v.pos.z+inst.pos.z
            if math.abs(row.pos.x-x)<1e-7 and math.abs(row.pos.y-y)<1e-7 and math.abs(row.pos.z-z)<1e-7 then
                assert(row.u==v.u and row.v==v.v and row.normal.z==1,'UV/normal drift')
                assert(row.tangent.x==co and row.tangent.y==si,'tangent transform drift')
                assert(row.color.r==(inst.sectionMaterialName=='red' and 204 or 37))
                matched=true;break
            end
        end
        assert(matched,'native hull triangle changed');count=count+1
    end
end end
assert(count==8*1284,'missing/duplicate container triangles')
fire('PostDrawOpaqueRenderables',false,false,false)
assert(Wall.batchStats.draws==Wall.batchStats.chunks,'unknown view must fail open')
-- Chunk culling uses this render pass, never LocalPlayer/EyePos or floor guesses.
local A={};A.__index=A
function Angle(p,y,r) return setmetatable({p=p,y=y,r=r},A) end
function A:Forward() local p,y=math.rad(self.p),math.rad(self.y);return Vector(math.cos(p)*math.cos(y),math.cos(p)*math.sin(y),-math.sin(p)) end
function A:Right() local y=math.rad(self.y);return Vector(math.sin(y),-math.cos(y),0) end
function A:Up() local p,y=math.rad(self.p),math.rad(self.y);return Vector(math.sin(p)*math.cos(y),math.sin(p)*math.sin(y),math.cos(p)) end
view={origin=Vector(),angles=Angle(0,180,0),fov=90,aspect=1.6,znear=1}
fire('PostDrawOpaqueRenderables',false,false,false);assert(Wall.batchStats.draws==0,'wholly rear chunks submitted')
view.angles=Angle(0,0,0)
fire('PostDrawOpaqueRenderables',false,false,false);assert(Wall.batchStats.draws>0)
for _,field in ipairs({'ortho','offcenter'}) do view[field]={};fire('PostDrawOpaqueRenderables',false,false,false)
    assert(Wall.batchStats.draws==Wall.batchStats.chunks);view[field]=nil end
local angles,origin=view.angles,view.origin
view.angles={};fire('PostDrawOpaqueRenderables',false,false,false)
assert(Wall.batchStats.draws==Wall.batchStats.chunks,'unknown view angles did not fail open')
view.angles=angles;view.origin=Vector(0/0,0,0);fire('PostDrawOpaqueRenderables',false,false,false)
assert(Wall.batchStats.draws==Wall.batchStats.chunks,'invalid view vector did not fail open')
view.origin=origin
view.origin=Vector(1800,-3600,0);view.fov=40;view.aspect=.6
fire('PostDrawOpaqueRenderables',false,false,false)
for _,m in ipairs(meshes) do m.drawn=false end
for _,args in ipairs({{true,false,false},{false,true,false},{false,false,true}}) do fire('PostDrawOpaqueRenderables',table.unpack(args)) end
for _,m in ipairs(meshes) do assert(not m.drawn,'excluded pass drew a chunk') end
-- World/candidate invalidation immediately restores native models; replacement
-- must destroy every obsolete IMesh. No generation/reset resources accumulate.
Wall.sectionMaterialsReady=false;tick();assert(live==0 and hidden()==0)
Wall.sectionMaterialsReady=true;settle();assert(hidden()==8)
on=false;callbacks.lod_reduced_effects();assert(live==0 and hidden()==0)
tick();assert(live==0)
on=true;settle();assert(hidden()==8)
fire('PostCleanupMap');assert(live==0 and hidden()==0)
settle();dofile(root..'cl_wall_batch.lua');assert(live==0 and hidden()==0)
settle();fire('ShutDown');assert(live==0 and hidden()==0)
-- A failed native upload or unavailable diffuse keeps the original models.
failUpload=true;settle();assert(hidden()==0 and live==0 and Wall.batchStats.reason:find('injected',1,true))
failUpload=false;callbacks.lod_reduced_effects();settle();assert(hidden()==8)
Wall:ClearBatches();bad=true;settle();assert(hidden()==0 and live==0)
bad=false;Wall:ClearBatches();settle();assert(hidden()==8)
-- Paired loaded draw-submission counts; native GPU time/FPS is unmeasured.
Wall:ClearBatches();meshes={};detailed=false;populate(600);settle()
assert(hidden()==600 and live<=512 and Wall.batchStats.vertices==600*1284)
view=nil;fire('PostDrawOpaqueRenderables',false,false,false)
assert(Wall.batchStats.draws<100,'submissions not batched')
print(string.format('WALL_BATCH_WORK instances=600 legacy_native_submissions=600 batched_submissions=%d exact_triangles=%d native_fps_measured=false',Wall.batchStats.draws,Wall.batchStats.vertices/3))
local built=uploads
for _=1,300 do tick();fire('PostDrawOpaqueRenderables',false,false,false) end
assert(uploads==built,'stable scene rebuilt meshes')
Wall:ClearBatches();assert(live==0 and hidden()==0 and peak<=512)
-- Same count/seed world replacement and model-owner replacement both invalidate.
populate(8);settle();local old=Wall.models;populate(8);tick()
assert(live==0);for _,m in ipairs(old) do assert(not m.hidden) end
settle();local previousModels=Wall.models;Wall.models={}
for i,m in ipairs(previousModels) do Wall.models[i]=m end
tick();assert(live==0 and hidden()==0);settle();Wall:ClearBatches()
-- Resource caps leave excess native geometry visible rather than dropping it.
populate(4000)
for _,inst in ipairs(Wall.world) do inst.gridX=1;inst.gridY=1;inst.floor=0;inst.stackIndex=1 end
tick()
assert(Wall.batchStats.reserved_vertices==math.floor(4000000/1284)*1284,'total vertex cap not exercised')
assert(Wall.batchStats.chunks<=512 and hidden()<4000,'excess geometry did not remain native')
Wall:ClearBatches();assert(live==0 and hidden()==0)
-- Candidate/fallback ordering can change on refresh; global material names
-- must retain their original diffuse texture, with at most two live shaders.
alternate=true;populate(8);dofile(root..'cl_wall_batch.lua');settle()
assert(creations==2 and Wall.batchMaterials.hull.material.texture=='hull')
assert(Wall.batchMaterials.other.material.texture=='other','Lua refresh aliased another diffuse texture')
Wall:ClearBatches();dofile(root..'cl_wall_batch.lua');settle()
assert(creations==2 and hidden()==8,'refresh accumulated shaders or lost hulls')
Wall:ClearBatches()
-- Extraction/bounds failure is conservative and retryable on Lua refresh.
triangles={{pos=Vector(),normal=Vector(0,0,1),u=0,v=0},{pos=Vector(1,0,0),normal=Vector(0,0,1),u=1,v=0},{pos=Vector(0,1,0),normal=Vector(0,0,1),u=0,v=1}}
dofile(root..'cl_wall_batch.lua');settle()
assert(Wall.batchStats.status=='fallback' and Wall.batchStats.reason=='stock-bounds-mismatch' and hidden()==0 and live==0)
print('WALL_BATCH_PASS: exact stock geometry/UV/tint/yaw; conservative view/pass handling; bounded incremental uploads; same-world idle; transactional failures; preference/appearance/owner/map/refresh/shutdown cleanup')
