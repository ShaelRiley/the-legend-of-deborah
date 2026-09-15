-- Acquisition and aggregate adapters; combat/status/movement remain shared authorities.
local E,Run,Rules=assert(LOD.Equipment),assert(LOD.RunManager),assert(LOD.RPGAbilityRules)
local CPS,Status=assert(LOD.CharacterProgressionSystem),assert(LOD.RPGStatusElements)
local function hero(ply)
    if not IsValid(ply) or not ply:IsPlayer() or Run:IsSoldierControl(ply) then return nil end
    return Run:GetPlayerState(ply)
end
local function bounded(t,id,lo,hi) return math.Clamp(tonumber(t and t[id]) or 0,lo,hi) end
function E:Extras(actor)
    local state=Rules:ProgressionState(actor)
    return state and state.equipmentExtras or {}
end
function E:ApplyDerived(state,d)
    local x=state.equipmentExtras or {}
    d.equipmentExtras=x
    d.dodgeChanceContribution=(d.dodgeChanceContribution or 0)+bounded(x,"dodge",0,33)/100
    local ceiling=bounded(x,"regen_ceiling",0,60)/100
    d.healthRegenCeilingFraction=math.min(1,(d.healthRegenCeilingFraction or 0)+ceiling)
    if ceiling>0 then
        d.healthRegenEnabled=true
        d.healthRegenDamageFreeDelaySeconds=d.healthRegenDamageFreeDelaySeconds or 5
        d.healthRegenBaseMaxHPPerSecond=math.max(.01,d.healthRegenBaseMaxHPPerSecond or 0)
    end
    d.healthRegenBaseMaxHPPerSecond=(d.healthRegenBaseMaxHPPerSecond or 0)*(1+bounded(x,"regen_rate",-50,100)/100)
    d.breadcrumbCells=math.Clamp((d.breadcrumbCells or 6)+bounded(x,"breadcrumb",0,24),2,24)
    d.mapDrainFeatMultiplier=(d.mapDrainFeatMultiplier or 1)*(1-bounded(x,"map_efficiency",-35,35)/100)
end
local recompute=CPS._RecomputeProgressionState
function CPS:_RecomputeProgressionState(state)
    local result=recompute(self,state)
    if state and state.derivedStats then E:ApplyDerived(state,state.derivedStats) end
    return result
