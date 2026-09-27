-- Actual predicted input and HUD handlers. No render or networking implementation
-- is substituted: engine drawing and transport are the observable boundaries.
local noop=function() end
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,'SPOT16_CLIENT: '..msg) end
IsValid=function(v) return type(v)=='table' and v.valid==true end
Color=function(...) return {...} end;Material=function() return {} end
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
IN_ATTACK=1;IN_ATTACK2=2;IN_RELOAD=4
local clock=100;CurTime=function() return clock end
local events={};hook={Add=function(event,id,fn) events[event]=events[event] or {};events[event][id]=fn end}
local packets,packet={},nil
net={Start=function(id) packet={id=id} end,WriteString=function(s) packet.context=s end,
 SendToServer=function() packets[#packets+1]=packet end}
local p={valid=true,alive=true,nw={LOD_IsSoldier=true,LOD_Deployed=true,LOD_TeamMenuContext='1:1:1:soldier'}}
local weapon={valid=true,GetClass=function() return 'weapon_ar2' end}
function p:Alive() return self.alive end
function p:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then return d end;return v end
function p:GetNW2String(k,d) return self.nw[k] or d end
function p:GetActiveWeapon() return weapon end
LocalPlayer=function() return p end
local width,height=1280,800;ScrW=function() return width end;ScrH=function() return height end
local text={};LOD={UI={HUDColor={},HUDText=function(_,s,_,x,y) text[#text+1]={s,x,y} end,IsMinigameLocked=function(self) return self.locked end}}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_player_weapon_specials.lua')
local function command(mask)
 local c={mask=mask,KeyDown=function(self,k) return (self.mask & k)~=0 end,
  RemoveKey=function(self,k) self.mask=self.mask & (~k) end}
 events.CreateMove.LOD_PlayerWeaponSpecials_PredictedInput(c);return c
end
command(0);local c=command(IN_ATTACK|IN_RELOAD|IN_ATTACK2)
check(#packets==1 and packets[1].context==p.nw.LOD_TeamMenuContext,'fresh press sends existing contextual channel')
check(c.mask==IN_ATTACK2,'stock primary and reload suppressed; secondary left for Magic observer')
for i=1,8 do clock=clock+1;command(IN_ATTACK|IN_RELOAD) end
check(#packets==1,'holding never sends repeat activation')
c=command(IN_RELOAD);check(c.mask==0,'Soldier reload always suppressed outside burst')
command(IN_ATTACK);check(#packets==2,'release/repress emits one new request')
p.nw.LOD_TeamMenuContext='1:1:2:soldier';command(IN_ATTACK)
check(#packets==2,'holding across replacement life cannot auto-fire')
command(0);command(IN_ATTACK);check(#packets==3 and packets[3].context=='1:1:2:soldier','fresh press binds replacement context')
for _,size in ipairs({{640,360},{1280,800},{1920,1080}}) do
 width,height=size[1],size[2];text={}
 check(events.HUDShouldDraw.LOD_SoldierRifleAmmo('CHudAmmo')==false,'hide Soldier finite primary ammo')
 check(events.HUDShouldDraw.LOD_SoldierRifleAmmo('CHudBattery')==nil,'Magic HUD unaffected')
 events.HUDPaint.LOD_SoldierRifleAmmo()
 check(#text==2 and text[1][1]=='AMMO' and text[2][1]=='INFINITE','explicit infinite role readout')
 for _,t in ipairs(text) do check(t[2]>=0 and t[2]<width and t[3]>=0 and t[3]<height,'scaled readout anchors inside viewport') end
end
for _,mode in ipairs({'dead','staged','undeployed','hero','menu','minigame','otherweapon'}) do
 p.alive=true;p.nw.LOD_IsSoldier=true;p.nw.LOD_Staged=false;p.nw.LOD_Deployed=true
 LOD.UI.ActivePage=nil;LOD.UI.locked=false;weapon.valid=true
 if mode=='dead' then p.alive=false elseif mode=='staged' then p.nw.LOD_Staged=true
 elseif mode=='undeployed' then p.nw.LOD_Deployed=false elseif mode=='hero' then p.nw.LOD_IsSoldier=false
 elseif mode=='menu' then LOD.UI.ActivePage='character' elseif mode=='minigame' then LOD.UI.locked=true
 else weapon.valid=false end
 text={};events.HUDPaint.LOD_SoldierRifleAmmo();check(#text==0,mode..' hides infinite readout')
end
p.alive=true;weapon.valid=true;p.nw.LOD_IsSoldier=false;p.nw.LOD_Deployed=true;LOD.UI.locked=false
check(events.HUDShouldDraw.LOD_SoldierRifleAmmo('CHudAmmo')==nil,'Hero native ammo not suppressed')
packets={};command(0);command(IN_ATTACK);check(#packets==1 and packets[1].context==nil,'Hero zero-payload activation remains unchanged')
clock=clock+2;c=command(IN_RELOAD);check(c.mask==IN_RELOAD,'Hero reload restored after ordinary input block')
print('SPOT16_CLIENT_PASS '..checks..' actual-production assertions; native layout/prediction pending')
