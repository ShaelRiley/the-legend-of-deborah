-- Actual area renderer and staging presentation, with Source boundaries doubled.
local root='gamemodes/legend_of_deborah/gamemode/'
LOD={UI={}}
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
function V.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function V.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:LengthSqr() return self:Dot(self) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:GetNormalized() return self*(1/math.sqrt(self:LengthSqr())) end
function V:Normalize() local n=self:GetNormalized();self.x,self.y,self.z=n.x,n.y,n.z end
function Angle(p,y,r) return {p=p,y=y,r=r,Forward=function() return Vector(1,0,0) end,Right=function() return Vector(0,1,0) end,Up=function() return Vector(0,0,1) end} end
function V:Angle() return Angle(0,0,0) end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function math.Clamp(x,a,b) return math.max(a,math.min(b,x)) end
function IsValid(x) return type(x)=='table' and x.valid==true end
function isstring(x) return type(x)=='string' end
local now,reduced=0,false
CurTime=function() return now end
GetConVar=function() return {GetBool=function() return reduced end} end
local eye=Vector(200,0,20)
EyePos=function() return eye end
local events,receivers={},{}
hook={Add=function(_,n,f) events[n]=f end}
net={Receive=function(n,f) receivers[n]=f end}
local material,spheres,quads,beams=nil,{},{},{}
CreateMaterial=function(n,_,p) assert(p['$ignorez']=='0' and p['$translucent']=='1');return n end
Material=function(n) return n end
render={SetMaterial=function(m) material=m end,DrawSphere=function(pos,r,long,lat,c) spheres[#spheres+1]={r=r,long=long,lat=lat,c=c} end,
    DrawQuadEasy=function(pos,normal,w,h,c) quads[#quads+1]={pos=pos,normal=normal,w=w,h=h,c=c} end,
    DrawQuad=function(a,b,c,d,color) quads[#quads+1]={c=color,material=material} end,
    DrawBeam=function(_,_,_,_,_,c) beams[#beams+1]=c end,DrawSprite=function() end}
dofile(root..'lod/cl_magic_area.lua')
local A=LOD.MagicArea
for _,color in pairs(A.Colors) do
    local edge,fill=A:Ink(color,1);assert(edge.a==255 and fill.a==102 and edge.r==fill.r and edge.b==fill.b)
    local edge2,fill2=A:Ink(color,.5);assert(edge2.a==127 and fill2.a==51)
end
A:Sphere(Vector(),100,Color(1,2,3,102),false);assert(spheres[1].r==100)
eye=Vector();A:Sphere(Vector(),100,Color(1,2,3,102),true)
assert(spheres[2].r==-100 and spheres[2].long<spheres[1].long,'Inside view and reduced tessellation')
A:Cell(Vector(0,0,3),256,Color(1,2,3,102));assert(quads[1].w==256 and quads[1].normal.z==-1)
eye=Vector(0,0,80);A:Cell(Vector(0,0,3),256,Color(1,2,3,102));assert(quads[2].normal.z==1)
local player={valid=true,Alive=function() return true end,GetNW2Bool=function() return false end}
LocalPlayer=function() return player end
surface={PlaySound=function() end,CreateFont=function() end}
net.ReadEntity=function() return player end
local reading=0
net.ReadVector=function() reading=reading+1;return reading%2==1 and Vector() or Vector(1,0,0) end
vector_origin=Vector()
LOD.Audio=dofile('tools/audio_test_double.lua')
dofile(root..'lod/cl_magic.lua')
receivers.LOD_MagicShoutFX()
quads={};beams={};events.LOD_MagicForceShoutWaves(true,false);assert(#quads==0 and #beams==0)
events.LOD_MagicForceShoutWaves(false,true);assert(#quads==0)
events.LOD_MagicForceShoutWaves(false,false)
assert(#quads==32 and #beams==24 and quads[1].c.a==102 and beams[1].a==255)
now=.2;quads={};events.LOD_MagicForceShoutWaves(false,false);assert(#quads==64 and quads[1].c.a<102)
reduced=true;quads={};events.LOD_MagicForceShoutWaves(false,false);assert(#quads==32,'Reduced effects retain one readable filled wave')
for i=1,50 do receivers.LOD_MagicShoutFX() end
assert(#LOD.MagicFX.waves==12,'Bounded legacy wave bursts')
events.LOD_MagicShoutCleanup();assert(#LOD.MagicFX.waves==0)
-- Spawn beyond the portal, opposite the Hermit and clear of the central pad.
local S={HutCenter=Vector(10,20,30),HutAngles=Angle(0,0,0),HutHalfForward=200,HutGuideDistance=76,
    EnsureHut=function() return true end,_RegisterHutEntity=function(_,e) return e end}
LOD.StagingDeployment=S;LOD.RunManager={};LOD.CryptoDirector={};LOD.CryptoStore={}
local statue={valid=true,SetPos=function(s,p) s.pos=p end,SetAngles=function(s,a) s.angle=a end,Spawn=function() end,Activate=function() end}
ents={Create=function(class) assert(class=='lod_debbie_statue');return statue end}
util={AddNetworkString=function() end}
dofile(root..'lod/sv_crypto_statue.lua');assert(LOD.CryptoDirector:EnsureStatue())
assert(statue.pos.x<S.HutCenter.x-S.HutGuideDistance-32 and statue.pos.x>S.HutCenter.x-S.HutHalfForward+16)
assert(statue.pos.y-S.HutCenter.y==80 and statue.angle.y==0)
-- One shared prompt painter for statue, portal and manual, honoring rebound Use.
include=function() end
ScrW=function() return 1280 end;ScrH=function() return 800 end
input={LookupBinding=function() return 'mouse4' end}
TEXT_ALIGN_CENTER=1
local paints={};draw={SimpleTextOutlined=function(...) paints[#paints+1]={...} end}
function statue:GetClass() return 'lod_debbie_statue' end
function statue:GetPos() return Vector() end
player.GetEyeTrace=function() return {Entity=statue} end
player.GetPos=function() return Vector() end
player.EyePos=function() return Vector() end
player.EyeAngles=function() return Angle(0,0,0) end
ents.FindByClass=function() return {} end
dofile(root..'cl_init.lua');events.LOD_StagingInteractionPrompt()
assert(#paints==1 and paints[1][1]=='Press "MOUSE 4" to Open the Wallet')
assert(paints[1][2]=='LOD_StagingBoundPrompt' and paints[1][8]==4)
assert(LOD.StagingPromptOwnedByGamemode,'Legacy entity prompt defers to gamemode')
LOD.UI.ActivePage='equipment';events.LOD_StagingInteractionPrompt();assert(#paints==1)
LOD.UI.ActivePage=nil;player.GetPos=function() return Vector(200,0,0) end
events.LOD_StagingInteractionPrompt();assert(#paints==1,'No out-of-range statue prompt')
print('PRESENTATION_POLISH_PASS: opaque boundaries/40% fills, inside/outside, fade/reduced/caps, opposite-portal statue placement and standard rebound prompt')

-- Reproduce the server realm: Entity has no client-only SetupBones method.
ENT={};AddCSLuaFile=function() end;include=function() end
LOD.RPGTestLog=nil
local frozen={valid=true,sequence=0,cycle=0,nw={},flexes={}}
local positions={L_UpperArm=Vector(0,10,60),R_UpperArm=Vector(0,-10,60),L_Hand=Vector(0,-8,50),R_Hand=Vector(0,8,50)}
function frozen:LookupBone(name) return name:match('Bip01_(.*)') end
function frozen:LookupSequence(name) return ({LineIdle01=1,LineIdle02=2,LineIdle03=3})[name] end
function frozen:ResetSequence(n) self.sequence=n end
function frozen:SetCycle(n) self.cycle=n end
function frozen:GetBonePosition(id) return positions[id] end
function frozen:GetSequence() return self.sequence end
function frozen:SetPlaybackRate(n) self.rate=n end
function frozen:SetNW2Int(k,v) self.nw[k]=v end
frozen.SetNW2Float=frozen.SetNW2Int
function frozen:SetFlexScale(n) self.flexScale=n end
function frozen:GetFlexNum() return 2 end
function frozen:GetFlexName(i) return i==0 and 'right_lowerer' or 'left_lowerer' end
function frozen:SetFlexWeight(i,v) self.flexes[i]=v end
dofile('gamemodes/legend_of_deborah/entities/entities/lod_debbie_statue/init.lua')
assert(frozen.SetupBones==nil)
ENT.FreezeDeborahPose(frozen)
assert(frozen.rate==0 and frozen.nw.LOD_StatueSequence==frozen.sequence)
assert(frozen.nw.LOD_StatueCycle==frozen.cycle and frozen.flexes[0]==.8)
assert(frozen.LODStatueArmsCrossed,'Frozen pose must finish without client-only APIs on the server')
print('STATUE_SERVER_REALM_PASS: bone queries/frozen state/scowl complete without SetupBones')