end
function E:RefreshDerived(ply,ps)
    if not ps or not ps.progressionState or Run:IsSoldierControl(ply) then return end
    local state=self:Ensure(ps)
    local weapon=IsValid(ply) and ply:GetActiveWeapon() or nil
    state.activeWeaponClass=IsValid(weapon) and weapon:GetClass() or nil
    local signature={state.activeWeaponClass or ""}
    for _,slot in ipairs(self.SlotOrder) do signature[#signature+1]=state.slots[slot] or "" end
    local key=table.concat(signature,"|")
    local p=ps.progressionState
    if p.equipmentKey==key then return end
    local a,_,block,x=self:Contributions(state)
    p.equipmentKey,p.equipmentAbilityDelta,p.equipmentBlockChanceContribution,p.equipmentExtras=key,a,block,x
    CPS:_RecomputeProgressionState(p)
    CPS:_ApplyPlayerMaxHP(ply,p)
    CPS:SyncPlayer(ply)
end
local movement=Rules.MovementMultiplier
function Rules:MovementMultiplier(actor)
    return movement(self,actor)*(1+bounded(E:Extras(actor),"movement",-25,35)/100)
end
local regen=Rules.MagicRegenMultiplier
function Rules:MagicRegenMultiplier(actor)
    return regen(self,actor)*(1+bounded(E:Extras(actor),"magic_regen",-50,100)/100)
end
local save=Status.ConditionSave
function Status:ConditionSave(target,ability,rng)
    local result,natural=save(self,target,ability,rng)
    return result+bounded(E:Extras(target),"save_"..ability,-6,6),natural
end
local morale=Status.MoraleSave
function Status:MoraleSave(target,rng,disadvantage)
    local result,natural,naturals=morale(self,target,rng,disadvantage)
    return result+bounded(E:Extras(target),"save_cha",-6,6),natural,naturals
end
local maxSummons=LOD.MagicProgression.MaxActiveSummons
function LOD.MagicProgression:MaxActiveSummons(state)
    return math.min(6,maxSummons(self,state)+bounded(state and state.equipmentExtras,"summon_cap",0,2))
end

function E:RewardKey(owner,source)
    local run=Run.State or {}
    return tostring(run.RunId or run.CampaignSeed or 1)..":"..tostring(run.LevelSeed or 1)..":"..tostring(owner)..":"..tostring(source)
end
function E:NewItem(ply,class,source)
    local ps=hero(ply);if not ps then return nil end
    local state=self:Ensure(ps)
    if not source then state.serial=(state.serial or 0)+1;source="grant:"..state.serial end
    local key=self:RewardKey(ps.identity or Run:IdentityOf(ply),source)
    return self:Generate(LOD.Seeds.Derive(Run.State.CampaignSeed or 1,key),Run.State.Level or 1,class,key)
end
function E:EnsureWeapon(ply,class)
    local ps=hero(ply);local def=self.Definitions[class]
    if not ps or not def or not def.weapon then return nil end
    local state=self:Ensure(ps)
    local current=self:Equipped(state,class)
    if current then return current end
    -- Re-equipping a stored record does not generate another item.
    for id,item in pairs(state.items) do if item.definitionId==class then self:Equip(state,id,class);return item end end
    local item=self:NewItem(ply,class,"initial:"..class)
    if item then state.items[item.id]=item;self:Equip(state,item.id,class) end
    return item
end
function E:StampWeapons(ply)
    if not hero(ply) then return end
    for _,class in ipairs(self.WeaponFamilies) do
        local weapon=ply:GetWeapon(class)
        if IsValid(weapon) then
            local item=self:EnsureWeapon(ply,class)
            weapon:SetNW2String("LOD_ItemName",self:ItemName(item))
        end
    end
end
-- The saved record is on character state, never solely on an engine entity.
local sync=E.Sync
function E:Sync(ply) self:StampWeapons(ply);return sync(self,ply) end
hook.Add("PlayerCanPickupWeapon","LOD_EquipmentInventoryCapacity",function(ply,weapon)
    local ps=hero(ply)
    if not ps or not IsValid(weapon) then return end
    local class=weapon:GetClass();local def=E.Definitions[class]
    if def and def.weapon and not E:CanStore(E:Ensure(ps),{definitionId=class,count=1}) then return false end
end)
hook.Add("WeaponEquip","LOD_ProceduralWeaponRecord",function(weapon,ply)
    local ps=hero(ply)
    if not ps or not IsValid(weapon) then return end
    E:EnsureWeapon(ply,weapon:GetClass())
    timer.Simple(0,function() if IsValid(ply) and hero(ply)==ps then E:Sync(ply) end end)
end)
-- Check the actual weapon, including SetActiveWeapon/restore paths; switch-intent
-- hooks can be cancelled and cannot be the ownership/stat authority.
hook.Add("PlayerPostThink","LOD_ProceduralActiveWeapon",function(ply)
    local ps=hero(ply);if not ps or not ply:Alive() then return end
    local weapon=ply:GetActiveWeapon()
    local class=IsValid(weapon) and weapon:GetClass() or nil
    local state=E:Ensure(ps)
    if state.activeWeaponClass~=class then E:Sync(ply) end
end)

local grantWeapon=LOD.LootDirector._GrantWeapon
local missingWeapon=LOD.LootDirector._MissingWeaponReward
function LOD.LootDirector:_MissingWeaponReward(ply,rng)
    return missingWeapon(self,ply,rng) or rng:Pick({"weapon_shotgun","weapon_smg1","weapon_357","weapon_ar2"})
end
function E:AcquireWorldItem(ply,item,accept)
    local ps=hero(ply)
    if not ps or not self:CanAct(ply) or not self:ValidateWearable(item) then return false end
    local state=self:Ensure(ps)
    if not self:CanStore(state,item) then return false end
    local slot,displaced=self:Placement(state,item)
    if not slot or state.items[item.id] or #displaced>0 and not accept then return false end
    local def=self:Definition(item)
    if def.weapon and not IsValid(ply:GetWeapon(def.weaponClass)) then
        -- Preserve all existing class-specific magazine/cap adapters. Suppress
        -- initial-record creation during this transaction so a grant cannot
        -- occupy a previously empty slot before AcquireWearable checks it.
        local before=table.Copy(state)
        local ok=grantWeapon(LOD.LootDirector,ply,def.weaponClass,LOD.RNG.New(item.seed))
        ps.equipment=before;state=before
        if not ok then return false end
        -- An existing item whose engine weapon was dropped is not a fresh
        -- magazine entitlement. Ordinary restore supplies its saved clips.
        if #displaced>0 then ply:GetWeapon(def.weaponClass):SetClip1(0) end
    end
    if not self:AcquireWearable(state,item,accept) then return false end
    self:Sync(ply)
    return true,self:ItemName(item).." equipped — "..self:Description(item,true)
end
function E:CollectWearable(ent,ply,accept)
    return self:AcquireWorldItem(ply,ent.LODLootPayload and ent.LODLootPayload.item,accept)
end
function LOD.LootDirector:_GrantWeapon(ply,class,rng)
    if not hero(ply) or not E.Definitions[class] then return grantWeapon(self,ply,class,rng) end
    return E:AcquireWorldItem(ply,E:NewItem(ply,class),true)
end
function E:PrepareReward(owner,kind,payload,options)
    options=options or {};payload=payload or {}
    local source=options.staticId or options.equipmentSeed
    if not source then
        Run.State.equipmentRewardSerial=(Run.State.equipmentRewardSerial or 0)+1
        source="world:"..Run.State.equipmentRewardSerial
    end
    local key=self:RewardKey(owner,source)
    local seed=LOD.Seeds.Derive(Run.State.CampaignSeed or 1,key)
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed,"equipment-conversion-v2"))
    if kind=="consumable" and payload.itemId=="healing_potion" and options.equipmentEligible and rng:Chance(.2) then
        return "consumable",{itemId="stink_bomb"}
    end
    if kind~="weapon" and kind~="cache" then return kind,payload end
    if options.equipmentEligible and rng:Chance(.35) then
        return "wearable",{item=self:Generate(seed,Run.State.Level or 1,nil,key)}
    end
    if kind=="cache" then return kind,payload end
    if not self.Definitions[payload.weaponClass] then return kind,payload end
    return "wearable",{item=self:Generate(seed,Run.State.Level or 1,payload.weaponClass,key)}
