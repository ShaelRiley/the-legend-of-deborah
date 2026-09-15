-- Actual equipment ownership, reward generator and elemental render paths.
local f=dofile('tools/test_equipment_economy_runtime.lua')
local E,Loot,Run=LOD.Equipment,LOD.LootDirector,f.Run
local p=f.actor('stored');Run.State.PlayerState.stored=p.ps
p:Give('weapon_357');p:SelectWeapon('weapon_357');E:Sync(p)
local w=p:GetActiveWeapon();w.clip=3;p.ammo['357']=17
local item=E:Equipped(p.ps.equipment,'weapon_357');local saved=table.Copy(item)
assert(E:InventoryWeapon(p,item.id,true))
assert(p.activeClass=='weapon_lod_empty_hands' and p:GetWeapon('weapon_357')==w)
assert(p.ps.equipment.activeWeaponClass=='weapon_lod_empty_hands')
local _,_,_,extras=E:Contributions(p.ps.equipment)
assert(w.clip==3 and p.ammo['357']==17 and p.ps.equipment.items[item.id].name==saved.name)
assert(not E:InventoryWeapon(p,item.id,true),'Stale stow cannot switch a different active weapon')
assert(E:InventoryWeapon(p,item.id,false) and p:GetActiveWeapon()==w)
assert(w.clip==3 and p.ammo['357']==17 and p.ps.equipment.items[item.id].id==saved.id)
p.soldier=true;assert(not E:InventoryWeapon(p,item.id,true));p.soldier=false
p.hp=0;assert(not E:InventoryWeapon(p,item.id,true));p.hp=100
assert(not E:InventoryWeapon(p,'foreign-id',false))
-- The actual need-weighted ordinary drop table exposes every requested family.
function p:Armor() return 0 end
local categories={}
for i=1,3000 do
    local category=Loot:_DropCategory(p,{dryKills=0},LOD.RNG.New(i*139),false)
    categories[category or 'none']=(categories[category or 'none'] or 0)+1
end
for _,kind in ipairs({'ammo','health','armor','weapon','wearable','consumable','life','none'}) do
    assert(categories[kind] and categories[kind]>5,'Reachable natural category: '..kind)
end
-- Explicit enemy categories reach real generated records and collection.
local families={}
for i=1,80 do
    local kind,payload=Loot:ResolveEnemyReward(p,'wearable',LOD.RNG.New(i))
    kind,payload=E:PrepareReward('stored',kind,payload,{staticId='drop'..i,equipmentEligible=true})
    assert(kind=='wearable' and E:ValidateWearable(payload.item))
    families[payload.item.definitionId]=true
end
for _,id in ipairs({"vest","headwear","ring","boots","trousers","gloves","shield"}) do assert(families[id],"Natural wearable family: "..id) end
assert(categories.wearable>300 and categories.consumable>150 and categories.weapon>150)
local gearKind,gearPayload=E:PrepareReward('stored','wearable',{}, {staticId='vest-drop',equipmentEligible=true})
local gearPickup={valid=true,LODLootOwnerIdentity='stored',LODLootLevelSeed=Run.State.LevelSeed,
    LODLootKind=gearKind,LODLootPayload=gearPayload,LODLootStaticId='vest-drop'}
assert(Loot:Collect(gearPickup,p,true) and p.ps.equipment.items[gearPayload.item.id])
assert(not Loot:Collect(gearPickup,p,true))
local kind,payload=Loot:ResolveEnemyReward(p,'consumable',LOD.RNG.New(1))
assert(kind=='consumable' and payload.itemId=='healing_potion')
local ent={valid=true,LODLootOwnerIdentity='stored',LODLootLevelSeed=Run.State.LevelSeed,
    LODLootKind=kind,LODLootPayload=payload,LODLootStaticId='potion-drop'}
assert(Loot:Collect(ent,p,false) and p.ps.equipment.items.healing_potion.count==1)
assert(not Loot:Collect(ent,p,false),'Repeated collection cannot duplicate a potion')
print('STOW_AND_ORDINARY_DROPS_PASS')
-- No engine particle system is involved. Assert actual geometry by every Content,
-- both quality modes, age evolution, expiry, capped sound and net event dispatch.
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:GetNormalized() local n=math.sqrt(self.x^2+self.y^2+self.z^2);return self*(1/math.max(n,.001)) end
function V:DistToSqr(b) local d=self-b;return d.x^2+d.y^2+d.z^2 end
function V:Distance(b) return math.sqrt(self:DistToSqr(b)) end
Angle=function(...) return {...} end
Material=function(s) return s end;CreateMaterial=function(s) return s end
local calls,boxes,sounds,now=0,0,0,0
CurTime=function() return now end
sound={Play=function() sounds=sounds+1 end}
render={SetMaterial=function() end,DrawSprite=function() calls=calls+1 end,
    DrawBeam=function() calls=calls+1 end,DrawBox=function() calls=calls+1;boxes=boxes+1 end,
    DrawSphere=function() calls=calls+1 end,DrawQuadEasy=function() calls=calls+1 end}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
EyePos=function() return Vector(10000,0,0) end
dofile(root..'cl_magic_area.lua');dofile(root..'cl_magic_spectacle.lua')
local S=LOD.MagicSpectacle
for _,form in ipairs({'blast','beam','bolt','bomb','missile','summon','summon_hit'}) do
    for _,content in ipairs({'raw','earth','ice','fire','electric','dark','light'}) do
        local fx={form=form,content=content,origin=Vector(),destination=Vector(10,0,0),radius=100,tiles={},shape=1}
        calls=0;S:Draw(fx,.18,false);local normal=calls
        assert(normal>5 and normal<130)
        calls=0;S:Draw(fx,.18,true);assert(calls>0 and calls<normal)
        calls=0;S:Draw(fx,.95,false);assert(calls==0)
        S:Begin(fx)
    end
end
assert(boxes>0 and sounds==1,'Earth fragments render and burst sound is rate limited')
local hooks,receivers={},{}
hook.Add=function(_,id,fn) hooks[id]=fn end
net.Receive=function(id,fn) receivers[id]=fn end
GetConVar=function() return {GetBool=function() return false end} end
LocalPlayer=function() return nil end
LOD.StatusPortrait=nil
dofile(root..'cl_magic_form_fx.lua')
local packet,index
local function read() index=index+1;return packet[index] end
net.ReadString=read;net.ReadVector=read;net.ReadEntity=read;net.ReadUInt=read;net.ReadFloat=read
for i=1,100 do
    packet={'bomb','electric',Vector(),Vector(100,0,0),false,1,100};index=0
    receivers.LOD_MagicFormFX()
end
calls=0;hooks.LOD_MagicFormPresentation(true,false);assert(calls==0)
hooks.LOD_MagicFormPresentation(false,true);assert(calls==0)
hooks.LOD_MagicFormPresentation(false,false);assert(calls>0 and calls<1000,'Four area impacts bound rendering under a burst')
hooks.LOD_MagicFormPresentationCleanup();calls=0
hooks.LOD_MagicFormPresentation(false,false);assert(calls==0)
print('MAGIC_SPECTACLE_PASS: seven content signatures, six forms, reduced work, expiry, net dispatch, burst budget, sound throttle, cleanup')
