-- Regression corpus over the real placement solver and both preview endpoints.
local fx=dofile('tools/test_magic_wall.lua')
local F,owner,boxes=fx.F,fx.owner,fx.boxes
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local originalEye,originalAim=owner.GetShootPos,owner.GetAimVector
local function reset()
 for i=#boxes,1,-1 do boxes[i]=nil end
 boxes[1]={lo=Vector(-2000,-2000,-32),hi=Vector(2000,2000,0)}
 owner.GetShootPos=originalEye;owner.GetAimVector=originalAim
end
local ctx={spatialBonusCells=3}
reset()
-- Shallow grazing aim along a crate: back away normal to its face, not along it.
boxes[2]={lo=Vector(-1000,20,0),hi=Vector(1000,150,384)}
owner.GetAimVector=function() return Vector(1,.1,-.1):GetNormalized() end
local p=assert(F:WallPlacement(owner,ctx));assert(p.origin.y+p.maxs.y<20)
-- Fixed 160-unit drop wrongly rejected tall eye positions and rising aims.
reset();owner.GetShootPos=function() return Vector(0,0,200) end
p=assert(F:WallPlacement(owner,ctx));assert(p.origin.z==F.Tuning.Wall.clearance)
owner.GetAimVector=function() return Vector(1,0,.8):GetNormalized() end
assert(F:WallPlacement(owner,ctx))
-- Floor contact clearance and a ceiling lower than the old rigid 112-unit hull.
reset();boxes[2]={lo=Vector(-1000,-1000,96),hi=Vector(1000,1000,128)}
p=assert(F:WallPlacement(owner,ctx));assert(p.maxs.z<96 and p.maxs.z>=48)
-- Width need not stand on a complete physical floor strip; one anchor is enough.
reset();boxes[1]={lo=Vector(-100,-24,-32),hi=Vector(600,24,0)}
p=assert(F:WallPlacement(owner,ctx));assert(p.maxs.y-p.mins.y>100)
-- A held/cosmetic child is not an obstruction, regardless of its engine class.
reset();local child={valid=true,GetOwner=function() return owner end,GetParent=function() return owner end,IsPlayer=function() return false end}
boxes[2]={entity=child,lo=Vector(-5,-5,50),hi=Vector(10,5,75)}
assert(F:WallPlacement(owner,ctx))
-- A near-vertical look remains usable and never produces a zero forward axis.
reset();owner.GetAimVector=function() return Vector(0,0,-1) end
owner.GetForward=function() return Vector(1,0,0) end
assert(F:WallPlacement(owner,ctx))
-- Unsupported positions/solid interiors/remote floors still fail with a reason.
reset();boxes[1]=nil
local bad,why=F:WallPlacement(owner,ctx);assert(not bad and why=='ground')
reset();boxes[2]={lo=Vector(-10,-10,1),hi=Vector(500,10,200)}
bad,why=F:WallPlacement(owner,ctx);assert(not bad and why=='blocked')
reset();boxes[1]={lo=Vector(-2000,-2000,-450),hi=Vector(2000,2000,-418)}
bad,why=F:WallPlacement(owner,ctx);assert(not bad and why=='reach')
reset()
local ordinaryLine=util.TraceLine
util.TraceLine=function(d)
    if d.endpos.z<d.start.z and math.abs(d.endpos.x-d.start.x)<.001 and math.abs(d.endpos.y-d.start.y)<.001 then
        return {Hit=false,Fraction=1,HitPos=d.endpos}
    end
    return ordinaryLine(d)
end
assert(F:WallPlacement(owner,ctx),'Generated-floor feet hull must succeed even when the vertical line probe misses')
util.TraceLine=ordinaryLine
-- Broad deterministic aim corpus: not one hand-picked horizontal test ray.
reset();local successes=0
for _,pitch in ipairs({-80,-60,-30,0,30,60,80}) do
 for yaw=0,330,30 do
  local pitchRad,yawRad=math.rad(pitch),math.rad(yaw)
  owner.GetAimVector=function() return Vector(math.cos(pitchRad)*math.cos(yawRad),math.cos(pitchRad)*math.sin(yawRad),math.sin(pitchRad)) end
  assert(F:WallPlacement(owner,ctx),'Open-floor aim failed at '..pitch..'/'..yaw)
  successes=successes+1
 end
