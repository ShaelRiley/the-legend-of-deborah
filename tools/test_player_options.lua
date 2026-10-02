local e=dofile('tools/music_test_fixture.lua');local check=e.check
CLIENT=true;LOD.SoldierMovement={Active=function(_,p) return p.soldier==true end}
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
print('PLAYER_OPTIONS PASS '..e.checks)
