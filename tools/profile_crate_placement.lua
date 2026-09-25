-- Finite CPU-only gate: real generator -> wall manifest -> client cache -> placement.
-- Optional args: baseline receipt to compare, output receipt, "profile" for sampling, optional branding Lua source.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function Angle(p,y,r) return {p=p,y=y,r=r} end
vector_origin=Vector();angle_zero=Angle(0,0,0)
function IsValid(v) return type(v)=='table' and v.valid~=false end
function CurTime() return 100 end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local hooks={};hook={Add=function(_,id,f) hooks[id]=f end,Remove=noop}
concommand={Add=noop};surface={CreateFont=noop};net={Receive=noop}
ClientsideModel=function() return nil end -- native model creation excluded from timing
ErrorNoHalt=error
local loads,creates=0,0
function Material() loads=loads+1;return {IsError=function() return false end,GetTexture=function() return {IsError=function() return false end} end} end
function CreateMaterial() creates=creates+1;return {SetTexture=noop,Recompute=noop,IsError=function() return false end,GetShader=function() return 'UnlitGeneric' end} end
LOD={}
for _,name in ipairs({'sh_config','sh_rng','sh_crate_visuals','sh_crate_brand_metadata','sv_maze_generator','sv_maze_builder_static_walls','cl_wall_visuals','cl_container_branding'}) do dofile(name=='cl_container_branding' and arg[4] or root..name..'.lua') end
local G,B,W,C=LOD.MazeGenerator,LOD.MazeBuilder,LOD.WallVisualsClient,LOD.CrateVisuals
B._BuildMergedWallCollision=noop -- collision allocation is outside the measured client path
LOD.WallVisuals={SetSegments=function(_,g,segments) W.logical=segments;return true end}
local receipts={}
local function receipt()
 local selected,edges,ends={},{},{}
 for i,v in ipairs(W.world) do if v.companyBranded then
  selected[#selected+1]=i
  assert(v.brandSurfaceEligible and not v.marked)
  assert(not edges[v.overlayEdgeKey]);edges[v.overlayEdgeKey]=true
  local prefix=tostring(v.stackIndex)..':'..v.overlayOrientation..':'
  for _,e in ipairs({v.overlayEndpointA,v.overlayEndpointB}) do assert(not ends[prefix..e]);ends[prefix..e]=true end
 end end
 local s=LOD.CrateBranding.Summary()
 assert(#selected==s.branded and #selected<=math.floor(#W.world*.4))
 assert(s.maxDraws==64 and s.shaderSlots<=2 and C.SafeWidth==240 and C.SafeHeight==78)
 return table.concat({s.brandID,s.company,s.containers,s.branded,s.cap,s.geometryBlocked,s.coverage,s.observations,table.concat(selected,',')},'|')
end
local function run(label,seed,dense)
 -- Dense stress keeps generator/topology logic; raises only fixture occupancy.
 local mc=LOD.Config.Maze
 if dense then mc.RareFourthLayerChance=1;mc.LayerOccupancy={{.8,.8},{.55,.55},{.35,.35},{.1,.1}} end
 local g=assert(G:Generate(seed));B.BuildFailures=0;B:_BuildWalls(g);assert(B.BuildFailures==0)
 W.seed=seed;W.origin=Vector();W.dirty=true;hooks.LOD_BuildProceduralContainerWalls()
 -- Fixed wayfinding reservation mask, identical before/after; not native projection.
 for i,v in ipairs(W.world) do v.marked=i%17==0 end
 local floors={};for _,v in ipairs(W.world) do floors[v.floor]=true end
 local times={};local expected
 for trial=1,4 do
  W.markRevision=trial;collectgarbage('collect')
  local start=os.clock();hooks.LOD_RebuildSparseContainerBrandPlacement();local ms=(os.clock()-start)*1000
  local r=receipt();expected=expected or r;assert(r==expected,'rebuild changed output')
  if trial>1 then times[#times+1]=ms end
 end
 table.sort(times);receipts[#receipts+1]=label..'|'..expected
 local start=os.clock();for i=1,1000 do hooks.LOD_RebuildSparseContainerBrandPlacement() end
 local cached=(os.clock()-start)*1000/1000
 print(string.format('%s seed=%d containers=%d layers=%d median_ms=%.3f min_ms=%.3f max_ms=%.3f cached_ms=%.6f',label,seed,#W.world,table.Count(floors),times[2],times[1],times[3],cached))
 if arg[3]=='profile' then
  local samples={}
  debug.sethook(function()
   local info=debug.getinfo(2,'nS');local k=(info.short_src or '')..':'..(info.name or '?')
   samples[k]=(samples[k] or 0)+1
  end,'',1000)
  W.markRevision=99;hooks.LOD_RebuildSparseContainerBrandPlacement();debug.sethook()
  local rows={};for k,n in pairs(samples) do rows[#rows+1]={k,n} end;table.sort(rows,function(a,b) return a[2]>b[2] end)
  for i=1,math.min(6,#rows) do print('sample '..label..' '..rows[i][1]..' '..rows[i][2]) end
 end
end
run('representative',7719,false)
run('dense',15438,true)
run('dense-successor',23157,true)
local result=table.concat(receipts,'\n')..'\n'
if arg[1] and arg[1]~='-' then local f=assert(io.open(arg[1]));local old=f:read('*a');f:close();assert(old==result,'exact placement/identity/coverage receipt differs') end
if arg[2] then local f=assert(io.open(arg[2],'w'));f:write(result);f:close() end
assert(creates==1 and loads==3,'placement changed lazy material/resource behavior')
print('PLACEMENT_GATE_PASS: exact repeated indices, identity, coverage, separation, 40% cap, 64 draws, lazy resources; CPU timings are not native FPS')
