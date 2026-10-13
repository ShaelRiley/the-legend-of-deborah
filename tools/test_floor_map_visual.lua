-- Actual native stock rendering and Finder lifecycle; no custom globe assumption.
local F=dofile('tools/test_floor_map_props.lua')
local noop=function() end
local eye=Vector(1100,-800,460)
EyePos=function() return eye end;TEXT_ALIGN_CENTER=1
local hooks,planes,polys,texts={}, {}, {}, {}
hook={Add=function(_,id,fn) hooks[id]=fn end}
local depth,lighting=false,false
render={SuppressEngineLighting=function(v) lighting=v end}
cam={IgnoreZ=function(v) depth=v end,Start3D2D=function(pos,ang,scale) planes[#planes+1]={pos=pos,ang=ang,scale=scale} end,End3D2D=noop}
surface={SetDrawColor=noop,DrawPoly=function(p) polys[#polys+1]=p end}
draw={NoTexture=noop,RoundedBox=noop,SimpleText=function(t) texts[#texts+1]=t end}
ErrorNoHalt=noop
local models={}
ClientsideModel=function(path)
 local e=setmetatable({model=path}, {__index=F.native});models[#models+1]=e
 function e:SetNoDraw(v) self.hidden=v end
 function e:SetupBones() self.bones=true end
 function e:DrawModel() assert(self.hidden and self.bones and lighting and depth);self.draws=(self.draws or 0)+1 end
 return e
end
local root='gamemodes/legend_of_deborah/entities/entities/'
ENT=F.classes.lod_floor_map
include=function(leaf) dofile(root..'lod_floor_map/'..leaf) end
dofile(root..'lod_floor_map/cl_init.lua')
local a,b=F.pickup(F.start),F.pickup(F.start+Vector(0,0,384))
a:Initialize();b:Initialize();b:SetFloorIndex(2)
a:Draw();assert(a.draws==1 and not lighting,'ordinary book is not native geometry or lighting leaked')
a:DrawTranslucent();assert(#planes==2 and #polys==5 and texts[1]=='FLOOR 2 MAP')
local cachedPoly=polys[1]
for _,height in ipairs({-100,33,150}) do for yaw=0,315,45 do
 eye=a:GetPickupPosition()+Vector(math.cos(math.rad(yaw))*100,math.sin(math.rad(yaw))*100,height)
 planes={};polys={};a:DrawTranslucent()
 local p=planes[1];local delta=eye-p.pos;local dir=delta*(1/math.sqrt(delta:LengthSqr()))
 assert(p.ang.f:Cross(p.ang:Right()):Dot(dir)>.99999,'eye hint became edge-on')
 assert(polys[1]==cachedPoly,'eye polygon rebuilt each frame')
 for _,plane in ipairs(planes) do
  local radius=plane.scale==1 and math.sqrt(26^2+12^2) or math.sqrt(145^2+25^2)*.12
  local delta=plane.pos-a:GetPos()
  for _,axis in ipairs({'x','y','z'}) do assert(math.abs(delta[axis])+radius<96,'hint escapes orientation-safe bounds') end
 end
end end
eye=Vector(384*9,0,0);local draws=a.draws;a:Draw();assert(a.draws==draws+1,'custom distance cull still hides native book')
local owner={alive=true,finder=false,nw={}}
function owner:Alive() return self.alive end
function owner:GetNW2Bool(k) return k=='LOD_RPGMapFinder' and self.finder or self.nw[k] or false end
LocalPlayer=function() return owner end
local finder=hooks.LOD_MapFinderPickups
finder(false,false);assert(#models==0)
owner.finder=true;finder(true,false);assert(#models==0,'depth pass drew Finder')
finder(false,false);assert(#models==4 and not depth and not lighting,'Finder must show both props on each floor and restore render state')
for _,model in ipairs(models) do assert(model.draws==1) end
finder(false,false);assert(#models==4 and models[1].draws==2,'Finder recreates native models each frame')
for _,k in ipairs({'LOD_IsSoldier','LOD_Eliminated'}) do owner.nw[k]=true;local n=models[1].draws;finder(false,false);assert(models[1].draws==n);owner.nw[k]=nil end
owner.alive=false;local n=models[1].draws;finder(false,false);assert(models[1].draws==n);owner.alive=true
local original=models[1].DrawModel;models[1].DrawModel=function() error('native draw failure') end
finder(false,false);assert(not depth and not lighting,'Finder left global rendering modified');models[1].DrawModel=original
a:Remove();assert(models[1].removed and models[2].removed and not LOD.FloorMapVisual.pickups[a],'collection retained helper props')
hooks.LOD_FloorMapGlobeCleanup();assert(models[3].removed and models[4].removed)
ENT=F.classes.lod_floor_map_pedestal;include=function(leaf) dofile(root..'lod_floor_map_pedestal/'..leaf) end
dofile(root..'lod_floor_map_pedestal/cl_init.lua')
local pedestal=b.LODFloorMapPedestal;pedestal:Draw();assert(pedestal.draws==1 and not lighting,'solid pedestal is not stock geometry')
print('FLOOR_MAP_VISUAL_PASS: native book and pedestal DrawModel; 24 hint viewpoints; complete all-orientation bounds; no body distance cull; distant other-floor Finder; cached helpers; death/role/depth guards; collection/shutdown; native rendering errors restore lighting/depth')
