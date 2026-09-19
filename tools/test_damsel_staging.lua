local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local V=getmetatable(Vector());function V:Dot(v) return self.x*v.x+self.y*v.y+self.z*v.z end
function V:Angle() return {y=math.deg(math.atan(self.y,self.x))} end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,
    Forward=function() return Vector(1,0,0) end,Right=function() return Vector(0,1,0) end} end
local D,R=LOD.Damsels,LOD.RunManager
if not D then dofile(root..'sh_damsels.lua');D=LOD.Damsels end
R.State={CampaignSeed=72,CampaignEpoch=1,Level=1,BuildReady=true,RescuedDamsels={},DamselClaims={}}
local states={};R.GetPlayerState=function(_,p) return states[p] end
R.IsSlotActivePlayer=function() return true end;R.IsSoldierControl=function() return false end
R.NewCampaign=function(self)
 self.State={CampaignSeed=84,CampaignEpoch=2,Level=1,BuildReady=true,RescuedDamsels={},DamselClaims={}}
 return true
end
LOD.Equipment={};LOD.CryptoDirector={};LOD.CryptoStore={}
local S={HutCenter=Vector(),HutAngles=Angle(),HutHalfForward=448,HutHalfRight=288,HutEntities={},
 EnsureHut=function() return true end,IsPlayerInHut=function() return true end}