end
reset()
owner.ps.progressionState.classId='wizard';LOD.MagicProgression:GrantForm(owner.ps.progressionState,'wall')
LOD.MagicProgression:SelectForm(owner.ps.progressionState,'wall')
owner.ps.progressionState.selectedMagicContentId=nil;owner.ps.magic=100
LOD.Magic.NextCast[owner]=0;fx.setTime(100)
local hooks,receivers={},{}
hook.Add=function(_,id,fn) hooks[id]=fn end
local writes,sent={},{}
net.Start=function() writes={} end
for _,name in ipairs({'Bool','String','Vector'}) do net['Write'..name]=function(value) writes[#writes+1]=value end end
net.Send=function(ply) sent[#sent+1]={recipient=ply,values=writes} end
net.Receive=function(name,fn) receivers[name]=fn end
player={GetAll=function() return {owner} end}
dofile(root..'sv_wall_preview.lua')
local record=F:WallPreviewState(owner);assert(record.ready and record.shape)
local actual=assert(F:WallPlacement(owner,{spatialBonusCells=F:SpatialBonusCells(owner,owner.ps.progressionState)}))
assert(actual.origin:DistToSqr(record.shape.origin)==0 and actual.maxs:DistToSqr(record.shape.maxs)==0,'Preview is the cast solver geometry')
hooks.LOD_WallPreview();assert(#sent==1 and sent[1].recipient==owner)
fx.setTime(100.05);hooks.LOD_WallPreview();assert(#sent==1,'Rate limited')
fx.setTime(100.2);hooks.LOD_WallPreview();assert(#sent==1,'Unchanged geometry suppressed until heartbeat')
fx.setTime(100.6);hooks.LOD_WallPreview();assert(#sent==2)
owner.ps.magic=0;assert(F:WallPreviewState(owner).reason=='magic');owner.ps.magic=100
LOD.Magic.NextCast[owner]=200;assert(F:WallPreviewState(owner).reason=='cooldown');LOD.Magic.NextCast[owner]=0
owner.active=false;assert(F:WallPreviewState(owner).reason=='staging');owner.active=true
owner.ps.progressionState.selectedMagicFormId='blast';fx.setTime(101);hooks.LOD_WallPreview()
assert(#sent==3 and sent[3].values[1]==false and not F.WallPreviews[owner])
owner.ps.progressionState.selectedMagicFormId='wall';fx.setTime(102);hooks.LOD_WallPreview()
hooks.LOD_WallPreviewCleanup();assert(not next(F.WallPreviews) and sent[#sent].values[1]==false)
-- Client render uses the received bounds and observes local lifecycle immediately.
local clock=100;RealTime=function() return clock end
Material=function() return {} end
LocalPlayer=function() return owner end
LOD.UI={Colors={},HUDText=function() end};LOD.Spellbook={Snapshot={selectedFormId='wall'}}
ScrW=function() return 1280 end;ScrH=function() return 720 end
local rendered=0
render={SetMaterial=function() end,DrawBox=function(origin,_,mins,maxs)
 assert(origin==record.shape.origin and mins==record.shape.mins and maxs==record.shape.maxs);rendered=rendered+1
end,DrawWireframeBox=function() end}
dofile(root..'cl_wall_preview.lua')
local queue,index
local function feed(values)
 queue=values;index=0
 local function read() index=index+1;return queue[index] end
 net.ReadBool=read;net.ReadString=read;net.ReadVector=read
 receivers.LOD_WallPreview()
end
LOD.MagicFX={WallAimActive=function(self) return self.WallAimButton end}
feed({true,true,'ready',true,record.shape.origin,record.shape.mins,record.shape.maxs})
hooks.LOD_WallPlacementGhost(false,false);assert(rendered==0 and not LOD.WallPreview:Current(),'Equipped but idle Wall has no guide')
LOD.MagicFX.WallAimButton=2
hooks.LOD_WallPlacementGhost(false,false);assert(rendered==1)
LOD.MagicFX.WallAimButton=nil;hooks.LOD_WallPlacementGhost(false,false);assert(rendered==1,'Release hides even a still-fresh server preview')
LOD.MagicFX.WallAimButton=2
hooks.LOD_WallPlacementGhost(true,false);assert(rendered==1)
LOD.UI.ActivePage='book';hooks.LOD_WallPlacementGhost(false,false);assert(rendered==1);LOD.UI.ActivePage=nil
owner.hp=0;assert(not LOD.WallPreview:Current());owner.hp=100
LOD.Spellbook.Snapshot.selectedFormId='beam';assert(not LOD.WallPreview:Current());LOD.Spellbook.Snapshot.selectedFormId='wall'
clock=101;assert(not LOD.WallPreview:Current() and not LOD.WallPreview.Record,'Stale packets never leave a ghost')
feed({true,false,'ground',false});assert(LOD.WallPreview:Current().reason=='ground')
feed({false});assert(not LOD.WallPreview.Record)
print('WALL_PLACEMENT_PREVIEW_PASS: '..successes..' aim angles, grazing cover, high eye, low ceiling, ledge, own cosmetics, vertical aim, real rejection reasons, identical server preview/cast bounds, private rate-limited packets and client lifecycle')
