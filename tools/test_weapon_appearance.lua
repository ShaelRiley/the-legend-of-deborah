local f=dofile('tools/test_equipment_economy_runtime.lua')
local E,V=LOD.Equipment,LOD.WeaponAppearance
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local seen,hashes,maxBytes={}, {},0
for i=1,2500 do
    local item=E:Generate(i*197,1+i%100,'weapon_357','visual:'..i)
    local packet=V:Encode(item);maxBytes=math.max(maxBytes,#packet)
    assert(#packet>0 and #packet<=480)
    local style=assert(V:Decode(packet));local raw=assert(V:Compile(V:Data(item)))
    assert(style.hash==raw.hash and #style.traits==#item.properties)
    local frozen=table.Copy(item);frozen.id='recreated:'..i
    assert(V:Encode(frozen)==packet,'DFT recreation/renaming cannot change frozen appearance')
    local reverse=table.Copy(item);local list={};for j=#reverse.properties,1,-1 do list[#list+1]=reverse.properties[j] end
    reverse.properties=list;assert(V:Encode(reverse)==packet,'Property ordering is not identity')
    for _,t in ipairs(style.traits) do seen[t.id]=true;assert(t.glyph~='' and t.bars>=1 and t.bars<=4) end
    assert(not hashes[style.hash],'Sample repeated a full visual fingerprint');hashes[style.hash]=true
end
-- Every catalog property can be represented, including wearable-only properties
-- if future weapon eligibility changes. Each amount affects identity.
for _,id in ipairs(E.EconomyOrder) do
    local g=assert(V.Grammar[id]);assert(g.label and g.shape and g.glyph)
    local data={1,42,1,100,{{g.index,1}}};local first=assert(V:Compile(data))
    data[5][1][2]=2;assert(V:Compile(data).hash~=first.hash)
    data[5][1][2]=-1;local negative=assert(V:Compile(data));assert(negative.traits[1].negative)
end
for _,packet in ipairs({'','bad',string.rep('x',481),'1;0;1;1;999:2','2;0;1;1;1:2','1;nan;1;1;1:2','1;1;1;1;1:2,1:3'}) do
    assert(not V:Decode(packet))
end
local gun=f.actor('visual-owner');gun:Give('weapon_357');gun:SelectWeapon('weapon_357');E:Sync(gun)
local weapon=gun:GetActiveWeapon();local first=weapon.nw.LOD_WeaponAppearance;assert(V:Decode(first))
local copy=E:NewItem(gun,'weapon_357','another');assert(E:AcquireWorldItem(gun,copy,false,'pickup'))
assert(weapon.nw.LOD_WeaponAppearance==first,'Collecting a copy leaves the held style intact')
assert(E:InventoryWeapon(gun,copy.id,false));assert(weapon.nw.LOD_WeaponAppearance==V:Encode(copy))
local writes=0;local old=weapon.SetNW2String
function weapon:SetNW2String(k,v) if k=='LOD_WeaponAppearance' then writes=writes+1 end;return old(self,k,v) end
for i=1,100 do V:Stamp(weapon,copy) end;assert(writes==0,'Unchanged records do not send appearance again')
print('APPEARANCE_DATA_PASS: 2500 distinct sampled fingerprints; all '..#E.EconomyOrder..' properties; max packet '..maxBytes..' bytes; frozen/order identity; copy selection; unchanged sends')

-- Execute actual renderer under both detail modes and every grammar shape.
local vectors={};vectors.__index=vectors
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vectors) end
vectors.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
vectors.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
vectors.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function vectors:DistToSqr(b) local d=self-b;return d.x*d.x+d.y*d.y+d.z*d.z end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,RotateAroundAxis=function() end,
    Forward=function() return Vector(1,0,0) end,Right=function() return Vector(0,1,0) end,Up=function() return Vector(0,0,1) end} end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
CreateMaterial=function(name) return name end
local calls,texts,planes,now,low,tick=0,{},0,0,false,1
local function drawCall() calls=calls+1 end
render={SetMaterial=function() end,DrawBox=drawCall,DrawBeam=drawCall,DrawSphere=drawCall}
surface={CreateFont=function() end,SetDrawColor=function() end,DrawRect=drawCall,DrawLine=drawCall,DrawOutlinedRect=drawCall}
draw={SimpleText=function(text) texts[#texts+1]=text;drawCall() end}
cam={Start3D2D=function() planes=planes+1 end,End3D2D=function() planes=planes-1 end}
CurTime=function() return now end;FrameNumber=function() return tick end;EyePos=function() return Vector() end
GetConVar=function() return {GetBool=function() return low end} end
E.DrawItemIcon=function() end
local hooks={};hook.Add=function(_,id,fn) hooks[id]=fn end
dofile(root..'cl_weapon_appearance.lua')
local ent={valid=true,pos=Vector()}
function ent:GetNW2String() return V:Encode(copy) end
function ent:GetNoDraw() return false end
function ent:GetPos() return self.pos end
function ent:LookupAttachment() return 1 end
function ent:GetAttachment() return {Pos=Vector(10,0,0),Ang=Angle()} end
function ent:GetClass() return 'weapon_357' end
function ent:OBBCenter() return Vector() end
function ent:LocalToWorld(p) return p end
function ent:GetAngles() return Angle() end
for _,id in ipairs(E.EconomyOrder) do
    local g=V.Grammar[id];local style=V:Compile({1,42,4,100,{{g.index,2}}})
    for _,reduced in ipairs({false,true}) do
        low=reduced;calls=0;texts={};V:Draw(ent,style,'weapon_357',nil,true)
        assert(calls>5 and calls<130 and planes==0)
        assert(texts[1]==g.glyph,'Every actual property engraving is drawn')
    end
end
local style=V:ItemStyle(copy);local same=V:ItemStyle(copy);assert(style==same)
low=false;calls=0;for i=1,20 do V:Draw(ent,style,'weapon_357',nil,false) end
local capped=calls;V:Draw(ent,style,'weapon_357',nil,false);assert(calls==capped)
tick=tick+1;low=true;calls=0;for i=1,4 do V:Draw(ent,style,'weapon_357',nil,false) end
capped=calls;V:Draw(ent,style,'weapon_357',nil,false);assert(calls==capped)
ent.pos=Vector(2000,0,0);calls=0;V:Draw(ent,style,'weapon_357',nil,false);assert(calls==0)
ent.pos=Vector();ent.LookupAttachment=function() return 0 end
V:Draw(ent,style,'weapon_lod_crowbar',nil,true);assert(planes==0)
ent.LookupBone=function() return 0 end
ent.GetBonePosition=function() return Vector(99,0,0),Angle() end
local anchor=V:Anchor(ent,'weapon_lod_crowbar',true);assert(anchor.x>99,'Melee ornament follows the animated hand bone')
hooks.LOD_ProceduralWeaponAppearance(ent,nil,ent)
E:DrawItemIcon(copy,0,0,48,pale);assert(planes==0)
hooks.LOD_WeaponAppearanceCleanup();assert(V:ItemStyle(copy)~=same)
print('APPEARANCE_RENDER_PASS: all shapes/glyphs; quality modes; balanced 3D2D; frame/distance caps; attachment fallback; weak-cache cleanup')
