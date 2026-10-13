-- Production display/collision/pickup boundaries; not native Source acceptance.
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:Cross(b) return Vector(self.y*b.z-self.z*b.y,self.z*b.x-self.x*b.z,self.x*b.y-self.y*b.x) end
function V:LengthSqr() return self:Dot(self) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:Angle() return Angle(math.deg(math.atan(-self.z,math.sqrt(self.x^2+self.y^2))),math.deg(math.atan(self.y,self.x)),0) end
local A={};A.__index=A
function Angle(p,y,r)
    local cp,sp,cy,sy,cr,sr=math.cos(math.rad(p)),math.sin(math.rad(p)),math.cos(math.rad(y)),math.sin(math.rad(y)),math.cos(math.rad(r)),math.sin(math.rad(r))
    return setmetatable({p=p,y=y,r=r,f=Vector(cp*cy,cp*sy,-sp),
        right=Vector(-sr*sp*cy+cr*sy,-sr*sp*sy-cr*cy,-sr*cp),
        up=Vector(cr*sp*cy+sr*sy,cr*sp*sy-sr*cy,cr*cp)},A)
end
function A:Forward() return self.f end
function A:Right() return self.right end
function A:Up() return self.up end
function A:RotateAroundAxis(axis,degrees)
    local co,si=math.cos(math.rad(degrees)),math.sin(math.rad(degrees))
    local function rotate(v) return v*co+axis:Cross(v)*si+axis*(axis:Dot(v)*(1-co)) end
    self.f,self.right,self.up=rotate(self.f),rotate(self.right),rotate(self.up)
