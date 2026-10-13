-- Execute the canonical gamemode HUD hook; engine trace/drawing are doubles.
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},V) end
function V.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V:LengthSqr() return self.x^2+self.y^2+self.z^2 end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:Normalize() local n=math.sqrt(self:LengthSqr());self.x,self.y,self.z=self.x/n,self.y/n,self.z/n end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
IsValid=function(v) return type(v)=='table' and v.valid==true end
isstring=function(v) return type(v)=='string' end
Color=function(...) return {...} end
ScrW=function() return 1280 end;ScrH=function() return 800 end
TEXT_ALIGN_CENTER=1
local binding='e'
input={LookupBinding=function(name) assert(name=='+use');return binding end}
local hooks,fonts,texts={}, {}, {}
hook={Add=function(event,id,fn) hooks[id]=fn end}
surface={CreateFont=function(id,spec) fonts[id]=spec end}
draw={SimpleTextOutlined=function(text,font,x,y,_,ax,ay,outline)
 texts[#texts+1]=text;assert(font=='LOD_StagingBoundPrompt' and x==640 and y==512)
 assert(ax==TEXT_ALIGN_CENTER and ay==TEXT_ALIGN_CENTER and outline==4)
end}
include=noop
LOD={UI={},BossRegistry={Modules={}},Damsels={},FieldManual={}}
local target
local ply={valid=true,alive=true,pos=Vector(0,0,0),nw={LOD_Staged=true}}
function ply:Alive() return self.alive end
function ply:GetNW2Bool(key,default) local v=self.nw[key];if v==nil then return default end;return v end
function ply:GetPos() return self.pos end
function ply:EyePos() return self.pos end
function ply:EyeAngles() return {Forward=function() return Vector(1,0,0) end} end
function ply:GetEyeTrace() return {Entity=target} end
LocalPlayer=function() return ply end
local nearby={}
ents={FindByClass=function(class) return nearby[class] or {} end}
local function entity(class,x)
 return {valid=true,pos=Vector(x or 100,0,0),GetClass=function() return class end,
 GetPos=function(self) return self.pos end,WorldSpaceCenter=function(self) return self.pos end}
end
local guide=entity('lod_staging_prop')
guide.KIND_GUIDE=1;guide.KIND_PORTAL=2;guide.kind=1;guide.label='DUNGEON HERMIT'
function guide:GetStageKind() return self.kind end
function guide:GetStageLabel() return self.label end
target=guide
dofile('gamemodes/legend_of_deborah/gamemode/cl_init.lua')
local paint=assert(hooks.LOD_StagingInteractionPrompt)
assert(LOD.StagingPromptOwnedByGamemode and fonts.LOD_StagingBoundPrompt.size==38)
local function expect(wanted)
 texts={};paint();assert(#texts==(wanted and 1 or 0),'wrong number of interaction prompts')
 if wanted then assert(texts[1]==wanted,texts[1]) end
end
expect('Press E to Talk to the Hermit')
binding='mouse4';expect('Press MOUSE 4 to Talk to the Hermit')
binding=nil;expect('Press E to Talk to the Hermit')
guide.label='HECTOR THE DIRECTOR';expect('Press E to Talk to Hector');guide.label='DUNGEON HERMIT'
guide.pos.x=112;expect('Press E to Talk to the Hermit')
guide.pos.x=112.01;expect(nil);guide.pos.x=100
for key,value in pairs({LOD_Staged=false,LOD_IsSoldier=true,LOD_Eliminated=true,LOD_Deployed=true}) do
 local old=ply.nw[key];ply.nw[key]=value;expect(nil);ply.nw[key]=old
end
ply.alive=false;expect(nil);ply.alive=true
ply.valid=false;expect(nil);ply.valid=true
guide.valid=false;expect(nil);guide.valid=true
guide.kind=3;expect(nil);guide.kind=1
LOD.UI.ActivePage={};expect(nil);LOD.UI.ActivePage=nil
for _,owner in ipairs({LOD.Damsels,LOD.FieldManual}) do
 local key=owner==LOD.Damsels and 'DialogueFrame' or 'Frame'
 owner[key]={valid=true};expect(nil);owner[key]=nil
end
-- Portal/statue/manual retain the existing shared hook, font and key routing.
binding='f';target=entity('lod_debbie_statue')
expect('Press "F" to Open the Wallet')
target=nil;nearby.lod_field_manual={entity('lod_field_manual')}
expect('Press "F" to Read')
nearby.lod_field_manual=nil
local portal=entity('lod_staging_prop');portal.KIND_PORTAL=2
portal.GetStageKind=function() return 2 end
portal.PortalAimFraction=function(_,p,d) assert(p==ply and d==340);return .3 end
nearby.lod_staging_prop={portal};expect('Press "F" to Enter the Labyrinth')
-- Dungeon release uses the same large aimed prompt and actual bound Use key.
nearby.lod_staging_prop={};ply.nw.LOD_Staged=false;ply.nw.LOD_Deployed=true
local console=entity('lod_neil_release_button',80)
console.released=false
function console:GetReleased() return self.released end
function console:GetPickupPosition() return self:GetPos() end
target=console;binding='e';expect('Press "E" to Release Neil')
binding='mouse4';expect('Press "MOUSE 4" to Release Neil')
console.pos.x=96;expect('Press "MOUSE 4" to Release Neil')
console.pos.x=96.01;expect(nil);console.pos.x=80
console.released=true;expect(nil);console.released=false
ply.nw.LOD_IsSoldier=true;expect(nil);ply.nw.LOD_IsSoldier=false
ply.nw.LOD_Eliminated=true;expect(nil);ply.nw.LOD_Eliminated=false
LOD.UI.ActivePage={};expect(nil);LOD.UI.ActivePage=nil
ply.alive=false;expect(nil);ply.alive=true
target=nil;expect(nil)
print('STAGING_PROMPT_PASS: one large Hermit prompt; rebound/fallback Use; reveal; exact reach; role/life/staging/menu/dialogue guards; portal/statue/manual regressions')
