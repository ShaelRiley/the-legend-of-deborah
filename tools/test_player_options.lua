local e=dofile('tools/movement_test_fixture.lua');local check=e.check
CLIENT=true;LOD.SoldierMovement={Active=function(_,p) return p.soldier==true end}
local declarations={}
local create=CreateClientConVar
CreateClientConVar=function(name,value,save,userinfo,help,low,high)
 declarations[name]={value=value,save=save,userinfo=userinfo,low=low,high=high}
 return create(name,value)
end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_player_options.lua')
local p={setting=0,held=false,mode=MOVETYPE_WALK}
function p:GetInfoNum() return self.setting end
function p:KeyDown() return self.held end
function p:GetMoveType() return self.mode end
function p:GetRunSpeed() return 200 end
function p:GetWalkSpeed() return 100 end
local function move(cap,client,forward,side)
 local m={max=cap,client=client,forward=forward or 0,side=side or 0,up=17,velocity=Vector(9,8,-7)}
 function m:GetMaxSpeed() return self.max end;function m:SetMaxSpeed(v) self.max=v end
 function m:GetMaxClientSpeed() return self.client end;function m:SetMaxClientSpeed(v) self.client=v end
 function m:GetForwardSpeed() return self.forward end;function m:SetForwardSpeed(v) self.forward=v end
 function m:GetSideSpeed() return self.side end;function m:SetSideSpeed(v) self.side=v end
 return m
end
local function near(a,b,label) check(math.abs(a-b)<.000001,label..': '..a..' ~= '..b) end
local function realized(m)
 local n=math.sqrt(m.forward*m.forward+m.side*m.side)
 local cap=m.client>0 and math.min(m.max,m.client) or m.max
 return math.min(n,cap)
end
for _,setting in ipairs({0,1}) do for _,held in ipairs({false,true}) do
 p.setting=setting;p.held=held
 local initial=held and 200 or 100
 local m=move(initial*.33,initial*.33)
 LOD.PlayerOptions:ApplyMove(p,m)
 local sprint=setting==1 and not held or setting==0 and held
 check(LOD.PlayerOptions:WantsSprint(p)==sprint,'logical modifier inversion')
 check(math.abs(m.max-(sprint and 200 or 100)*.33)<.001,'crouch/other native restrictions preserved')
 check(p.held==held,'physical modifier unchanged for Shift+Use')
end end
p.soldier=true;check(not LOD.PlayerOptions:WantsSprint(p),'Soldiers gain no sprint')

-- Reproduce the reported defect with walking-sized movement requests, including
-- analog input. A higher cap alone cannot accelerate a smaller wish velocity.
p.soldier=false;p.setting=1;p.held=false
local reproduction=move(100,100,100,0)
LOD.PlayerOptions:ApplyMove(p,reproduction)
near(realized(reproduction),200,'Always Run must actually run, not only raise its cap')

-- Execute both existing SetupMove paths, not a copied locomotion implementation.
GM={};LOD.RPG={};dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua')
local multiplier=1
LOD.RPGAbilityRules.MovementMultiplier=function() return multiplier end
LOD.SoldierMovement.PrepareMove=function() return false end
LOD.SoldierMovement.Publish=function() end
function p:Alive() return true end
function p:SetNW2Float(_,v) self.multiplier=v end
function p:GetNW2Float(_,default) return self.multiplier or default end
LocalPlayer=function() return p end
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_rpg_movement.lua')
for _,realm in ipairs({'server','client'}) do
 SERVER=realm=='server';CLIENT=not SERVER
 local callback=e.hooks[SERVER and 'LOD_RPG_GateD_Movement' or 'LOD_PredictedVoluntarySpeed']
 for _,setting in ipairs({0,1}) do for _,held in ipairs({false,true}) do
  p.setting=setting;p.held=held
  local initial=held and 200 or 100
  local sprint=setting==1 and not held or setting==0 and held
  local target=sprint and 200 or 100
  for _,restriction in ipairs({.33,1}) do
   for _,boost in ipairs({.5,1,1.55,2}) do
    multiplier=boost;p.multiplier=boost
    for _,axis in ipairs({{0,0},{1,0},{-1,0},{0,1},{0,-1},{.6,.8},{.3,-.4}}) do
     local m=move(initial*restriction,initial*restriction,axis[1]*initial*restriction,axis[2]*initial*restriction)
     callback(p,m)
     near(m.forward,axis[1]*target*restriction*boost,realm..' forward request')
     near(m.side,axis[2]*target*restriction*boost,realm..' lateral request')
     near(realized(m),math.sqrt(axis[1]^2+axis[2]^2)*target*restriction*boost,realm..' realized speed')
     near(m.max,target*restriction*boost,realm..' speed cap')
     near(m.client,m.max,realm..' prediction parity')
     check(p.held==held and m.up==17 and m.velocity.x==9 and m.velocity.y==8 and m.velocity.z==-7,
      'physical modifier, vertical and forced velocity unchanged')
    end
   end
  end
 end end
