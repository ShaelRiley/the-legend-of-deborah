-- Execute actual entity initialization, collection and native DrawModel paths.
local F=dofile('tools/test_floor_map_props.lua')
local root='gamemodes/legend_of_deborah/entities/entities/'
local noop=function() end
local calls,players,hooks=0,{},{}
LOD.Config.Progression.KeycardTriggerRadius=48
LOD.Config.Progression.Cards={}
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
for i=1,4 do LOD.Config.Progression.Cards[i]={color=Color(80+i*35,130,180),name='Card '..i,letter=tostring(i),symbol='KEY'} end
LOD.RunManager={IsActivePlayer=function() return true end}
LOD.ProgressionDirector={CollectCard=function(_,i,p,e) calls=calls+1;return true end,
 CollectJailKey=function(_,p,e) calls=calls+1;e:Remove();return true end}
sound={Play=noop};player.GetAll=function() return players end
function F.native:EmitSound() end
hook={Add=function(_,id,fn) hooks[id]=fn end,Remove=noop}
render={SuppressEngineLighting=noop}
cam={Start3D2D=noop,End3D2D=noop}
draw={RoundedBox=noop,SimpleText=noop};ErrorNoHalt=noop;TEXT_ALIGN_CENTER=1
local eye=Vector()
EyePos=function() return eye end
for _,class in ipairs({'lod_keycard','lod_jail_key'}) do
 ENT={};include=function(leaf) dofile(root..class..'/'..leaf) end
 dofile(root..class..'/init.lua')
 F.classes[class]=ENT;F.initializers[class]=ENT.Initialize
 dofile(root..class..'/cl_init.lua')
end
local cases=0
for _,z in ipairs({-12286,0,8192}) do
 for _,class in ipairs({'lod_keycard','lod_jail_key','lod_floor_map'}) do
  for i=1,(class=='lod_keycard' and 4 or 1) do
   local e=F.make(class);local anchor=Vector(1200,-1500,z+40)
   e:SetPos(anchor);if e.SetCardIndex then e:SetCardIndex(i) end
   F.initializers[class](e)
   local pickup=e:GetPickupPosition()
   local block=assert(e.LODProgressionPedestal)
   local lo,hi=e:GetModelBounds()
   local worldLo,worldHi=LOD.ProgressionProps:RotatedBounds(lo,hi,e:GetAngles())
   assert(e:GetPos().z+worldLo.z==block:GetPos().z+block:OBBMaxs().z+2,'item clips through block')
   assert(block:GetPos().z+block.lo.z==z,'block floats or clips through floor')
   assert(block.hi.z-block.lo.z<32 and e.solid==SOLID_NONE,'item blocks jumping past its low pedestal')
   assert(e:UpdateTransmitState()==TRANSMIT_ALWAYS and block:UpdateTransmitState()==TRANSMIT_ALWAYS)
   if class=='lod_keycard' then assert(e:GetModel()=='models/props_c17/BriefCase001a.mdl') end
   if class=='lod_jail_key' then assert(e:GetModel()=='models/props_c17/TrapPropeller_Lever.mdl') end
   LOD.ProgressionProps:RefreshBounds(e)
   for _,axis in ipairs({'x','y','z'}) do assert(e.renderLo[axis]<lo[axis] and e.renderHi[axis]>hi[axis],'bounds clip native model') end
   if class~='lod_floor_map' then
    for yaw=0,330,30 do for _,distance in ipairs({4,80,900,12000}) do for _,height in ipairs({-400,0,400}) do
     eye=pickup+Vector(math.cos(math.rad(yaw))*distance,math.sin(math.rad(yaw))*distance,height)
     local n=e.draws or 0;e:Draw();assert(e.draws==n+1,'angle/distance suppressed a native body')
    end end end
    players={{Alive=function() return true end,NearestPoint=function() return pickup end}}
    local n=calls;e.NextPickupCheck=0;e:Think();assert(calls==n+1 and e.removed and block.removed,'pickup changed touch anchor or orphaned pedestal')
   else e:Remove();assert(block.removed) end
   cases=cases+1
  end
 end
end
print('PROGRESSION_STOCK_PROPS_PASS: '..cases..' bodies on negative/zero/positive floors; all four cards, Jail Key and map; native models; 2160 angle/distance/height DrawModel calls; complete bounds; fixed touch anchors; jumpable block-only collision; always-transmitted bodies; owned collection cleanup')