end

-- Do not allow the inventory UI to detach properties while retaining the gun.
-- Native weapon selection controls which stored weapon's contribution is active.
local unequip=E.Unequip
function E:Unequip(state,slot)
    if self.Definitions[slot] and self.Definitions[slot].weapon then return false end
    return unequip(self,state,slot)
end

function E:CaptureAttack(actor,weapon)
    local ps=hero(actor)
    if not ps then return nil end
    if weapon then self:EnsureWeapon(actor,weapon) end
    self:RefreshDerived(actor,ps)
    local item=weapon and self:Equipped(ps.equipment,weapon) or nil
    local snapshot={extras=table.Copy(ps.progressionState.equipmentExtras or {}),
        derived=table.Copy(ps.progressionState.derivedStats),weapon=weapon,itemId=item and item.id,
        ownerIdentity=ps.identity,runId=Run.State.RunId,levelSeed=Run.State.LevelSeed,
        injured=actor:Health()<=actor:GetMaxHealth()*.5,
        still=actor:GetVelocity():Length2D()<5,charged=(ps.magic or 0)>=75,dc={}}
    if item then for _,r in ipairs(item.properties) do local p=self:RecordDefinition(item,r)
        if p and p.element then snapshot.element=p.element end
    end end
    for id,def in pairs(Status.Registry) do snapshot.dc[id]=Status:ConditionDC(actor,def.ability) end
    snapshot.origin=actor:GetPos()
    return snapshot
end
function E:SealWeaponAttack(actor,contract,class)
    if not contract then return end
    local event=contract.attackEvent
    if type(event)=="table" and event.equipmentSnapshot then contract.equipmentSnapshot=event.equipmentSnapshot;return end
    contract.equipmentSnapshot=self:CaptureAttack(actor,class)
    if type(event)=="table" then event.equipmentSnapshot=contract.equipmentSnapshot end
