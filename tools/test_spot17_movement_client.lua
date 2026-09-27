-- Actual shared projection + existing predicted movement/input callbacks.
-- Native CMoveData/CUserCmd/entity/time/network methods are observable boundaries.
SERVER=false;CLIENT=true
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,'SPOT17_CLIENT: '..msg) end
local function near(a,b,msg) check(math.abs(a-b)<.00001,msg) end
local noop=function() end
IN_ATTACK=1;IN_ATTACK2=2;IN_RELOAD=4;IN_SPEED=8;IN_JUMP=16
IN_FORWARD=32;IN_BACK=64;IN_MOVELEFT=128;IN_MOVERIGHT=256;IN_DUCK=512
OBS_MODE_NONE=0;KEY_H=35
bit={band=function(a,b) return a&b end,bnot=function(a) return ~a end}
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
Vector=function(x,y,z) return {x=x or 0,y=y or 0,z=z or 0} end
Color=function(...) return {...} end;Material=function() return {} end
IsValid=function(v) return type(v)=='table' and v.valid==true end
local clock=100;CurTime=function() return clock end;RealTime=CurTime
local events={};hook={Add=function(event,id,fn) events[id]=fn end}
concommand={Add=noop};vgui={GetKeyboardFocus=function() return nil end}
net={Start=noop,SendToServer=noop,WriteString=noop}
LOD={Config={Encounter={Archetypes={soldier={speed=140}}}}}
local weapon={valid=true,GetClass=function() return 'weapon_ar2' end}
local p={valid=true,alive=true,ground=true,observer=0,nw={}}
function p:IsPlayer() return true end;function p:Alive() return self.alive end
function p:OnGround() return self.ground end;function p:GetObserverMode() return self.observer end
function p:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then return d end;return v end
function p:GetNW2Float(k,d) return self.nw[k] or d end
function p:GetNW2String(k,d) return self.nw[k] or d end
function p:GetNW2Entity(k) return self.nw[k] end
function p:GetActiveWeapon() return self.weapon end
LocalPlayer=function() return p end
local function reset()
 p.valid=true;p.alive=true;p.ground=true;p.observer=0;p.weapon=weapon;weapon.valid=true
 p.nw={LOD_IsSoldier=true,LOD_Deployed=true,LOD_TeamMenuContext='1:1:3:soldier',LOD_VoluntaryMovementMultiplier=1}
end
reset()
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_soldier_movement.lua');dofile(root..'cl_haste.lua');dofile(root..'cl_player_weapon_specials.lua')
local M=LOD.SoldierMovement
local function move(mask,cap,velocity)
 local m={mask=mask or 0,max=cap or 400,client=cap or 400,forward=450,side=450,up=150,velocity=velocity or Vector(250,180,-60)}
 function m:GetForwardSpeed() return self.forward end;function m:SetForwardSpeed(v) self.forward=v end
 function m:GetSideSpeed() return self.side end;function m:SetSideSpeed(v) self.side=v end
 function m:GetUpSpeed() return self.up end;function m:SetUpSpeed(v) self.up=v end
 function m:GetMaxSpeed() return self.max end;function m:SetMaxSpeed(v) self.max=v end
 function m:GetMaxClientSpeed() return self.client end;function m:SetMaxClientSpeed(v) self.client=v end
 function m:GetVelocity() return self.velocity end;function m:SetVelocity(v) self.velocity=v end
 function m:GetButtons() return self.mask end;function m:SetButtons(v) self.mask=v end
 function m:KeyDown(k) return (self.mask & k)~=0 end
 function m:RemoveKey(k) self.mask=self.mask & (~k) end
 function m:ClearMovement() self.forward=0;self.side=0;self.up=0 end
 return m
end
local function rootPacket()
 p.nw.LOD_SoldierRootUntil=clock+.88;p.nw.LOD_SoldierRootContext=p.nw.LOD_TeamMenuContext
 p.nw.LOD_SoldierRootWeapon=weapon
end
for _,multiplier in ipairs({.45,1,1.11,1.55,2,3.1}) do
 for _,ground in ipairs({true,false}) do
  for _,mask in ipairs({IN_SPEED,IN_JUMP,IN_SPEED|IN_JUMP|IN_DUCK}) do
   reset();p.ground=ground;p.nw.LOD_VoluntaryMovementMultiplier=multiplier
   local m=move(mask);events.LOD_PredictedVoluntarySpeed(p,m)
   near(m.max,140*multiplier,'replicated multiplier applied once to AI base')
   near(m.client,m.max,'prediction caps agree')
   check(not m:KeyDown(IN_SPEED),'no predicted sprint')
   check(m:KeyDown(IN_JUMP)==(not ground and (mask&IN_JUMP)~=0),'ground-only ordinary jump suppression')
   near(m.velocity.x,250,'uncommitted velocity not rewritten')
   local cmd=move(mask);events.LOD_PlayerWeaponSpecials_PredictedInput(cmd)
   check(not cmd:KeyDown(IN_SPEED),'actual CreateMove filters ordinary sprint')
   check(cmd:KeyDown(IN_JUMP)==(not ground and (mask&IN_JUMP)~=0),'actual CreateMove preserves airborne feat input')
  end
 end
