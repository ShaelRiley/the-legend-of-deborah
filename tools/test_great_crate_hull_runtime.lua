-- Executes the production section authority; only Source boundaries are doubled.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
color_white=Color(255,255,255)
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function HSVToColor(h,s,v)
 local c=v*s;local x=c*(1-math.abs((h/60)%2-1));local m=v-c
 local values={{c,x,0},{x,c,0},{0,c,x},{0,x,c},{x,0,c},{c,0,x}}
 local t=values[math.floor(h/60)%6+1]
 return Color((t[1]+m)*255,(t[2]+m)*255,(t[3]+m)*255)
end
function ColorToHSV(c)
 local r,g,b=c.r/255,c.g/255,c.b/255
 local hi,lo=math.max(r,g,b),math.min(r,g,b);local d=hi-lo;local h=0
 if d>0 then
  if hi==r then h=60*((g-b)/d%6) elseif hi==g then h=60*((b-r)/d+2) else h=60*((r-g)/d+4) end
 end
 return h,hi==0 and 0 or d/hi,hi
end
function IsValid(v) return v and v.valid~=false end
local hooks,callbacks={},{}
hook={Add=function(_,id,f) hooks[id]=f end}
concommand={Add=noop}
cvars={AddChangeCallback=function(id,f) callbacks[id]=f end}
local enabled=true
function CreateClientConVar(id,default,archive,userinfo)
 assert(id=='lod_crate_hull_candidate' and default=='1' and not archive and not userinfo)
 return {GetBool=function() return enabled end}
end
local broken=nil
function Material(path)
 local candidate=path:find('/crate/',1,true)
 return {IsError=function() return candidate and broken=='material' end,
 GetShader=function() return candidate and broken=='shader' and 'UnlitGeneric' or 'VertexLitGeneric' end,
 GetTexture=function()
  if candidate and broken=='missing' then return nil end
  return {IsError=function() return candidate and broken=='texture' end,
   Width=function() return candidate and broken=='size' and 16 or 1024 end,Height=function() return 1024 end}
 end}
end
LOD={};dofile(root..'sh_rng.lua')
local Wall={models={},world={},seed=947,nextModel=601,retryQueue={}}
LOD.WallVisualsClient=Wall
local writes=0
for i=1,600 do
 local m={color=Color(20,30,40),material='stale',sub=true}
 function m:SetMaterial(name) self.material=name;writes=writes+1 end
 function m:GetMaterial() return self.material end
 function m:GetMaterials() return {'cargo_container01','cargo_container02','cargo_container03'} end
 function m:SetSubMaterial() self.sub=false end
 function m:SetColor(c) self.color=c end
 function m:GetColor() return self.color end
 function m:SetSkin(s) assert(s==0) end
 Wall.models[i]=m;Wall.world[i]={floor=(i-1)%4,quadrant=math.floor((i-1)/4)%4+1}
end
dofile(root..'cl_container_section_recolor.lua')
local tick=hooks.LOD_ReconcileContainerSectionMaterials
local function settle()
 for _=1,30 do local old=writes;tick();assert(writes-old<=192,'batch ceiling exceeded') end
 local old=writes;tick();assert(writes==old,'idle material churn')
end
local function set(value) enabled=value;callbacks.lod_crate_hull_candidate() end
settle()
for _,m in ipairs(Wall.models) do assert(m.material:find('/crate/sections/c2_',1,true),'repaired default missing') end
set(false);settle()
local baseline={}
for i,m in ipairs(Wall.models) do
 assert(m.material:find('/container_sections/v19_',1,true) and not m.sub and m.color.r==255)
 baseline[i]={material=m.material,color=Wall.world[i].sectionColor}
end
set(true);settle()
for i,m in ipairs(Wall.models) do
 assert(m.material:find('/crate/sections/c2_',1,true))
 local a,b=baseline[i].color,Wall.world[i].sectionColor
 assert(a.r==b.r and a.g==b.g and a.b==b.b,'palette changed with candidate')
end
set(false);settle()
for i,m in ipairs(Wall.models) do assert(m.material==baseline[i].material) end
for _,fault in ipairs({'material','shader','missing','texture','size'}) do
 broken=fault;set(true);settle()
 for i,m in ipairs(Wall.models) do assert(m.material==baseline[i].material and Wall.world[i].hullCandidateFallback) end
end
broken=nil;set(true);settle()
assert(Wall.models[1].material:find('/crate/sections/c2_',1,true))
-- A replacement client-model table is reconciled even after the previous pass is idle.
local replacement={};for i,m in ipairs(Wall.models) do replacement[i]=m;m.material='stale' end
Wall.models=replacement;settle();assert(replacement[1].material:find('/crate/sections/c2_',1,true))
print('CRATE_HULL_RUNTIME_PASS: repaired default on, legacy recovery; 600 models; unchanged palette; <=192 writes/batch; on/off; 5 material/sampler failures fall back; recovery and replacement-model reconciliation; idle quiescence')