LOD.StagingDeployment=S
for _,p in ipairs({Vector(82,0,0),Vector(-82,0,0),Vector(-408,-160,0),Vector(350,0,96),Vector(0,254,50),Vector(100,254,50)}) do
 S.HutEntities[#S.HutEntities+1]={GetPos=function() return p end}
end
local born,removed=0,0
ents.Create=function(class)
 assert(class=='lod_rescued_damsel');born=born+1
 return {SetPos=function(self,p) self.pos=p end,GetPos=function(self) return self.pos end,
 WorldSpaceCenter=function(self) return self.pos+Vector(0,0,36) end,
 SetAngles=function(self,a) self.ang=a end,Spawn=noop,Activate=noop,
 Remove=function(self) assert(self.valid~=false);removed=removed+1;self.valid=false end}
end
util.TraceHull=function(t)
 local p=t.start
 return {Hit=math.abs(p.x)+14>=S.HutHalfForward or math.abs(p.y)+14>=S.HutHalfRight}
end
util.TraceLine=function() return {Hit=false} end
local packets,packet={},nil
net.Start=function(name) packet={name=name,values={}} end
local function write(v) packet.values[#packet.values+1]=v end
net.WriteUInt=write;net.WriteDouble=write;net.WriteBool=write;net.WriteString=write
net.Send=function(p) packet.player=p;packets[#packets+1]=packet end
function ErrorNoHalt(s) error(s) end
dofile(root..'sv_damsels.lua')
local positions={}
assert(S:EnsureHut() and born==0)
for level=1,20 do
 R.State.RescuedDamsels[level]=true;R.State.Level=level+1
 assert(S:EnsureHut());assert(S:EnsureHut())
 assert(born==level and removed==0,'ordinary transition duplicates or removes staged actor')
 for i=1,level do
    local ent=D.Entities[i];assert(IsValid(ent))
    local p=ent:GetPos()
    if positions[i] then assert(p==positions[i],'stable placement changed') else positions[i]=p end
    for j=1,i-1 do assert(p:DistToSqr(positions[j])>=48^2,'actors overlap') end
    for _,prop in ipairs(S.HutEntities) do
        local q=prop:GetPos();assert((p.x-q.x)^2+(p.y-q.y)^2>=48^2,'staging interaction obstructed')
    end
 end
end
R.State.Abundance=true
local late={};states[late]={identity='late'}
D:Sync(late);assert(#packets==2 and packets[1].name=='LOD_DamselState' and packets[2].name=='LOD_DamselDialogue')
assert(packets[1].values[2]==21)
for i=4,23 do assert(packets[1].values[i]==true,'late join omitted rescued damsel') end
D:Sync(late);assert(#packets==3,'letter repeats on ordinary sync')
local hero={IsPlayer=function() return true end,Alive=function() return true end,
 GetPos=function() return D.Entities[1]:GetPos() end,EyePos=function() return D.Entities[1]:WorldSpaceCenter()-Vector(40,0,0) end,
 GetAimVector=function() return Vector(1,0,0) end}
states[hero]={identity='hero',lives=2}
assert(D:CanUse(hero,D.Entities[1]))
local claimed=0;D.Grant=function() claimed=claimed+1;return true,'done' end
IN_USE=32
hero.GetEyeTrace=function() return {Entity=S.HutEntities[1],HitPos=hero:EyePos()+Vector(40,0,0)} end
env.hooks.LOD_DamselUse(hero,IN_USE);assert(claimed==0,'talk intercepted another staging interaction')
hero.GetEyeTrace=nil
env.hooks.LOD_DamselUse(hero,IN_USE);assert(claimed==1,'E did not interact')
env.hooks.LOD_DamselUse(hero,IN_USE);assert(claimed==1,'repeated E duplicated reward')
local old=D.Entities[1]
assert(R:NewCampaign());assert(removed==20 and next(D.Entities)==nil and not D:CanUse(hero,old))
assert(S:EnsureHut() and born==20,'new campaign respawned old roster')
-- The native room discovery can report smaller enclosed rooms. Exercise a
-- 400 x 260 floor with six existing interaction/decor points, not only an arena.
S.HutHalfForward=200;S.HutHalfRight=130;S.HutEntities={}
for _,p in ipairs({Vector(82,0,0),Vector(-82,0,0),Vector(-160,-90,0),Vector(152,0,96),Vector(0,116,50),Vector(88,116,50)}) do
 S.HutEntities[#S.HutEntities+1]={GetPos=function() return p end}
end
for i=1,20 do R.State.RescuedDamsels[i]=true end
assert(S:EnsureHut() and born==40)
assert(S:EnsureHut() and born==40)
for i=1,20 do
 local pos=D.Entities[i]:GetPos()
 assert(math.abs(pos.x)+14<200 and math.abs(pos.y)+14<130)
 for j=1,i-1 do assert(pos:DistToSqr(D.Entities[j]:GetPos())>=40^2) end
 for _,prop in ipairs(S.HutEntities) do
  local q=prop:GetPos();assert((pos.x-q.x)^2+(pos.y-q.y)^2>=48^2)
 end
end
print('DAMSEL_STAGING_PASS: all20 fit clear perimeter, stable positions, no transition duplication, late join/one letter, E use and campaign removal')

-- Actual portrait panel construction; model colors and material selection stay
-- at the native render boundary for the in-engine playtest.
SERVER=false;CLIENT=true
local receivers,panels={},{}
net.Receive=function(name,fn) receivers[name]=fn end
surface={SetDrawColor=noop,DrawRect=noop,DrawOutlinedRect=noop}
function ScrW() return 1280 end;function ScrH() return 800 end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a} end
function Material() return {GetTexture=function() return nil end} end
function HSVToColor() return Color(100,150,210) end
LOD.RNG=LOD.RNG or {New=function() return {Int=function(_,a) return a end} end}
LOD.Seeds=LOD.Seeds or {Derive=function() return 1 end}
vgui={Create=function(kind,parent)
 local panel={kind=kind,parent=parent,Entity={GetModel=function() return 'portrait' end,GetMaterials=function() return {} end}}
 for _,method in ipairs({'SetTitle','SetDraggable','MakePopup','SetFOV','SetCamPos','SetLookAt','SetFont','SetTextColor','SetWrap'}) do panel[method]=noop end
 panel.SetPos=function(self,x,y) self.x=x;self.y=y end
 panel.SetSize=function(self,w,h) self.w=w;self.h=h end
 panel.SetModel=function(self,m) self.model=m end
 panel.SetText=function(self,text) self.text=text end
 panel.Remove=function(self) self.valid=false end;panel.Close=panel.Remove
 panels[#panels+1]=panel;return panel
end}
LOD.Config.Models=LOD.Config.Models or {Deborah='models/Humans/Group01/Female_01.mdl'}
dofile(root..'cl_damsels.lua')
D:ShowDialogue(1,'Rescued.','Ammo replenished.')
assert(panels[2].kind=='DModelPanel' and panels[2].x<panels[3].x and panels[2].y<panels[4].y)
assert(panels[3].text=='Nessa' and panels[4].text=='Rescued.' and panels[5].text=='Ammo replenished.')
local firstFrame=D.DialogueFrame
D:ShowDialogue(20,'At last.','ABUNDANCE')
assert(not firstFrame.valid and panels[8].model==LOD.Config.Models.Deborah)
KEY_E=18;D.DialogueFrame.OnKeyCodePressed(nil,KEY_E);assert(not D.DialogueFrame.valid)
print('DAMSEL_DIALOGUE_PASS: native panel hierarchy, upper-left portrait, name/text/receipt and E dismissal')