end
reset();local crouch=move(IN_DUCK,40);events.LOD_PredictedVoluntarySpeed(p,crouch)
near(crouch.max,40,'native crouch reduction cannot be raised by Soldier base')
for _,ground in ipairs({true,false}) do
 reset();p.ground=ground;rootPacket()
 check(M:Locked(p),'matching server deadline/context/native weapon projects root')
 local mask=IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_SPEED|IN_JUMP|IN_DUCK
 local m=move(mask);events.LOD_PredictedVoluntarySpeed(p,m)
 check(m.mask==IN_DUCK,'root filters movement buttons only')
 near(m.forward,0,'root forward');near(m.side,0,'root side');near(m.up,0,'root up')
 near(m.max,0,'root max');near(m.velocity.x,0,'root carried x');near(m.velocity.y,0,'root carried y')
 near(m.velocity.z,-60,'ordinary vertical fall preserved')
 local cmd=move(mask|IN_ATTACK2);events.LOD_PlayerWeaponSpecials_PredictedInput(cmd)
 check(cmd.mask==(IN_DUCK|IN_ATTACK2),'existing secondary-Magic observation and crouch retained')
 near(cmd.forward,0,'actual input clears movement')
 p.nw.LOD_SoldierForcedUntil=clock+.1
 m=move(mask);events.LOD_PredictedVoluntarySpeed(p,m)
 near(m.velocity.x,250,'marked forced x retained');near(m.velocity.y,180,'marked forced y retained')
 near(m.velocity.z,-60,'marked forced z retained');near(m.forward,0,'forced motion never restores voluntary input')
 clock=clock+.1;m=move(mask);events.LOD_PredictedVoluntarySpeed(p,m)
 near(m.velocity.x,0,'expired forced projection cannot escape root')
 clock=p.nw.LOD_SoldierRootUntil
 check(not M:Locked(p),'deadline expires with no new server packet')
 m=move();events.LOD_PredictedVoluntarySpeed(p,m);check(m.max>0 and m.forward>0,'movement restored at deadline')
end
local changes={
 hero=function() p.nw.LOD_IsSoldier=false end,life=function() p.nw.LOD_TeamMenuContext='1:1:4:soldier' end,
 campaign=function() p.nw.LOD_TeamMenuContext='2:1:3:soldier' end,missingContext=function() p.nw.LOD_TeamMenuContext='' end,
 wrongContext=function() p.nw.LOD_SoldierRootContext='old' end,
 replacedWeapon=function() p.weapon={valid=true,GetClass=weapon.GetClass} end,
 otherWeapon=function() p.weapon={valid=true,GetClass=function() return 'weapon_smg1' end} end,
 removedWeapon=function() weapon.valid=false end,dead=function() p.alive=false end,
 staged=function() p.nw.LOD_Staged=true end,undeployed=function() p.nw.LOD_Deployed=false end,
 waiting=function() p.nw.LOD_SoldierWaiting=true end,observer=function() p.observer=1 end,
 missingDeadline=function() p.nw.LOD_SoldierRootUntil=nil end,
}
for name,change in pairs(changes) do
 reset();rootPacket();change()
 check(not M:Locked(p),name..' rejects stale projection')
 local m=move(IN_SPEED|IN_JUMP);events.LOD_PredictedVoluntarySpeed(p,m)
 near(m.velocity.x,250,name..' cannot carry a stale velocity root')
end
reset();p.nw.LOD_IsSoldier=false;rootPacket();p.nw.LOD_VoluntaryMovementMultiplier=1.11
local hero=move(IN_SPEED|IN_JUMP,400);events.LOD_PredictedVoluntarySpeed(p,hero)
near(hero.max,444,'ordinary Hero movement pipeline untouched')
check(hero.mask==(IN_SPEED|IN_JUMP),'Hero sprint and jump untouched')
near(hero.velocity.x,250,'Hero velocity not rooted by old packet')
local remote=move();local other={};events.LOD_PredictedVoluntarySpeed(other,remote)
near(remote.max,400,'local prediction does not move another actor')
print('SPOT17_CLIENT_PASS '..checks..' new actual-production assertions; native prediction pending')