end
function E:PrepareDamageTags(contract,attacker,tags)
    local snapshot=contract and (contract.equipmentSnapshot
        or contract.originContract and contract.originContract.equipmentSnapshot
        or contract.attackEvent and contract.attackEvent.equipmentSnapshot)
    if not snapshot then return end
    tags.equipmentSnapshot=snapshot
    if snapshot.weapon and tags.physical and snapshot.element then tags.element=snapshot.element end
end
function E:DamageMultiplier(sourceDerived,targetDerived,tags)
    local snapshot=tags.equipmentSnapshot
    local x=snapshot and snapshot.extras or {}
    local amount=1
    if tags.statusDamage or tags.passiveDamage or tags.auraBurst or tags.reactiveDamage or tags.environmental then return amount end
    if tags.physical then
        amount=amount*(1+bounded(x,"physical",-35,75)/100)
        if snapshot and snapshot.injured then amount=amount*(1+bounded(x,"injured",-35,50)/100) end
        if snapshot and snapshot.still then amount=amount*(1+bounded(x,"still",-35,50)/100) end
        amount=amount*(1-bounded(targetDerived and targetDerived.equipmentExtras,"defense",-35,35)/100)
    elseif tags.magic then
        amount=amount*(1+bounded(x,"magic",-35,75)/100)
        if snapshot and snapshot.charged then amount=amount*(1+bounded(x,"charged",-35,50)/100) end
    end
    if tags.element then amount=amount*(1+bounded(x,"element_"..tags.element,0,50)/100) end
    return amount
end

function E:PostDamage(target,info,taken)
    if not taken or not IsValid(target) or target.LODDead or target:Health()<=0 or info:GetDamage()<=0 then return end
    local context=Status:DamageContext(info,target)
    local contract=context.damageContract
    local snapshot=contract and (contract.equipmentSnapshot or contract.originContract and contract.originContract.equipmentSnapshot)
    local attacker=info:GetAttacker()
    if not snapshot or not snapshot.weapon or not context.physical or context.statusDamage or context.magic or context.passiveDamage
        or context.auraBurst or context.reactiveDamage or context.dodged or context.blocked
        or not hero(attacker) or hero(attacker).identity~=snapshot.ownerIdentity or not E:CanAct(attacker) or Run.State.RunId~=snapshot.runId
        or Run.State.LevelSeed~=snapshot.levelSeed or attacker==target then return end
    if not LOD.FactionManager or not LOD.FactionManager:IsOpponent(attacker,target) then return end
    local event=contract.attackEvent or contract
    event.equipmentTargets=event.equipmentTargets or setmetatable({}, {__mode="k"})
    if event.equipmentTargets[target] then return end
    event.equipmentTargets[target]=true
    local rng=LOD.CombatRolls:_RNG("equipment-riders:"..target:EntIndex())
    local candidates={}
    for _,id in ipairs(self.RiderOrder) do if (snapshot.extras["proc_"..id] or 0)>0 then candidates[#candidates+1]=id end end
    rng:Shuffle(candidates)
    local attempts=0
    for _,id in ipairs(candidates) do
        local chance=bounded(snapshot.extras,"proc_"..id,0,35)/100
        local roll=rng:Float();local result="missed chance"
        if roll<chance then
            attempts=attempts+1
            if id=="intimidated" then
                local _,reason=Status:AttemptMorale(attacker,target,{forceMorale=true});result=reason or "Morale attempted"
            elseif id=="push" then
                local applied=LOD.Pushback:Apply(target,{attacker=attacker,origin=snapshot.origin,distance=96,source="equipment"})
                result=applied and "Push resolved" or "Push rejected"
            else local _,reason=Status:Apply(target,id,attacker,{dc=snapshot.dc[id]});result=reason or "attempted" end
        end
        LOD.CombatRolls:_Send(attacker,3,string.format("EQUIPMENT %s — %.1f%% roll / %.1f%% chance: %s",id,roll*100,chance*100,result),
            "status",{event="equipment_rider",status=id,chance=chance,roll=roll,outcome=result})
        if attempts>=2 then break end
    end
end
hook.Add("PostEntityTakeDamage","LOD_EquipmentHitRiders",function(target,info,taken) E:PostDamage(target,info,taken) end)
