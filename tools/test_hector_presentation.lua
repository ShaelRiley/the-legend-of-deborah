-- Execute the production receiver/render/lifecycle paths. Strict native API
-- doubles measure resources and render state; Source visuals remain native QA.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local now,low,created,live,draws,clips,clipping,fault=10,false,0,0,0,0,false,false
local hooks,receivers,queue,labels={},{},{},{}
local noop=function() end
function CurTime() return now end
function IsValid(e) return type(e)=='table' and not e.removed end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
local vec={};vec.__index=vec
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vec) end
function vec.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function vec.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function vec.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function vec:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function vec:DistToSqr(b) local d=self-b;return d:Dot(d) end
function vec:Normalize() local len=math.sqrt(self:Dot(self));if len>0 then self.x=self.x/len;self.y=self.y/len;self.z=self.z/len end end
function vec:GetNormalized() local p=Vector(self.x,self.y,self.z);p:Normalize();return p end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,Right=function() return Vector(0,1,0) end} end
function vec:Angle() return Angle(0,0,0) end
math.Clamp=function(x,a,b) return math.max(a,math.min(x,b)) end
function Material() return {} end
function GetConVar() return {GetBool=function() return low end} end
function EyePos() return Vector() end
function ScrW() return 1280 end
function ScrH() return 720 end
TEXT_ALIGN_CENTER=1;RENDERGROUP_OPAQUE=0
hook={Add=function(_,id,fn) hooks[id]=fn end}
local function read() assert(#queue>0,'read past snapshot');return table.remove(queue,1) end
net={Receive=function(id,fn) receivers[id]=fn end,ReadBool=read,ReadEntity=read,ReadVector=read,ReadFloat=read,ReadUInt=read}
surface={CreateFont=noop}
draw={RoundedBox=noop,SimpleText=function(s) labels[#labels+1]=s end}
local beams,sprites,discs,errors=0,0,0,0
render={SetColorMaterial=noop,SetMaterial=noop,DrawBeam=function() beams=beams+1 end,
    DrawSprite=function() sprites=sprites+1 end,
    EnableClipping=function(value) local old=clipping;clipping=value;return old end,
    PushCustomClipPlane=function() assert(clipping);clips=clips+1 end,
    PopCustomClipPlane=function() clips=clips-1;assert(clips>=0) end}
function ErrorNoHalt() errors=errors+1 end
local all={}
function ClientsideModel(model)
    created=created+1;live=live+1
    local e={model=model}
    e.SetNoDraw=noop;e.DrawShadow=noop;e.SetColor=noop;e.ResetSequence=noop;e.SetCycle=noop;e.SetPlaybackRate=noop
    function e:SetModelScale(s) self.scale=s end
    function e:SetPos(p) self.pos=p end
    function e:SetAngles(a) self.angle=a end
    e.SetupBones=noop
    function e:LookupBone() return nil end
    function e:GetBoneMatrix() return nil end
    function e:DrawModel() assert(not self.removed);draws=draws+1;if fault and model=='models/monk.mdl' then error('injected draw failure') end end
    function e:Remove() assert(not self.removed);self.removed=true;live=live-1 end
    all[#all+1]=e;return e
end
LOD={CampaignTimeout={FlattywoodSign=Vector(-82108,3781,-6272)},MagicArea={Disc=function() discs=discs+1 end}}
local actor={WorldSpaceCenter=function() return Vector(0,0,45) end}
local function packet(stage,kind,markCount,hazardCount,ent)
    queue={true,ent or actor,Vector(),stage or 2,500,1000,2,now+3,kind or 0,now+1.5,markCount or 0}
    for i=1,markCount or 0 do queue[#queue+1]=Vector(i*20,0,0) end
    queue[#queue+1]=hazardCount or 0
    for i=1,hazardCount or 0 do
        queue[#queue+1]=i%4+1;queue[#queue+1]=Vector(i*20,0,0);queue[#queue+1]=Vector(10,0,0)
        queue[#queue+1]=now+2;queue[#queue+1]=180
    end
    receivers.LOD_HectorState();assert(#queue==0,'incomplete snapshot read')
end
local function world() hooks.LOD_HectorWorld(false,false);assert(clips==0 and not clipping,'render state leaked') end
local function hud() labels={};hooks.LOD_HectorHealth() end
local function has(text) for _,s in ipairs(labels) do if s==text then return true end end end
dofile(root..'cl_hector.lua')
packet(1);assert(live==2 and created==2);world();hud();assert(has('THE DIRECTOR REVEALS HIMSELF'))
assert(all[1].scale==64 and all[2].scale==64)
local n=created
for _=1,20 do packet(2,3,4,12);world() end
assert(created==n and live==2,'snapshot/redraw leaked models')
hud();assert(has("ATTACK THE DIRECTOR'S HEART IN THE COURT") and has('CROWBAR — CLEAR THE MARKS'))
-- Reduced effects keeps all danger footprints, but halves circle segments.
packet(2,2,4,0);beams=0;discs=0;world();local full=beams;assert(discs==4)
low=true;beams=0;discs=0;world();assert(beams<full and discs==4);low=false
-- Enforced client bounds even if a packet uses all available count bits.
packet(2,3,7,15);beams=0;world();local over=beams
packet(2,3,4,12);beams=0;world();assert(beams==over,'unbounded mark/hazard render')
fault=true;world();assert(errors==1 and clips==0 and not clipping);fault=false
packet(3);assert(live==0);hud();assert(has('HECTOR DEFEATED — TAKE THE JAIL KEY'));world()
packet(2);assert(live==2);queue={false};receivers.LOD_HectorState();assert(live==0);hud();assert(#labels==0)
packet(2);now=now+2.1;hooks.LOD_HectorPropsRetire();assert(live==0);hud();assert(#labels==0)
packet(2);actor.removed=true;hooks.LOD_HectorPropsRetire();assert(live==0);actor.removed=nil
packet(2);local previous=all[#all];local replacement={WorldSpaceCenter=actor.WorldSpaceCenter}
packet(2,0,0,0,replacement);assert(live==2 and previous.removed,'replacement retained prior models')
hooks.LOD_HectorMapCleanup();assert(live==0);hud();assert(#labels==0)
packet(2);dofile(root..'cl_hector.lua');assert(live==0,'hot reload leaked models')
packet(2);hooks.LOD_HectorShutdown();assert(live==0)
print('HECTOR_PRESENTATION_PASS: native receiver/render paths; bounded models/marks/hazards; readable phases; reduced effects; clip fault unwind; inactive/stale/entity/map/shutdown/hot reload cleanup')
