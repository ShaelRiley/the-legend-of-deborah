-- Production progression, loot acquisition, damage, saves and status delegates.
-- Only Source entities/transport and deterministic die results are test doubles.
dofile('tools/test_checkpoint_d_closure.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,CPS,Rules,Status=LOD.Equipment,LOD.CharacterProgressionSystem,LOD.RPGAbilityRules,LOD.RPGStatusElements
local hooks,timers={},{}
hook.Add=function(event,id,fn) hooks[id]=fn end
hook.Remove=function(event,id) hooks[id]=nil end
hook.Run=function() end
timer.Simple=function(_,fn) timers[#timers+1]=fn end
net.Start=function() end;net.WriteTable=function() end;net.Send=function() end
local now=100;CurTime=function() return now end
IsValid=function(x) return type(x)=='table' and x.valid==true end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
function V:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function V:DistToSqr(b) return (self.x-b.x)^2+(self.y-b.y)^2+(self.z-b.z)^2 end
vector_origin=Vector()
local Run={State={RunId='test-run',CampaignSeed=73,LevelSeed=7,Level=51},ApplyPlayerState=function() end}
function Run:GetPlayerState(p) return type(p)=='table' and p.ps or self.State.PlayerState[p] end
function Run:IdentityOf(p) return p.id end
function Run:IsActivePlayer(p) return p.active~=false end
function Run:IsSoldierControl(p) return p.soldier end
LOD.RunManager=Run;LOD.MazeBuilder={}
scripted_ents={GetStored=function() end}
LOD.RPGPresentation={Event=function() end}
local function actor(id,enemy)
    local p={valid=true,id=id,hp=100,max=100,weapons={},nw={},ammo={},velocity=Vector(),LODHostile=enemy}
    function p:IsPlayer() return not self.LODHostile end
    function p:Alive() return self.hp>0 end
    function p:Health() return self.hp end
    function p:GetMaxHealth() return self.max end
    function p:SetMaxHealth(v) self.max=v end
    function p:SetHealth(v) self.hp=v end
    function p:GetPos() return Vector() end
    function p:GetVelocity() return self.velocity end
    function p:OnGround() return true end
    function p:KeyDown() return false end
    function p:EntIndex() return enemy and 2 or 1 end
    function p:GetActiveWeapon() return self.weapons[self.activeClass] end
    function p:GetWeapon(c) return self.weapons[c] end
    function p:HasWeapon(c) return self.weapons[c]~=nil end
    function p:GetAmmoCount(c) return self.ammo[c] or 0 end
    function p:SetAmmo(v,c) self.ammo[c]=v end
    function p:SelectWeapon(c) self.activeClass=c end
    function p:EmitSound() end
    function p:ChatPrint() end
    function p:SetNW2String(k,v) self.nw[k]=v end
    p.SetNW2Int,p.SetNW2Float,p.SetNW2Bool=p.SetNW2String,p.SetNW2String,p.SetNW2String
    function p:GetNW2Bool(k,default) local v=self.nw[k];if v==nil then return default end;return v end
    function p:GetNW2Float(k,default) return self.nw[k] or default end
    function p:Give(c)
        if self.failGive then return nil end
        local w={valid=true,class=c,clip=0,nw={},owner=self}
        function w:GetOwner() return self.owner end
        function w:GetClass() return self.class end
        function w:SetClip1(v) self.clip=v end
        function w:Clip1() return self.clip end
        function w:SetNW2String(k,v) self.nw[k]=v end
        self.weapons[c]=w
        if hooks.LOD_ProceduralWeaponRecord then hooks.LOD_ProceduralWeaponRecord(w,self) end
        return w
    end
    local state=CPS:NewProgressionState(id,enemy and 'shambler' or 'hero',enemy and 'ai' or 'hero')
    state.classId='fighter';state.baseAbilities=LOD.RPG.NewAbilityBlock(10)
    p.ps={identity=id,magic=100,progressionState=state};p.LODProgressionState=state
    CPS:_RecomputeProgressionState(state)
    return p
end
local owner,target=actor('owner'),actor('enemy',true)
Run.State.PlayerState={owner=owner.ps}
local SyncOriginal=CPS.SyncPlayer
CPS.SyncPlayer=function() end -- network snapshot only
dofile(root..'sv_loot_director.lua');dofile(root..'sv_equipment.lua');dofile(root..'sv_equipment_wearables.lua')
dofile(root..'sv_equipment_economy.lua')
local Loot=LOD.LootDirector
local function pickup(item,source)
    return {valid=true,LODLootOwnerIdentity='owner',LODLootLevelSeed=Run.State.LevelSeed,LODLootKind='wearable',
        LODLootStaticId=source,LODLootPayload={item=item}}
end
local a=E:NewItem(owner,'weapon_357','drop-a');local ent=pickup(a,'drop-a')
owner.failGive=true
assert(Loot:Collect(ent,owner,false),'Automatic bag pickup needs no native Give')
assert(ent.LODCollected and owner.ps.equipment.items[a.id] and not owner:GetWeapon('weapon_357'))
assert(not E:InventoryWeapon(owner,a.id,false),'Failed native materialization leaves stored item intact')
assert(owner.ps.equipment.items[a.id])
owner.failGive=false
assert(E:InventoryWeapon(owner,a.id,false))
local weapon=owner:GetWeapon('weapon_357');weapon.clip=2;owner.ammo['357']=9
local b=E:NewItem(owner,'weapon_357','drop-b');local replacement=pickup(b,'drop-b')
assert(Loot:Collect(replacement,owner,false),'Touch stores duplicate weapon without a decision')
assert(E:Equipped(owner.ps.equipment,'weapon_357').id==a.id,'Pickup does not replace equipped roll')
assert(E:InventoryWeapon(owner,b.id,false),'Select a stored copy')
assert(weapon.clip==2 and owner.ammo['357']==9,'Same-family selection cannot replenish ammo')
assert(owner.ps.equipment.items[a.id] and E:Equipped(owner.ps.equipment,'weapon_357').id==b.id)
assert(not Loot:Collect(pickup(b,'drop-b'),owner,true),'Consumed reward replay rejected')

-- Player:Give publishes WeaponEquip before the native weapon is fully settled.
-- The production capacity gate must not inspect a protected starter weapon, and
-- procedural record creation must wait until the next tick.
local settling=actor('settling');Run.State.PlayerState.settling=settling.ps
settling.LODStarterNativeGrant='weapon_smg1'
local unsafe={valid=true,GetClass=function() error('capacity inspected unsettled starter weapon') end}
assert(hooks.LOD_EquipmentInventoryCapacity(settling,unsafe)==true)
local pendingBefore=#timers
settling:Give('weapon_smg1')
settling.LODStarterNativeGrant=nil
assert(#timers==pendingBefore+1 and not settling.ps.equipment,
    'procedural WeaponEquip work ran inside native Give')
local settle=table.remove(timers)
settle()
assert(E:Equipped(settling.ps.equipment,'weapon_smg1'),
    'deferred procedural weapon record did not settle')

local copy=table.Copy(owner.ps.equipment)
owner.weapons['weapon_357']=nil;owner:Give('weapon_357');E:Sync(owner)
assert(E:Equipped(owner.ps.equipment,'weapon_357').id==copy.slots.weapon_357,'Weapon restoration retains item roll')
for _,class in ipairs(E.WeaponFamilies) do owner:Give(class) end
E:Sync(owner)
for _,class in ipairs(E.WeaponFamilies) do assert(E:ValidateWearable(E:Equipped(owner.ps.equipment,class))) end
local weaponCount=0;for _,item in pairs(owner.ps.equipment.items) do if E:Definition(item).weapon then weaponCount=weaponCount+1 end end
assert(weaponCount==7,'Repeated Give preserves the two acquired copies, never creates extra records')
-- Network synchronization must not repeat aggregation of unchanged equipment.
local aggregate,aggregations=E.Contributions,0
function E:Contributions(...) aggregations=aggregations+1;return aggregate(self,...) end
owner.ps.progressionState.equipmentKey=nil
E:Sync(owner)
for _=1,100 do E:Sync(owner) end
assert(aggregations==1,'Unchanged synchronization skips property aggregation')
owner:SelectWeapon('weapon_pistol');E:Sync(owner)
assert(aggregations==2,'Weapon change immediately refreshes derived stats')
E.Contributions=aggregate

assert(Loot:_MissingWeaponReward(owner,LOD.RNG.New(1)),'Owning all families must still allow new variants')
local level=Run.State.LevelSeed;Run.State.LevelSeed=8
assert(not Loot:Collect(pickup(E:NewItem(owner,'boots','stale'),'stale'),target,true),'Foreign owner rejected')
Run.State.LevelSeed=level
-- Active stats use exactly one gun plus worn gear; switching does not heal.
owner.activeClass='weapon_357';E:Sync(owner)
local expected=E:Contributions(owner.ps.equipment)
for _,ability in ipairs(E.Abilities) do assert(owner.ps.progressionState.equipmentAbilityDelta[ability]==expected[ability]) end
owner.hp=20;owner.activeClass='weapon_pistol';E:Sync(owner);assert(owner.hp<=20)
owner.activeClass='weapon_lod_throwable';E:Sync(owner)
for _,value in pairs(owner.ps.progressionState.equipmentAbilityDelta) do assert(value==0,'Holstered guns must not stack') end
-- Shared stat authorities, positive and negative contributions, caps, no accumulation.
local state=owner.ps.progressionState
state.equipmentExtras={dodge=100,regen_ceiling=80,regen_rate=50,magic_regen=50,breadcrumb=99,map_efficiency=20,summon_cap=9,save_wis=99}
CPS:_RecomputeProgressionState(state)
local d=state.derivedStats
assert(d.dodgeChanceContribution>=.33 and d.healthRegenEnabled and d.healthRegenCeilingFraction<=1)
assert(d.breadcrumbCells==24 and LOD.MagicProgression:MaxActiveSummons(state)==3)
local rate=d.healthRegenBaseMaxHPPerSecond
CPS:_RecomputeProgressionState(state);assert(state.derivedStats.healthRegenBaseMaxHPPerSecond==rate,'No repeated stat accumulation')
local save,natural=Status:ConditionSave(owner,'wis',{Int=function() return 10 end})
assert(save==natural+6,'Gear contributes once to the real condition save')
state.equipmentExtras={save_wis=-99};CPS:_RecomputeProgressionState(state)
save,natural=Status:ConditionSave(owner,'wis',{Int=function() return 10 end});assert(save==natural-6)
state.equipmentExtras={ward_fire=1};CPS:_RecomputeProgressionState(state)
local amount,result=Status:ResolveElementDamage(100,target,owner,{element='fire'},{Int=function() return 8 end})
assert(math.abs(amount-12)<.001 and result.kind=='resistance')
state.equipmentExtras.weak_fire=-1
amount,result=Status:ResolveElementDamage(100,target,owner,{element='fire'},{Int=function() return 8 end})
assert(amount==188 and result.kind=='weakness','One weakness ladder takes priority over all matching wards')
-- Sealed weapon attack includes active stat source and conditional states.
owner.activeClass='weapon_357';state.equipmentKey=nil;E:Sync(owner)
local contract={values={10},contributions={10},bonus=0,attackEvent={}}
E:SealWeaponAttack(owner,contract,'weapon_357')
local snapshot=contract.equipmentSnapshot
owner.activeClass='weapon_pistol';E:Sync(owner)
local tags={physical=true,damageContract=contract};E:PrepareDamageTags(contract,owner,tags)
assert(tags.element==snapshot.element and tags.equipmentSnapshot==snapshot)
local total=Rules:ResolveDamageContract(contract,owner,target,tags)
assert(total>0)
local split={originContract=contract,values={10},contributions={10},attackEvent=contract.attackEvent}
local splitTags={physical=true};E:PrepareDamageTags(split,owner,splitTags)
assert(splitTags.equipmentSnapshot==snapshot,'Magnum continuation uses original gear')
local cast=LOD.MagicForms:_NewContext(owner,{id='bolt'},nil)
assert(cast.equipmentSnapshot and not cast.equipmentSnapshot.weapon,'Magic seals stats without becoming a weapon hit')
-- Exercise the actual firearm contract producer, not just hand-built tags.
dofile(root..'sv_combat_rolls.lua')
LOD.CombatRolls.Stats.playerAttacks=0
owner.activeClass='weapon_357';E:Sync(owner)
local event={}
local first=LOD.CombatRolls:RollPlayerWeapon(owner,'weapon_357',event)
assert(first.attackEvent==event and first.equipmentSnapshot==event.equipmentSnapshot)
owner.activeClass='weapon_pistol';E:Sync(owner)
local nextRound=LOD.CombatRolls:RollPlayerWeapon(owner,'weapon_357',event)
assert(nextRound.equipmentSnapshot==first.equipmentSnapshot,'Burst shares a sealed item snapshot')
assert(nextRound.profile.rpgDerived==first.equipmentSnapshot.derived,'Burst dice use sealed gear-derived stats')
local neutralTags={physical=true}
local resolved=LOD.CombatRolls:ResolveActorDamage(first,owner,target,neutralTags)
assert(resolved>0 and neutralTags.element==first.equipmentSnapshot.element,'Real damage resolver sees weapon type and modifiers')
-- Production chance loop -> real Held status/save. No duplicate, filtered,
-- corpse, blocked, friendly, old-dungeon, Soldier, or recursive applications.
local rolls={}
LOD.CombatRolls._RNG=function() return {Float=function() return 0 end,Shuffle=function(_,t) return t end} end
LOD.CombatRolls._Send=function(_,_,_,text) rolls[#rolls+1]=text end
LOD.FactionManager={IsOpponent=function(_,a,b) return a==owner and b==target end}
Status._RNG=function() return {Int=function(_,lo) return lo end} end
snapshot.extras={proc_held=100};snapshot.dc.held=100
local info={value=10}
function info:GetDamage() return self.value end
function info:GetAttacker() return owner end
Status:AttachDamageContext(info,{physical=true,damageContract=contract})
E:PostDamage(target,info,false);assert(not Status:Has(target,'held'))
E:PostDamage(target,info,true);assert(Status:Has(target,'held'),'Real Held is applied through shared save/scheduler')
assert(#rolls==1);E:PostDamage(target,info,true);assert(#rolls==1,'One attempt per target/event')
Status:Clear(target,'held','test')
contract.attackEvent={};Status:DamageContext(info).blocked=true
E:PostDamage(target,info,true);assert(not Status:Has(target,'held'))
Status:DamageContext(info).blocked=nil
Run.State.LevelSeed=8;E:PostDamage(target,info,true);assert(not Status:Has(target,'held'));Run.State.LevelSeed=7
owner.soldier=true;E:PostDamage(target,info,true);assert(not Status:Has(target,'held'));owner.soldier=false
Status:DamageContext(info).statusDamage=true;E:PostDamage(target,info,true);assert(not Status:Has(target,'held'))
Status:DamageContext(info).statusDamage=nil
target.hp=0;E:PostDamage(target,info,true);assert(not Status:Has(target,'held'));target.hp=100
snapshot.dc.held=-100;E:PostDamage(target,info,true);assert(not Status:Has(target,'held'),'Chance success never bypasses save')
-- All natural gun payloads are procedural, with stable per-source identities.
local wearable,gun=0,0
for i=1,1000 do
    local kind,payload=E:PrepareReward('owner','weapon',{weaponClass='weapon_smg1'},{staticId=i,equipmentEligible=true})
    assert(kind=='wearable' and E:ValidateWearable(payload.item))
    if E:Definition(payload.item).weapon then gun=gun+1 else wearable=wearable+1 end
    local _,again=E:PrepareReward('owner','weapon',{weaponClass='weapon_smg1'},{staticId=i,equipmentEligible=true})
    assert(again.item.id==payload.item.id and again.item.name==payload.item.name)
end
assert(wearable>280 and wearable<420 and gun+wearable==1000)
local _,mandatory=E:PrepareReward('owner','weapon',{weaponClass='weapon_smg1'},{staticId='mandatory'})
assert(mandatory.item.definitionId=='weapon_smg1')
-- Capacity refuses before Give. Discard accepts only an owned, unequipped wearable.
local capacity=E.MaximumStoredEquipment;E.MaximumStoredEquipment=6
local fullPickup=pickup(E:NewItem(owner,'boots','full'),'full')
assert(not Loot:Collect(fullPickup,owner,false) and not fullPickup.LODCollected)
owner:SelectWeapon('weapon_pistol');E:Sync(owner)
assert(not E:Discard(owner.ps.equipment,E:Equipped(owner.ps.equipment,'weapon_pistol').id))
E.MaximumStoredEquipment=capacity
local extra=E:NewItem(owner,'boots','bag');owner.ps.equipment.items[extra.id]=extra
assert(E:Discard(owner.ps.equipment,extra.id) and not owner.ps.equipment.items[extra.id])
-- Every advertised ordinary status rider reaches the actual authoritative status API.
for _,id in ipairs(E.RiderOrder) do
    if Status.Registry[id] and id~='intimidated' then
        Status:CureNegative(target)
        snapshot.extras={['proc_'..id]=35};snapshot.dc[id]=100
        contract.attackEvent={};Status:AttachDamageContext(info,{physical=true,damageContract=contract})
        E:PostDamage(target,info,true)
        assert(Status:Has(target,id),'Advertised '..id..' weapon proc never applied')
    end
end
Status:CureNegative(target)
local morale=Status.AttemptMorale;local moraleCalls=0
Status.AttemptMorale=function(_,a,b,context) assert(a==owner and b==target and context.forceMorale);moraleCalls=moraleCalls+1;return false,'saved' end
snapshot.extras={proc_intimidated=35};contract.attackEvent={}
Status:AttachDamageContext(info,{physical=true,damageContract=contract});E:PostDamage(target,info,true)
assert(moraleCalls==1,'Intimidated weapon must invoke shared Morale save');Status.AttemptMorale=morale

print('PROCEDURAL_RUNTIME_PASS: real ownership/Give/deferred native settlement/atomic replacement/ammo preservation/restore; active-only stats; shared save/element/cap authorities; sealed attacks/Magic; real Held/save/duplicate/lifecycle gates; natural reward distribution')
-- Reuse these Source boundaries for the real SQLite wallet integration gate.
return {actor=actor,Run=Run,hooks=hooks,timers=timers}