end

-- Native zero client cap means no additional limit; restrictive positive caps
-- still win. Convert the effective cap once and publish it for engine movement.
p.setting=1;p.held=false
for _,caps in ipairs({{100,0,200},{100,75,150},{75,100,150}}) do
 local m=move(caps[1],caps[2],100,0);LOD.PlayerOptions:ApplyMove(p,m)
 near(m.max,caps[3],'effective cap');near(m.client,caps[3],'explicit native client cap')
end
for _,mode in ipairs({8,9}) do
 p.mode=mode;local m=move(100,100,30,-40);LOD.PlayerOptions:ApplyMove(p,m)
 check(m.max==100 and m.forward==30 and m.side==-40,'non-walking move type untouched')
end
p.mode=MOVETYPE_WALK;p.soldier=true
local soldier=move(100,100,30,-40);LOD.PlayerOptions:ApplyMove(p,soldier)
check(soldier.max==100 and soldier.forward==30 and soldier.side==-40,'Soldier locomotion untouched')
p.soldier=false;p.setting=0
local off=move(100,0,30,-40);LOD.PlayerOptions:ApplyMove(p,off)
check(off.client==0 and off.forward==30 and off.side==-40,'toggling Off restores native movement')

-- New presentation preferences have one saved client authority. Reload and
-- reconnect use existing values; no userinfo/server locomotion setting leaks.
local O=LOD.PlayerOptions
for _,name in ipairs({'lod_third_person','lod_map_scale','lod_map_opacity'}) do
 local d=assert(declarations[name]);check(d.save and not d.userinfo,'presentation preference must be local and archived')
end
check(not O.ThirdPerson:GetBool() and O:MapScaleValue()==1 and O:MapOpacityValue()==1,'existing appearance defaults')
e.set('lod_map_scale',1.25);e.set('lod_map_opacity',.35);e.set('lod_third_person',1)
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_player_options.lua')
check(O.ThirdPerson:GetBool() and O:MapScaleValue()==1.25 and O:MapOpacityValue()==.35,'reload overwrote saved preferences')
for _,v in ipairs({-.1,0,.5,1,1.5,2}) do
 e.set('lod_map_scale',v);e.set('lod_map_opacity',v)
 check(O:MapScaleValue()==math.Clamp(v,.5,1.5) and O:MapOpacityValue()==math.Clamp(v,0,1),'finite presentation bounds')
end
local scaleFloat,opacityFloat=O.MapScale.GetFloat,O.MapOpacity.GetFloat
for _,v in ipairs({math.huge,-math.huge,0/0}) do
 O.MapScale.GetFloat=function() return v end;O.MapOpacity.GetFloat=function() return v end
 check(O:MapScaleValue()==(v~=v and 1 or math.Clamp(v,.5,1.5)) and O:MapOpacityValue()==(v~=v and 1 or math.Clamp(v,0,1)),'nonfinite native preference')
end
O.MapScale.GetFloat=scaleFloat;O.MapOpacity.GetFloat=opacityFloat
e.set('lod_map_scale','nan');e.set('lod_map_opacity','garbage')
check(O:MapScaleValue()==1 and O:MapOpacityValue()==1,'invalid preference must restore usable defaults')

