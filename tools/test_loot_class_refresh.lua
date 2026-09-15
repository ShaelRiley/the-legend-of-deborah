local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R,C=LOD.Equipment,LOD.RPGAbilityRules,LOD.CharacterProgressionSystem
local V=getmetatable(Vector())
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function V:GetNormalized() local n=math.sqrt(self:LengthSqr());return n>0 and self*(1/n) or Vector() end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
local attacker=env.actor('rogue');local target=env.actor('target',true)
local p=attacker.LODProgressionState;p.classId='rogue';C:_RecomputeProgressionState(p)
local facing=Vector(1,0,0)
function target:GetForward() return facing end
function attacker:GetPos() return Vector(-100,0,0) end
target.LODProgressionState.derivedStats.damageResistancePerDie=3
local function near(a,b) assert(math.abs(a-b)<.00001,tostring(a)..' ~= '..b) end
for mult=1,3 do
    local c={contributions={10,5},attackEvent={}}
    local tags={physical=true,authoredScale=mult,attackMultiplier=mult}
    near(R:ResolveDamageContract(c,attacker,target,tags),15*(mult+1))
    assert(tags.backstab)
    facing=Vector(-1,0,0)
    near(R:ResolveDamageContract(c,attacker,target,tags),15*(mult+1)) -- same event, no second decision
    facing=Vector(1,0,0)
end
facing=Vector(-1,0,0)
near(R:ResolveDamageContract({contributions={10,5}},attacker,target,{physical=true}),9)
facing=Vector(0,1,0)
near(R:ResolveDamageContract({contributions={10,5}},attacker,target,{physical=true}),9)
facing=Vector(1,0,0)
near(R:ResolveDamageContract({contributions={10,5}},attacker,target,{physical=true,statusDamage=true}),9)
p.classId='fighter';C:_RecomputeProgressionState(p)
near(R:ResolveDamageContract({contributions={10,5}},attacker,target,{physical=true}),9)

-- Actual shield placement and recomputation own the class contribution.
dofile(root..'sv_rpg_block.lua')
p.baseAbilities.str=20;C:_RecomputeProgressionState(p)
local shield=E:NewItem(attacker,'shield','shield');local state=E:Ensure(attacker.ps)
state.items[shield.id]=shield;assert(E:Equip(state,shield.id,'left_arm'));E:RefreshDerived(attacker,attacker.ps)
local base=p.equipmentBlockChanceContribution+(p.derivedStats.blockChanceContribution or 0)
near(R:BlockChance(attacker),math.min(.33,base+math.max(0,p.derivedStats.strMod)/100))
E:Unequip(state,'left_arm');E:RefreshDerived(attacker,attacker.ps);near(R:BlockChance(attacker),0)
E:Equip(state,shield.id,'left_arm');p.classId='rogue';p.equipmentKey=nil;E:RefreshDerived(attacker,attacker.ps)
near(R:BlockChance(attacker),p.equipmentBlockChanceContribution+(p.derivedStats.blockChanceContribution or 0))
-- Auto-collection of copies, full bags, all-family trash and native adapters.
local carrier=env.actor('carrier')
function carrier:StripWeapon(class) self.weapons[class]=nil end
local bag=E:Ensure(carrier.ps)
local first=E:NewItem(carrier,'weapon_357','first')
local second=E:NewItem(carrier,'weapon_357','second')
assert(E:AcquireWorldItem(carrier,first,false,'pickup'))
assert(E:AcquireWorldItem(carrier,second,false,'pickup'))
assert(not carrier:HasWeapon('weapon_357') and bag.items[first.id] and bag.items[second.id])
assert(E:InventoryWeapon(carrier,first.id,false))
assert(not E:DiscardOwned(carrier,first.id),'Equipped item cannot be trashed')
assert(E:DiscardOwned(carrier,second.id) and carrier:HasWeapon('weapon_357'))
assert(E:InventoryWeapon(carrier,first.id,true))
assert(E:DiscardOwned(carrier,first.id) and not carrier:HasWeapon('weapon_357'))
E:Sync(carrier);assert(not bag.items[first.id],'Sync cannot resurrect the trashed native gun')
local spare=E:NewItem(carrier,'vest','spare')
assert(E:AcquireWorldItem(carrier,spare,false,'pickup'));assert(E:DiscardOwned(carrier,spare.id))
E:AddConsumable(bag,'healing_potion',3);E:Unequip(bag,'throwable');assert(E:DiscardOwned(carrier,'healing_potion'))
local capacity=E.MaximumStoredEquipment;E.MaximumStoredEquipment=0
assert(not E:AcquireWorldItem(carrier,second,false,'pickup') and not bag.items[second.id])
E.MaximumStoredEquipment=capacity
assert(E:AcquireWorldItem(carrier,second,false,'pickup'),'Freeing capacity permits the same untouched drop')
-- Death clears the entire run bag/slots and derived effects, retaining progression.
E:AddConsumable(state,'healing_potion',2)
local saved=p;local level=p.level
E:LoseOnDeath(attacker,attacker.ps)
assert(next(attacker.ps.equipment.items)==nil and next(attacker.ps.equipment.slots)==nil)
assert(next(attacker.ps.inventory.weapons)==nil and next(attacker.ps.inventory.ammo)==nil)
assert(attacker.ps.progressionState==saved and saved.level==level and not saved.equipmentShieldEquipped)
for _,n in pairs(saved.equipmentAbilityDelta) do assert(n==0) end
local newer=E:NewItem(attacker,'shield','shield');assert(newer.id~=shield.id,'New life cannot reuse stale equipment identity')

