-- Paired operation-count probe of the real renderer. --baseline records the old
-- source without expecting the new bounds; no native FPS claim.
local baseline=arg and arg[1]=='--baseline'
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
color_white=Color(255,255,255)
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function HSVToColor(h,s,v)
 local c=v*s;local x=c*(1-math.abs((h/60)%2-1));local m=v-c
 local t=({{c,x,0},{x,c,0},{0,c,x},{0,x,c},{x,0,c},{c,0,x}})[math.floor(h/60)%6+1]
 return Color((t[1]+m)*255,(t[2]+m)*255,(t[3]+m)*255)
end
function ColorToHSV(c)
 local r,g,b=c.r/255,c.g/255,c.b/255;local hi,lo=math.max(r,g,b),math.min(r,g,b)
 local d,h=hi-lo,0
 if d>0 then
  if hi==r then h=60*((g-b)/d%6) elseif hi==g then h=60*((b-r)/d+2) else h=60*((r-g)/d+4) end
 end
 return h,hi==0 and 0 or d/hi,hi
end
function IsValid(v) return v and v.valid~=false end
local hooks,callbacks,commands={},{},{}
hook={Add=function(_,id,f) hooks[id]=f end};concommand={Add=function(id,f) commands[id]=f end}
cvars={AddChangeCallback=function(id,f) callbacks[id]=f end}
local enabled=true
function CreateClientConVar() return {GetBool=function() return enabled end} end
local materials,broken=0,false
function Material(path)
 materials=materials+1
 return {IsError=function() return broken and path:find('/crate/',1,true)~=nil end,GetShader=function() return 'VertexLitGeneric' end,
 GetTexture=function() return {IsError=function() return false end,Width=function() return 1024 end,Height=function() return 1024 end} end}
end
LOD={};dofile(root..'sh_rng.lua')
local Wall={models={},world={},seed=947,nextModel=601,retryQueue={}}
LOD.WallVisualsClient=Wall
local writes=0
local function model()
 local m={color=Color(20,30,40),material='stale'}
 function m:SetMaterial(name) self.material=name;writes=writes+1 end
 function m:GetMaterial() return self.material end
 function m:GetMaterials() return {'stock1','stock2','stock3'} end
 function m:SetSubMaterial() end
 function m:SetColor(c) self.color=c end
 function m:GetColor() return self.color end
 function m:SetSkin(s) assert(s==0) end
 return m
end
for i=1,600 do
 Wall.models[i]=model();Wall.world[i]={floor=(i-1)%4,quadrant=math.floor((i-1)/4)%4+1}
end
local nativeIpairs=ipairs
local visits=0
ipairs=function(t)
 if t~=Wall.world then return nativeIpairs(t) end
 return function(a,i) i=i+1;if a[i] then visits=visits+1;return i,a[i] end end,t,0
end
dofile(root..'cl_container_section_recolor.lua')
local tick=assert(hooks.LOD_ReconcileContainerSectionMaterials)
local function settle()
 for _=1,40 do local old=writes;tick();assert(writes-old<=192,'reconcile cap changed') end
 for _,m in nativeIpairs(Wall.models) do assert(m.material~='stale','unreconciled model') end
end
local started=os.clock();settle()
local buildVisits,buildMaterials,buildSeconds=visits,materials,os.clock()-started
visits=0;materials=0;started=os.clock()
for _=1,600 do tick() end
local idleSeconds=os.clock()-started
print(string.format('LOW_END_PALETTE build_world_visits=%d build_material_lookups=%d idle_600_world_visits=%d idle_material_lookups=%d build_lua_seconds=%.6f idle_lua_seconds=%.6f native_fps_measured=false',buildVisits,buildMaterials,visits,materials,buildSeconds,idleSeconds))
-- Fingerprint full visible assignment, identical pre/post (not just a few colors).
local sig=0
for i,m in nativeIpairs(Wall.models) do
 local c=Wall.world[i].sectionColor
 local text=string.format('%s:%.8f,%.8f,%.8f;',m.material,c.r,c.g,c.b)
 for j=1,#text do sig=(sig*31+text:byte(j))%2147483647 end
end
print('LOW_END_PALETTE visible_assignment_fingerprint='..sig)
if baseline then return end
assert(buildVisits<=600,'floor metadata scanned more than once for stable manifest')
assert(buildMaterials<=32,'candidate validation not shared by the 16 sections')
assert(visits==0 and materials==0,'steady-state manifest/material work persists')
-- Same-seed, same-length replacement with DIFFERENT floor membership invalidates.
local old=Wall.world;Wall.world={}
for i=1,600 do Wall.world[i]={floor=(i-1)%2,quadrant=math.floor((i-1)/2)%4+1} end
settle();assert(visits==600,'same-length world replacement did not rescan exactly once')
-- Existing world is normally immutable; count/seed guards also cover tooling.
-- Appending within the SAME floor range must restart model reconciliation too.
Wall.world[601]={floor=1,quadrant=1};Wall.models[601]=model();Wall.nextModel=602
local v=visits;settle();assert(visits-v==601,'same-floor append not invalidated')
Wall.world[601]=nil;Wall.models[601]=nil;Wall.nextModel=601;settle()
Wall.world[601]={floor=3,quadrant=1};Wall.models[601]=model();Wall.nextModel=602
v=visits;settle();assert(visits-v==601,'append not invalidated')
v=visits;Wall.seed=948;settle();assert(visits-v==601,'seed not invalidated')
-- New world of same floor count must still reconcile with reused models.
local replacement={};for i,inst in nativeIpairs(Wall.world) do replacement[i]={floor=inst.floor,quadrant=inst.quadrant%4+1} end
Wall.world=replacement;for _,m in nativeIpairs(Wall.models) do m.material='stale' end
settle()
-- Candidate failure/recovery follows the existing explicit mode restart.
broken=true;callbacks.lod_crate_hull_candidate();settle()
for i,m in nativeIpairs(Wall.models) do assert(Wall.world[i].hullCandidateFallback and m.material:find('/container_sections/',1,true)) end
broken=false;callbacks.lod_crate_hull_candidate();settle()
for _,m in nativeIpairs(Wall.models) do assert(m.material:find('/crate/sections/',1,true)) end
-- Empty cleanup and fresh same-seed world never retain prior floor metadata.
Wall.world={};Wall.models={};Wall.nextModel=1;tick()
Wall.world={{floor=0,quadrant=1}};Wall.models={model()};Wall.nextModel=2;settle()
assert(Wall.models[1].material:find('/crate/sections/',1,true))
ipairs=nativeIpairs
print('LOW_END_PALETTE_PASS: exact visible assignment, stable quiescence, world/count/seed/model/mode lifetimes, finite cap, fallback/recovery')