-- Exercise the real gamemode camera entry point through its native base view.
-- Native geometry/traces are boundaries; the camera policy is production code.
LOD.UI={};OBS_MODE_NONE=0;MASK_SOLID=1
local baseCalls,traces,vectors=0,0,0
local nativeVector=Vector
Vector=function(...) vectors=vectors+1;return nativeVector(...) end
local origin=Vector(100,200,300)
local angles={Forward=function() return Vector(1,0,0) end}
local nativeOrigin,nativeFov=origin,65
GM.BaseClass={CalcView=function(self,who,pos,ang,fov,znear,zfar)
 baseCalls=baseCalls+1
 check(self==GM and who==p and pos==origin and ang==angles and fov==70,'native view arguments changed')
 return {origin=nativeOrigin,angles=ang,fov=nativeFov,znear=znear,zfar=zfar}
end}
local obstruction,startSolid,allSolid
util={TraceHull=function(t)
 traces=traces+1
 check(t.start==nativeOrigin and t.filter==p and t.mask==MASK_SOLID,'trace ownership/origin changed')
 check(t.mins.x==-6 and t.maxs.z==6 and t.endpos.x==nativeOrigin.x-118 and t.endpos.z==nativeOrigin.z+34,'existing placement changed')
 return {HitPos=obstruction or t.endpos,StartSolid=startSolid,AllSolid=allSolid}
end}
p.alive=true;p.vehicle=false;p.observer=0;p.viewEntity=p
function p:Alive() return self.alive end
function p:InVehicle() return self.vehicle end
function p:GetObserverMode() return self.observer end
function p:GetViewEntity() return self.viewEntity end
local vr,cinematic=false,false
LOD.VR={IsActive=function() return vr end}
LOD.CampaignTimeout={IsCinematic=function() return cinematic end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_player_options.lua')
local function view() return GM:CalcView(p,origin,angles,70,4,9000) end
e.set('lod_third_person',0);local n=vectors
for _=1,1000 do local v=view();check(v.origin==nativeOrigin and v.fov==65 and not v.drawviewer,'Off changed native view') end
check(traces==0 and vectors==n and baseCalls==1000,'disabled camera creates recurring geometry work')
e.set('lod_third_person',1)
nativeOrigin=Vector(101,202,303);nativeFov=45 -- native weapon zoom and view offset
local v=view()
check(v.origin.x==-17 and v.origin.z==337 and v.angles==angles and v.fov==45 and v.znear==4 and v.zfar==9000 and v.drawviewer,'third-person lost native weapon/clipping data')
obstruction=Vector(90,202,310);v=view();check(v.origin==obstruction and v.drawviewer,'camera ignored obstruction')
startSolid=true;v=view();check(v.origin==nativeOrigin and not v.drawviewer,'inside-solid camera must retain native view')
startSolid=false;allSolid=true;v=view();check(v.origin==nativeOrigin and not v.drawviewer,'all-solid camera must retain native view')
allSolid=false;obstruction=nil
for _,reason in ipairs({'dead','invalid','vehicle','spectator','remote-view','vr','timeout','victory','finale'}) do
 p.alive=reason~='dead';p.valid=reason~='invalid';p.vehicle=reason=='vehicle';p.observer=reason=='spectator' and 1 or 0
 p.viewEntity=reason=='remote-view' and {} or p;vr=reason=='vr';cinematic=reason=='timeout'
 LOD.VictoryCelebrationClient=reason=='finale' and {finale={}} or reason=='victory' and {endsAt=CurTime()+1} or {}
 local before=traces;v=view();check(traces==before and v.origin==nativeOrigin and not v.drawviewer,reason..' view ownership lost')
end
p.alive=true;p.valid=true;p.vehicle=false;p.observer=0;p.viewEntity=p;vr=false;cinematic=false
LOD.VictoryCelebrationClient={endsAt=CurTime()-1}
check(view().drawviewer,'camera failed to resume after cinematic')
e.set('lod_third_person',0);check(not view().drawviewer,'camera toggle failed to restore first person')
print('PLAYER_OPTIONS PASS '..e.checks)