-- Real near-look selection, including obstructed, side and cloaked targets.
dofile(root..'sh_near_look.lua')
local candidates={};local obstruction=false
function attacker:EyePos() return Vector() end
function attacker:EyeAngles() return {Forward=function() return Vector(1,0,0) end} end
function attacker:GetEyeTrace() return {} end
function target:GetPos() return self.pos or Vector(100,3,0) end
function target:WorldSpaceCenter() return self:GetPos() end
function target:GetNoDraw() return self.hidden end
function target:GetNW2Float(k,f) return self.nw[k] or f end
ents=ents or {}
ents.FindInCone=function() return candidates end
util.TraceLine=function() return {Hit=obstruction} end
candidates={target}
assert(LOD.NearLook:Find(attacker,512,function() return true end)==target)
obstruction=true;assert(not LOD.NearLook:Find(attacker,512,function() return true end));obstruction=false
target.pos=Vector(100,30,0);assert(not LOD.NearLook:Find(attacker,512,function() return true end))
target.pos=Vector(600,0,0);assert(not LOD.NearLook:Find(attacker,512,function() return true end))
target.pos=nil;assert(LOD.NearLook:Qualifies(attacker,target,512))
target.pos=Vector(100,30,0);assert(not LOD.NearLook:Qualifies(attacker,target,512))
target.pos=nil;target.nw.LOD_Watcher=true;target.nw.LOD_WatcherInvisibleUntil=CurTime()+1
assert(not LOD.NearLook:Find(attacker,512,function() return true end))
target.nw.LOD_WatcherInvisibleUntil=0
assert(not LOD.NearLook:Find(attacker,512,function() return false end))
print('LOOT_CLASS_REFRESH_PASS: backstab 2x/3x/4x and once-per-event geometry; shield-only STR Block; death loss; near-look cone/LOS/cloak')

-- Frozen statue rendering, bounded shared mesh and optional light budget.
ENT={};include=function() end
Material=function(v) return v end;CreateMaterial=function(v) return v end
local clock,low,builds,sprites,lights=0,false,0,0,0
CurTime=function() return clock end;EyePos=function() return Vector() end
GetConVar=function() return {GetBool=function() return low end} end
Matrix=function() return {SetTranslation=function() end,SetAngles=function() end,SetScale=function() end} end
render={SetMaterial=function() end,DrawSprite=function() sprites=sprites+1 end}
cam={PushModelMatrix=function() end,PopModelMatrix=function() end}
Mesh=function() return {BuildFromTriangles=function(_,v) builds=builds+1;assert(#v==96) end,Draw=function() end,Destroy=function() end} end
DynamicLight=function() lights=lights+1;return {} end
local statue={cycles={},pos=Vector()}
function statue:GetNW2Int() return 4 end
function statue:GetNW2Float() return .35 end
function statue:SetSequence(n) assert(n==4) end
function statue:SetPlaybackRate(n) assert(n==0) end
function statue:SetCycle(n) self.cycles[#self.cycles+1]=n end
function statue:SetupBones() end
function statue:DrawModel() end
function statue:GetPos() return self.pos end
function statue:GetAngles() return {} end
function statue:LocalToWorld(p) return p end
function statue:EntIndex() return 42 end
dofile('gamemodes/legend_of_deborah/entities/entities/lod_debbie_statue/cl_init.lua')
for i=1,120 do clock=i/60;ENT.Draw(statue) end
assert(builds==1 and sprites==240 and lights<=20)
for _,cycle in ipairs(statue.cycles) do assert(cycle==.35) end
local before=lights;low=true;clock=5;ENT.Draw(statue);assert(lights==before)
statue.pos=Vector(2000,0,0);local draws=sprites;ENT.Draw(statue);assert(sprites==draws)
print('HOLY_STATUE_PASS: fixed sequence/cycle; one cached 32-triangle stone wing mesh; distance/quality/light limits')
