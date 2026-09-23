-- Production equipment, queue selection, slot admission and revival. Only native
-- bodies, transport and deferred engine ticks are doubles.
local env = dofile('tools/test_equipment_economy_runtime.lua')
local root = 'gamemodes/legend_of_deborah/gamemode/lod/'
local E, R = LOD.Equipment, env.Run
local now, pending, actors = 200, {}, {}
CurTime = function() return now end
timer.Simple = function(_, fn) pending[#pending+1] = fn end
local function flush()
    local list = pending; pending = {}
    for _, fn in ipairs(list) do fn() end
end
player.GetAll = function() return actors end
CreateConVar = function(_, value) return {GetInt=function() return tonumber(value) or 0 end} end
dofile(root..'sv_human_soldier_progression.lua')
dofile(root..'sv_run_manager.lua')
dofile(root..'sv_multiplayer_hardening.lua')
dofile(root..'sv_resurrection_feather.lua')
local function actor(id)
    local p = env.actor(id)
    p.SteamID64 = function() return id end
    p.Nick = function() return id end
    p.UnSpectate = function(self) self.spectating = false end
    p.Spectate = function(self) self.spectating = true end
    p.SpectateEntity = function() end
    p.SetPos = function() end
    p.StripWeapons = function(self) self.weapons = {} end
    p.Spawn = function(self)
        self.spawns = (self.spawns or 0)+1; self.hp = 100
        self.LODRunSpawnSerial = (self.LODRunSpawnSerial or 0)+1
    end
    p.GetNW2String = function(self,k,d) return self.nw[k] or d end
    actors[#actors+1] = p
    return p
end
local owner, first, second = actor('owner'), actor('first'), actor('second')
local function setup()
    pending = {}; now = now+2
    R.State = {CampaignSeed=73,LevelSeed=7,Level=1,BuildReady=true,Graph={},CharacterOrder={},
        ActiveIdentity={owner=true},WaitingSince={},PlayedIdentities={},PlayerState={}}
    for i,p in ipairs(actors) do
        p.valid=true;p.hp=100;p.spawns=0;p.LODHumanSoldierProgressionState=nil
        p.ps.lives = p==owner and 3 or 0
        p.ps.eliminated = p~=owner;p.ps.queue='hero';p.ps.respawnAt=nil;p.ps.soldierRespawnWait=nil
        p.ps.eliminatedSince = 100;p.ps.ordinal=i;p.ps.deploymentComplete=true
        R.State.PlayerState[p.id]=p.ps;R.State.PlayedIdentities[p.id]=true
    end
    first.hp, second.hp=0,0
    owner.ps.equipment=nil; E.NextUse[owner]=nil
    assert(E:Grant(owner,'resurrection_feather',3))
    assert(E:Equip(owner.ps.equipment,'resurrection_feather','throwable'))
    assert(E:Activate(owner))
    return owner.ps.equipment
end
local function count()
    local item=owner.ps.equipment.items.resurrection_feather
    return item and item.count or 0
end
local function noSpend()
    local n=count(); assert(not E:Use(owner,'throw'));assert(count()==n)
end
setup()
local progression,inventory,equipment=first.ps.progressionState,{weapons={'saved'}},{items={saved=true}}
first.ps.inventory, first.ps.equipment=inventory,equipment
local magic=owner.ps.magic
assert(E:Use(owner,'throw'));assert(count()==2 and first.ps.lives==1 and not first.ps.eliminated)
assert(second.ps.lives==0 and first.spawns==0,'Ordinal tie-break; native spawn deferred')
assert(first.ps.progressionState==progression and first.ps.inventory==inventory and first.ps.equipment==equipment)
assert(owner.ps.magic==magic and E.NextUse[owner]==now+.6)
noSpend();flush();assert(first.spawns==1 and R:IsActivePlayer(first))
assert(not R:ReviveIdentity('first'),'Repeated revival cannot mint lives')
now=now+1;assert(E:Use(owner,'drink'));flush()
assert(count()==1 and second.ps.lives==1 and second.spawns==1)
now=now+1;noSpend();assert(count()==1,'Empty queue costs nothing')

setup(); second.ps.eliminatedSince=99
assert(E:Use(owner,'drink'));assert(second.ps.lives==1 and first.ps.lives==0,'Timestamp precedes ordinal')

setup();first.ps.queue='soldier';second.ps.soldierRespawnWait=true
noSpend()
first.ps.queue='hero';first.ps.respawnAt=now+20;noSpend()
first.ps.respawnAt=nil;first.ps.lives=1;first.ps.eliminated=false;noSpend()
first.ps.lives=0;first.ps.eliminated=true;first.hp=100
first.LODHumanSoldierProgressionState={actorType="human_soldier",soldierIncarnation=true};noSpend()
assert(R:ReturnToHeroQueue(first));assert(first.ps.eliminatedSince==100)
assert(not R:IsSoldierControl(first) and first.LODRunInventoryReady==false)
assert(E:Use(owner,'throw'));flush();assert(first.spawns==1,'Alive former Soldier spectator gets a Hero body')

setup();local consume=E.Consume
E.Consume=function() return false end
noSpend();assert(first.ps.lives==0 and first.ps.eliminated and not R:IsActivePlayer(first) and #pending==0)
E.Consume=consume
local calls=0
assert(not R:ReviveIdentity('owner',function() calls=calls+1;return true end) and calls==0,
    'Ineligible revival cannot invoke debit')

for _,blocked in ipairs({'dead','inactive','soldier','unheld','empty','failed','cleared','frozen','building','timeout'}) do
    setup()
    if blocked=='dead' then owner.hp=0
    elseif blocked=='inactive' then R.State.ActiveIdentity.owner=nil
    elseif blocked=='soldier' then owner.LODHumanSoldierProgressionState={actorType="human_soldier",soldierIncarnation=true}
    elseif blocked=='unheld' then owner.activeClass='weapon_lod_crowbar'
    elseif blocked=='empty' then E:Consume(owner.ps.equipment,'resurrection_feather');E:Consume(owner.ps.equipment,'resurrection_feather');E:Consume(owner.ps.equipment,'resurrection_feather')
    elseif blocked=='failed' then R.State.Failed=true
    elseif blocked=='cleared' then R.State.LevelCleared=true
    elseif blocked=='frozen' then R.State.SimulationFrozen=true
    elseif blocked=='building' then R.State.BuildReady=false
    elseif blocked=='timeout' then LOD.CampaignTimeout={Expire=function() return true end} end
    noSpend();assert(first.ps.lives==0,blocked)
    LOD.CampaignTimeout=nil
end

-- Slot admission and disconnected identities are still owned by RunManager.
setup();R.State.ActiveIdentity.a=true;R.State.ActiveIdentity.b=true;R.State.ActiveIdentity.c=true
assert(E:Use(owner,'drink'));assert(first.ps.lives==1 and not R:IsActivePlayer(first) and first.spawns==0)
R.State.ActiveIdentity.a=nil
assert(R:PromoteWaitingSpectators()==1 and first.spawns==1 and first.ps.lives==1)
setup();first.valid=false
assert(E:Use(owner,'throw'));assert(first.ps.lives==1 and first.spawns==0)
first.valid=true;assert(R:PromoteWaitingSpectators()==1)
assert(first.spawns==1 and first.ps.lives==1)
R:ReleasePlayer(first);assert(R:TryActivatePlayer(first));assert(first.ps.lives==1,'Reconnect never grants another life')

for _,stale in ipairs({'campaign','graph','level','identity','body','death','disconnect','failed','cleared','soldier'}) do
    setup();assert(E:Use(owner,'throw'))
    if stale=='campaign' then R.State=table.Copy(R.State)
    elseif stale=='graph' then R.State.Graph={}
    elseif stale=='level' then R.State.LevelSeed=8
    elseif stale=='identity' then R.State.PlayerState.first=table.Copy(first.ps)
    elseif stale=='body' then first.LODRunSpawnSerial=(first.LODRunSpawnSerial or 0)+1
    elseif stale=='death' then first.ps.lives=0;first.ps.eliminated=true
    elseif stale=='disconnect' then first.valid=false
    elseif stale=='failed' then R.State.Failed=true
    elseif stale=='cleared' then R.State.LevelCleared=true
    elseif stale=='soldier' then first.LODHumanSoldierProgressionState={actorType="human_soldier",soldierIncarnation=true} end
    flush();assert(first.spawns==0,stale..' must suppress stale spawn');assert(count()==2)
end

setup();local state=owner.ps.equipment
assert(not E:AddConsumable(state,'resurrection_feather',1) and count()==3)
assert(E:Consume(state,'resurrection_feather'));assert(E:Consume(state,'resurrection_feather'))
assert(E:Use(owner,'drink') and count()==0 and not state.slots.throwable)
assert(not E:IsActive(owner),'Last Feather releases throwable controls')
assert(E:Prompt(E.Definitions.resurrection_feather)=='LMB / RMB: RESURRECT HERO')

setup();local cards,feathers=0,0
for i=1,256 do
    local source='feather-proof-'..i
    local seed=LOD.Seeds.Derive(R.State.CampaignSeed,E:RewardKey('owner',source))
    local card=LOD.RNG.New(LOD.Seeds.Derive(seed,'summon-card-v1')):Chance(1/8)
    local feather=LOD.RNG.New(LOD.Seeds.Derive(seed,'resurrection-feather-v1')):Chance(1/8)
    local options={equipmentEligible=true,staticId=source}
    local _,a=E:PrepareReward('owner','consumable',{itemId='healing_potion'},options)
    local _,b=E:PrepareReward('owner','consumable',{itemId='healing_potion'},options)
    assert(a.itemId==b.itemId)
    if card then assert(a.itemId=='summon_card');cards=cards+1
    elseif feather then assert(a.itemId=='resurrection_feather');feathers=feathers+1
    else assert(a.itemId~='resurrection_feather' and a.itemId~='summon_card') end
    local _,fixed=E:PrepareReward('owner','consumable',{itemId='healing_potion'},{staticId=source})
    assert(fixed.itemId=='healing_potion','Authored rewards preserved')
end
assert(cards>0 and feathers>0)
print('RESURRECTION_FEATHER_PASS: atomic debit, both controls, queue order, Soldier exclusion/return, slots/reconnect, stale callbacks, inventory preservation and seeded rewards')