end
angle_zero=Angle(0,0,0)
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function IsValid(e) return type(e)=='table' and not e.removed end
local now,eye,still=0,Vector(150,0,80),false
function CurTime() return now end
function EyePos() return eye end
TEXT_ALIGN_CENTER=1;RENDERGROUP_BOTH=9;MOVETYPE_NONE=0;SOLID_BBOX=2;COLLISION_GROUP_NONE=0
LOD={Config={Progression={KeycardHeight=40,KeycardTriggerRadius=52},Maze={CellSize=384}}}
LOD.AdventurePresentation={Reduced=function() return still end,Glint=noop}
math.random=function() error('key display consumed gameplay RNG') end
local hooks={};hook={Add=function(event,_,fn) hooks[event]=fn end}
AddCSLuaFile=noop;Material=noop
local path=arg[1] or 'gamemodes/legend_of_deborah/entities/entities/lod_jail_key/'
ENT={};dofile(path..'shared.lua');include=noop
local materials,boxes,sprites,planes,texts={}, {}, {}, {}, {}
CreateMaterial=function(_,shader,params)
    assert(shader=='UnlitGeneric' and params['$ignorez']~='1','key bypasses maze depth')
    local m={params=params};materials[#materials+1]=m;return m
end
render={SetMaterial=noop,
    DrawBox=function(pos,ang,lo,hi,color,writeZ)
        assert(writeZ==true and color.a==255,'solid objective lost normal opaque depth')
        boxes[#boxes+1]={pos=pos,ang=ang,lo=lo,hi=hi,color=color}
    end,
    DrawSprite=function(pos,w,h) sprites[#sprites+1]={pos=pos,r=math.max(w,h)*.5} end}
cam={Start3D2D=function(pos,ang,scale) planes[#planes+1]={pos=pos,ang=ang,scale=scale} end,End3D2D=noop}
draw={RoundedBox=noop,SimpleText=function(text) texts[#texts+1]=text end}
dofile(path..'cl_init.lua')
local e=setmetatable({pos=Vector(500,-300,200),source='production'}, {__index=ENT})
function e:GetPos() return self.pos end
function e:GetClass() return 'lod_jail_key' end
function e:GetKeySource() return self.source end
function e:EntIndex() return 17 end
function e:SetRenderBounds(lo,hi) self.lo,self.hi=lo,hi;self.boundsWrites=(self.boundsWrites or 0)+1 end
assert(e.Initialize,'key uses tiny placeholder render bounds')
e:Initialize();assert(ENT.RenderGroup==RENDERGROUP_BOTH,'missing render pass declaration')
local function inside(point,radius)
    point=point-e.pos;radius=radius or 0
    for _,axis in ipairs({'x','y','z'}) do
        assert(point[axis]-radius>=e.lo[axis]-.00001 and point[axis]+radius<=e.hi[axis]+.00001,'display escapes render bounds at '..axis)
    end
end
local function paint()
    boxes,sprites,planes,texts={},{},{},{}
    e:Draw();local opaque=#boxes;e:DrawTranslucent()
    assert(#boxes==opaque,'opaque geometry painted twice')
end
local poses=0
for _,source in ipairs({'production','gordon_warden','temporary_core','boss:chuck'}) do
    e.source=source
    for _,height in ipairs({-160,0,80,240}) do for yaw=0,315,45 do for _,time in ipairs({0,.31,1.2,3.9,11.1}) do
        now=time;eye=e.pos+Vector(math.cos(math.rad(yaw))*150,math.sin(math.rad(yaw))*150,height)
        paint();poses=poses+1
        assert(#boxes==14 and #planes==1 and #sprites==(source=='temporary_core' and 3 or 0),'finite paint budget')
        assert(texts[1]==(source=='temporary_core' and 'CORE — JAIL KEY' or 'JAIL KEY'),'identity lost')
        for i,box in ipairs(boxes) do
            for _,x in ipairs({box.lo.x,box.hi.x}) do for _,y in ipairs({box.lo.y,box.hi.y}) do for _,z in ipairs({box.lo.z,box.hi.z}) do
                inside(box.pos+box.ang:Forward()*x-box.ang:Right()*y+box.ang:Up()*z)
            end end end
            if i>7 then
                local dir=eye-box.pos;dir=dir*(1/math.sqrt(dir:LengthSqr()))
                assert(box.ang:Forward():Dot(dir)>.99999,'edge-on key')
            end
        end
        for _,sprite in ipairs(sprites) do inside(sprite.pos,sprite.r) end
        local p=planes[1];inside(p.pos,math.sqrt((source=='temporary_core' and 155 or 120)^2+26^2)*p.scale)
        local dir=eye-p.pos;dir=dir*(1/math.sqrt(dir:LengthSqr()))
        assert(p.ang:Forward():Cross(p.ang:Right()):Dot(dir)>.99999,'edge-on/back-facing label')
    end end end
end
assert(#materials==2 and materials[1].params['$ignorez']=='0' and materials[2].params['$ignorez']=='0','depth or material budget')
local before=e.boundsWrites;hooks.NotifyShouldTransmit(e,false);assert(e.boundsWrites==before)
e.lo,e.hi=Vector(-1,-1,-1),Vector(1,1,1)
hooks.NotifyShouldTransmit(e,true);assert(e.boundsWrites==before+1 and e.hi.z>=132,'full-update bounds recovery')
ents={FindByClass=function() return {e} end};hooks.OnReloaded();assert(e.boundsWrites==before+2)
e.source='temporary_core';still=true;eye=e.pos+Vector(100,0,80);now=1;paint()
local pos,size=boxes[8].pos,sprites[1].r
now=50;paint();assert(boxes[8].pos:DistToSqr(pos)==0 and sprites[1].r==size,'Reduced Effects animates')
eye=e.pos+Vector(384*6+1,0,0);paint();assert(#boxes==0 and #planes==0 and #sprites==0,'distance cull')
local sourceGetter=e.GetKeySource
e.GetKeySource=false;eye=e.pos+Vector(100,0,80);paint();assert(texts[1]=='JAIL KEY','partial datatable paint')
e.GetKeySource=sourceGetter

-- Real server Initialize and Think. Only the plinth is solid, never the key.
dofile(path..'init.lua')
function e:SetModel(model) self.model=model end
function e:SetMoveType(kind) self.move=kind end
function e:SetSolid(kind) self.solid=kind end
function e:SetCollisionBounds(lo,hi) self.collisionLo,self.collisionHi=lo,hi end
function e:SetCollisionGroup(kind) self.group=kind end
function e:SetKeySource(source) self.source=source end
e.DrawShadow=noop;e.NextThink=noop
e.source='';e:Initialize()
assert(e.solid==SOLID_BBOX and e.move==MOVETYPE_NONE and e.group==COLLISION_GROUP_NONE)
assert(e.source=='production' and e.pos.z==200,'origin/source changed')
assert(e.collisionLo.x==-20 and e.collisionHi.x==20 and e.collisionHi.y-e.collisionLo.y==40)
assert(e.collisionLo.z==-40 and e.collisionHi.z-e.collisionLo.z==28,'plinth deck/height')
-- Conservative 200 impulse / 600 gravity clearance budget; not native proof.
assert(200^2/(2*600)-(e.collisionHi.z-e.collisionLo.z)>5)
for i=1,7 do
    local box=boxes[i]
    for _,axis in ipairs({'x','y','z'}) do
        assert(box.pos[axis]+box.lo[axis]>=e.pos[axis]+e.collisionLo[axis] and box.pos[axis]+box.hi[axis]<=e.pos[axis]+e.collisionHi[axis],'paint outside solid hull')
    end
end
local calls,sounds=0,0;local allow=false
LOD.ProgressionDirector={CollectJailKey=function(_,ply,key)
    calls=calls+1;assert(key==e and ply.hero)
    if allow then e.removed=true;return true end
    return false
end}
LOD.RunManager={IsActivePlayer=function(_,ply) return ply.hero end}
sound={Play=function() sounds=sounds+1 end}
local hero={hero=true,alive=true,nearest=e.pos+Vector(40,0,0)}
function hero:Alive() return self.alive end
function hero:NearestPoint(pos) assert(pos==e.pos);return self.nearest end
player={GetAll=function() return {hero} end}
now=100;e:Think();assert(calls==1 and not e.removed and sounds==0,'denial removed pedestal')
now=100.01;e:Think();assert(calls==1,'cadence changed')
hero.alive=false;now=101;e:Think();assert(calls==1)
hero.alive=true;hero.hero=false;now=102;e:Think();assert(calls==1)
hero.hero=true;hero.nearest=e.pos+Vector(53,0,0);now=103;e:Think();assert(calls==1,'radius expanded')
hero.nearest=e.pos+Vector(40,0,0);allow=true;now=104;e:Think();assert(calls==2 and e.removed and sounds==1,'collection/pedestal retirement')
print('JAIL_KEY_VISIBILITY_PASS: '..poses..' angle/time/source views; complete bounds; viewer-facing thick key/text; real low/narrow pedestal; opaque/translucent/depth/material budget; Reduced Effects; full-update/reload; partial accessor; culling/cadence/active/live/touch admission; same-entity removal')
