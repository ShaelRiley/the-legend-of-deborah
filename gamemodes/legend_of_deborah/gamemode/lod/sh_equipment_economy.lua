-- LOD-EQUIP-016. One versioned generator for weapons and wearable equipment.
-- Version 1 records retain their original validator/value; never reroll owned gear.
local E = assert(LOD.Equipment)
local legacyValidate, legacyValue, legacyDescription = E.ValidateWearable, E.Value, E.Description
local acquire = E.AcquireWearable
E.EconomyVersion, E.ScalingDungeonCap = 2, 999
E.WeaponLoot = {variantChance=.5}
E.WeaponFamilies = {"weapon_pistol", "weapon_lod_crowbar", "weapon_shotgun", "weapon_smg1", "weapon_357", "weapon_ar2"}
local weaponNames = {"Pistol", "Crowbar", "Shotgun", "SMG", "Revolver", "Pulse Rifle"}
local weaponModels = {"w_pistol", "w_crowbar", "w_shotgun", "w_smg1", "w_357", "w_irifle"}
for i, class in ipairs(E.WeaponFamilies) do
    E.Definitions[class] = {name=weaponNames[i], weapon=true, weaponClass=class, slots={class},
        model="models/weapons/"..weaponModels[i]..".mdl"}
    E.SlotOrder[#E.SlotOrder+1], E.SlotLabels[class] = class, weaponNames[i]
end
-- Innate techniques are authoritative definition grants, not permanent feats.
-- Generic/frozen records retain their existing IDs, properties and valuation.
E.SpecialMoves.psychic_crush = {id="psychic_crush", name="Psychic Crush", displayName="Psychic Crush",
    recipe={"DOWN","UP","DOWN"}, glyphs="↓ ↑ ↓", magicCost=18, cooldown=4,
    value=50, family="psychic_crown", innateOnly=true, effect="nearest", offensive=true,
    cells=2, damageDice=2, damageSides=8, saveAbility="wis",
    description="Crush the nearest visible, reachable enemy within two cells for 2d8 + WIS Magic; WIS save halves damage."}
E.MoveOrder[#E.MoveOrder+1] = "psychic_crush"
E.Definitions.psychic_crown = {name="Crown of Psychic Crushing", wearable=true, slots={"head"},
    model="models/props_junk/cardboard_box004a.mdl", moves={"psychic_crush"}, minimumRarity=2}
E.SpecialMoves.ember_fist = {id="ember_fist", name="Ember Fist", displayName="Ember Fist",
    recipe={"LEFT","DOWN","RIGHT"}, glyphs="← ↓ →", magicCost=12, cooldown=2,
    value=35, family="fighting_gloves", innateOnly=true, effect="projectile", offensive=true,
    damageDice=2, damageSides=6, projectile={form="bolt",speed=1200,range=1920,lifetime=1.6},
    description="Launch a straight fireball up to 1920 units: 2d6 + WIS Magic, using these gloves' element and its normal Content rider. No splash; cover stops it."}
E.SpecialMoves.cinder_rise = {id="cinder_rise", name="Cinder Rise", displayName="Cinder Rise",
    recipe={"RIGHT","DOWN","RIGHT"}, glyphs="→ ↓ →", magicCost=18, cooldown=4,
    value=45, family="fighting_gloves", innateOnly=true, effect="strike", offensive=true,
    cells=0, damageDice=2, damageSides=8, rider="immolated",
    description="Rising strike in your current square: 2d8 + WIS Magic using these gloves' element; surviving damaged enemies attempt the normal Immolated save. Cover blocks it; no Hero displacement."}
E.MoveOrder[#E.MoveOrder+1] = "ember_fist"
E.MoveOrder[#E.MoveOrder+1] = "cinder_rise"
E.Definitions.fighting_gloves = {name="Gloves of the Fighting Streets", wearable=true,
    slots={"left_hand","right_hand"}, occupancy={"left_hand","right_hand"}, budgetMultiplier=2,
    model="models/props_junk/cardboard_box004a.mdl", moves={"ember_fist","cinder_rise"}, minimumRarity=2}
-- Preserve the original generator's random-family stream for recorded rewards.
-- Newly rolled world rewards opt into innate families on a separate substream.
E.SpecialMoves.veil = {id="veil", name="Veil", displayName="Veil",
    recipe={"LEFT","UP","LEFT"}, glyphs="← ↑ ←", magicCost=20, cooldown=20, duration=12,
    value=50, family="invisibility_ring", innateOnly=true, effect="cloak",
    description="Invisible for up to 12 seconds. Attack input, Magic, throwing, or dealing/taking HP damage reveals you. Removing this ring ends Veil; hazards still hurt."}
E.MoveOrder[#E.MoveOrder+1] = "veil"
E.Definitions.invisibility_ring = {name="Ring of Invisibility", wearable=true,
    slots={"left_hand","right_hand"}, model="models/props_junk/cardboard_box004a.mdl",
    moves={"veil"}, minimumRarity=2}
E.SpecialMoves.thunder_charge = {id="thunder_charge", name="Thunder Charge", displayName="Thunder Charge",
    recipe={"UP","DOWN","UP"}, glyphs="↑ ↓ ↑", magicCost=24, cooldown=6,
    value=60, family="thunder_hat", innateOnly=true, effect="charge", offensive=true,
    element="electric", damageDice=2, damageSides=8, hitStunMultiplier=1, distance=1152, duration=.8, warning=.25,
    description="Warn for 0.25s, then charge straight up to three blocks. First enemy contact: 2d8 + WIS electric Magic and eligible hit-stun. Actors, walls, locks and unsafe floors stop you. No steering or invulnerability."}
E.MoveOrder[#E.MoveOrder+1] = "thunder_charge"
E.Definitions.thunder_hat = {name="Hat of the Thunder God", wearable=true, slots={"head"},
    model="models/props_junk/cardboard_box004a.mdl", moves={"thunder_charge"}, minimumRarity=2}
E.InnateFamilyOrder = {"psychic_crown", "fighting_gloves", "invisibility_ring", "thunder_hat"}
function E:RewardWearableFamily(seed)
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed,"equipment-innate-family-v1"))
    return rng:Chance(.125) and rng:Pick(self.InnateFamilyOrder) or nil
end

function E:InnateValue(family, quality)
    local total=0
    for _,id in ipairs(self.Definitions[family] and self.Definitions[family].moves or {}) do
        total=total+self.SpecialMoves[id].value
    end
    return math.floor(total*(quality or 100)/100)
end
E.Rarities = {
    {name="Unusual", threshold=6500, factor=100, affixes=4},
    {name="Rare", threshold=9000, factor=120, affixes=5},
    {name="Exalted", threshold=9900, factor=145, affixes=6},
    {name="Legendary", threshold=10000, factor=175, affixes=7}
}
E.EconomyOrder, E.EconomyProperties = {}, {}
local function property(id, def)
    def.id, def.precision = id, def.precision or 10
    E.EconomyOrder[#E.EconomyOrder+1], E.EconomyProperties[id] = id, def
end
local abilityNames = {str="Might",dex="Finesse",con="Fortitude",int="Insight",wis="Wisdom",cha="Charm"}
for _, ability in ipairs(E.Abilities) do
    property("ability_"..ability, {ability=ability, label=string.upper(ability), epithet=abilityNames[ability],
        maximum=12, half=100, precision=1, negative=true})
    property("save_"..ability, {save=ability, label=string.upper(ability)..(ability=="str" and " Push saves" or " condition saves"), epithet=abilityNames[ability].." Warding",
        maximum=6, half=100, precision=1, negative=true})
end
local numeric = {
    {"physical", "Physical damage", "Force", 60,80}, {"magic", "Magic damage", "Sorcery",60,80},
    {"movement", "Movement speed", "Swiftness",25,100}, {"dodge", "Dodge contribution", "Evasion",20,150},
    {"defense", "Physical damage reduction", "Protection",25,120},
    {"regen_ceiling", "Health regeneration ceiling", "Mending",50,100},
    {"regen_rate", "Health regeneration rate", "Recovery",100,80},
    {"magic_regen", "Magic regeneration rate", "Renewal",100,80},
    {"push_out", "Outgoing Push distance", "Shoving",50,80},
    {"push_resist", "Incoming Push reduction", "Anchoring",50,80},
    {"map_efficiency", "Map drain reduction", "Cartography",35,80},
    {"summon_duration", "Summon lifetime", "Enduring Servants",50,100},
    {"injured", "Physical damage while at/below half HP", "Last Stands",50,80},
    {"still", "Physical damage while moving below 5 units/s", "Patience",50,80},
    {"charged", "Magic damage while at/above 75 Magic", "Reserves",50,80}
}
for _, row in ipairs(numeric) do
    property(row[1], {stat=row[1], label=row[2], epithet=row[3], maximum=row[4], half=row[5],
        unit="%", negative=row[1]~="regen_ceiling" and row[1]~="dodge"})
end
property("breadcrumb", {stat="breadcrumb", label="Breadcrumb cells",epithet="Wayfinding",maximum=12,half=80,precision=1})
property("block", {stat="block",label="Block contribution",epithet="Guarding",maximum=33,half=120,unit="%",family="shield"})
property("summon_cap", {stat="summon_cap",label="Active summon capacity",epithet="Command",fixed=1,cost=45,precision=1})
E.ElementOrder = {"earth","fire","dark","ice","light","electric"}
local adjectives = {earth="Earthly",fire="Fiery",dark="Umbral",ice="Wintery",light="Radiant",electric="Crackling"}
for _, element in ipairs(E.ElementOrder) do
    property("element_"..element, {element=element,label=element.." damage",epithet=adjectives[element],qualifier=adjectives[element],
        maximum=50,half=80,unit="%",group="element"})
    property("ward_"..element, {ward=element,label=element.." resistance",epithet=adjectives[element].." Warding",fixed=1,cost=25,group="ward:"..element})
    property("weak_"..element, {weakness=element,label=element.." weakness",epithet=adjectives[element].." Frailty",fixed=1,cost=15,drawbackOnly=true,group="ward:"..element})
end
E.RiderOrder = {"clumsy","immolated","poisoned","bleeding","muted","held","reckless","arcane_shattered","intimidated","push"}
local riderNames = {clumsy="Stumbling",immolated="Burning",poisoned="Poisoning",bleeding="Bloodletting",muted="Silence",
    held="Holding",reckless="Recklessness",arcane_shattered="Shattering",intimidated="Dread",push="Repulsion"}
for _, id in ipairs(E.RiderOrder) do
    property("proc_"..id, {rider=id,label=id.." attempt on weapon hit",epithet=riderNames[id],maximum=25,half=100,unit="%"})
end
for _, id in ipairs(E.MoveOrder) do
    local move=E.SpecialMoves[id]
    if not move.innateOnly then
        property("move_"..id, {move=id,label=move.name,epithet=move.name,fixed=1,cost=move.value,family=move.family})
    end
end

local function finite(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
function E:Budget(level, family, rarity, quality)
    local d=finite(level) and math.floor(level) or 1
    d=math.max(1,math.min(self.ScalingDungeonCap,d))
    local base=100+math.floor(12*math.sqrt(d-1)+4*math.log(d)/math.log(2))
    local multiplier=self.Definitions[family] and self.Definitions[family].budgetMultiplier or (family=="gloves" and 2 or 1)
    return math.floor(base*multiplier*(self.Rarities[rarity or 1].factor/100)*(quality or 100)/100)+self:InnateValue(family,quality)
end
function E:Magnitude(def, power)
    if def.fixed then return def.fixed end
    return math.max(1/def.precision, math.floor(def.maximum*power/(def.half+power)*def.precision+.5)/def.precision)
end
function E:RecordDefinition(item, record)
    return (item.version==2 and self.EconomyProperties or self.Properties)[record.id]
end
function E:Value(item)
    if not item or item.version~=2 then return legacyValue(self,item) end
    local positive,negative=0,0
    for _,r in ipairs(item.properties or {}) do
        if r.amount>0 then positive=positive+r.power else negative=negative+r.power end
    end
    return positive-math.min(negative,math.floor(item.budget*.2))+self:InnateValue(item.definitionId,item.quality)
end
function E:ValidateWearable(item)
    if not item or item.version~=2 then
        local definition=self:Definition(item)
        if definition and definition.moves then return false end
        -- The old validator refers to self:Budget; bind its original schedule.
        local proxy=setmetatable({Budget=function(_,d,f)
            return (10+2*math.floor((math.max(1,math.min(100,math.floor(tonumber(d) or 1)))-1)/5))*(f=="gloves" and 2 or 1)
        end}, {__index=self})
        return legacyValidate(proxy,item)
    end
    local def=self:Definition(item)
    if not def or not (def.wearable or def.weapon) or item.count~=1 or type(item.id)~="string"
        or #item.id>220 or not finite(item.dungeonLevel) or item.dungeonLevel<1
        or item.dungeonLevel>self.ScalingDungeonCap or item.dungeonLevel%1~=0
        or not self.Rarities[item.rarity] or item.rarity<(def.minimumRarity or 1) or not finite(item.quality) or item.quality<90 or item.quality>110 or item.quality%1~=0
        or item.budget~=self:Budget(item.dungeonLevel,item.definitionId,item.rarity,item.quality)
        or type(item.properties)~="table" or #item.properties~=self.Rarities[item.rarity].affixes+1 then return false end
    local used, groups, positive, negative, elements, riders={},{},0,0,0,0
    for _,r in ipairs(item.properties) do
        local p=self.EconomyProperties[r.id]
        if not p or used[r.id] or p.group and groups[p.group] or p.family and p.family~=item.definitionId
            or not finite(r.power) or r.power%1~=0 or r.power<1 or r.power>item.budget*1.2
            or not finite(r.amount) or r.amount==0 or math.abs(r.amount)~=self:Magnitude(p,r.power)
            or p.fixed and r.power~=p.cost then return false end
        used[r.id]=true; if p.group then groups[p.group]=true end
        if r.amount<0 then
            if not p.negative and not p.drawbackOnly then return false end
            negative=negative+1
        else
            if p.drawbackOnly then return false end
            positive=positive+1
            if p.element then elements=elements+1 end
            if p.rider then riders=riders+1 end
        end
    end
    return negative==1 and positive==self.Rarities[item.rarity].affixes and elements==1
        and (not def.weapon or riders>=1) and self:Value(item)==item.budget
end

function E:Generate(seed, level, requestedFamily, contextId)
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed,"equipment-v2:"..tostring(contextId or "preview")))
    local family=requestedFamily or rng:Pick(self.FamilyOrder)
    local def=self.Definitions[family]
    if not def or not (def.wearable or def.weapon) then return nil end
    local rarityRoll,rarity=rng:Int(1,10000),1
    for i,r in ipairs(self.Rarities) do if rarityRoll<=r.threshold then rarity=i;break end end
    rarity=math.max(rarity,def.minimumRarity or 1)
    local d=math.max(1,math.min(self.ScalingDungeonCap,math.floor(tonumber(level) or 1)))
    local item={version=2,id="gear2:"..tostring(contextId or seed)..":"..family,definitionId=family,count=1,
        seed=seed,dungeonLevel=d,rarity=rarity,quality=rng:Int(90,110),properties={}}
    item.budget=self:Budget(d,family,rarity,item.quality)
    local used,groups={},{}
    local function add(id,power,sign)
        local p=self.EconomyProperties[id]
        item.properties[#item.properties+1]={id=id,power=power,amount=self:Magnitude(p,power)*(sign or 1)}
        used[id]=true;if p.group then groups[p.group]=true end
    end
    -- One real drawback; no opposing properties or unlimited curse refunds.
    local negatives={}
    for _,id in ipairs(self.EconomyOrder) do local p=self.EconomyProperties[id]
        if (p.negative or p.drawbackOnly) and (not p.family or p.family==family) then negatives[#negatives+1]=id end
    end
    local drawback=rng:Pick(negatives);local dp=self.EconomyProperties[drawback]
    local refund=dp.fixed and dp.cost or math.floor(item.budget*rng:Int(10,20)/100)
    add(drawback,refund,-1)
    local remaining=item.budget-self:InnateValue(family,item.quality)+math.min(refund,math.floor(item.budget*.2))
    local function choose(id)
        local p=self.EconomyProperties[id]; local power=p.fixed and p.cost or 6
        add(id,power);remaining=remaining-power
    end
    choose("element_"..rng:Pick(self.ElementOrder))
    if def.weapon then choose("proc_"..rng:Pick(self.RiderOrder)) end
    while #item.properties<self.Rarities[rarity].affixes+1 do
        local choices={}
        for _,id in ipairs(self.EconomyOrder) do local p=self.EconomyProperties[id]
            if not used[id] and not p.drawbackOnly and (not p.group or not groups[p.group])
                and (not p.family or p.family==family) and (p.fixed and p.cost or 6)<=remaining-6*(self.Rarities[rarity].affixes-#item.properties) then
                choices[#choices+1]=id
            end
        end
        choose(assert(rng:Pick(choices),"Equipment budget cannot fund its mandatory affixes"))
    end
    local flexible,totalWeight={},0
    for _,r in ipairs(item.properties) do if r.amount>0 and not self.EconomyProperties[r.id].fixed then
        local weight=rng:Int(100,1000); flexible[#flexible+1]={record=r,weight=weight};totalWeight=totalWeight+weight
    end end
    local available=remaining
    for _,entry in ipairs(flexible) do
        local extra=math.floor(available*entry.weight/totalWeight)
        entry.record.power=entry.record.power+extra;remaining=remaining-extra
    end
    -- Assign rounding residue once, then derive all magnitudes from authoritative power.
    local first=flexible[1].record; first.power=first.power+remaining
    for _,entry in ipairs(flexible) do local r=entry.record;r.amount=self:Magnitude(self.EconomyProperties[r.id],r.power) end
    local names=LOD.RNG.New(LOD.Seeds.Derive(seed,"equipment-v2-names:"..tostring(contextId or "preview")))
    item.provenance=names:Pick({"Deborah's","Neil's","Hermit's","Wayfarer's","Dockworker's","Warden's","Pilgrim's","Cartographer's"})
    local qualifier,signature
    for _,r in ipairs(item.properties) do local p=self.EconomyProperties[r.id]
        if r.amount>0 and p.element then qualifier=p.qualifier end
        if r.amount>0 and p.rider and not signature then signature=p.epithet end
    end
    if not signature then for _,r in ipairs(item.properties) do local p=self.EconomyProperties[r.id]
        if r.amount>0 and not p.element then signature=p.epithet;break end
    end end
    local secondary={}
    for _,r in ipairs(item.properties) do local p=self.EconomyProperties[r.id]
        if r.amount>0 and not p.element and p.epithet~=signature then secondary[#secondary+1]=p.epithet end
    end
    item.name=item.provenance.." "..qualifier.." "..def.name.." of "..signature
        ..(#secondary>0 and " and "..names:Pick(secondary) or "")
    assert(self:ValidateWearable(item),"Invalid generated equipment v2")
    return item
end

-- The reward corpus crashes in upstream LuaJIT 2.0.4 when compiled. The
-- September 17 x64 GMod dump also faults inside lua_shared while Generate is
-- active, reporting LuaJIT 2.1.0-beta3 and generation mode "default". A version
-- number is not a safe capability test for engine-specific LuaJIT builds.
-- Interpret this bounded, low-frequency generator and its nested closures on
-- every LuaJIT. Keep the global compiler, shared RNG and combat paths enabled;
-- preserve every RNG draw and item field. Apply once when the function loads,
-- never toggle global JIT state per reward. See docs/GENERATOR_CRASH_REPAIR_20260917.md.
E.GenerationExecutionMode = "default"
if jit and type(jit.off) == "function" then
    jit.off(E.Generate, true)
    E.GenerationExecutionMode = "interpreter-generator"
end
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts.equipment_generator = "generator-jit-20260917-01"

function E:Description(item, compact)
    if not item or item.version~=2 then return legacyDescription(self,item,compact) end
    local out={self.Rarities[item.rarity].name.." · Dungeon "..item.dungeonLevel}
    for _,id in ipairs(self:Definition(item).moves or {}) do
        local m=self.SpecialMoves[id]
        out[#out+1]=m.name.." "..m.glyphs.." / "..m.magicCost.." Magic / "..m.cooldown.."s"..(compact and "" or " — "..m.description)
    end
    for _,r in ipairs(item.properties) do
        local p=self.EconomyProperties[r.id]
        if p.move then local m=self.SpecialMoves[p.move]
            out[#out+1]=m.name.." "..m.glyphs.." / "..m.magicCost.." Magic / "..m.cooldown.."s"..(compact and "" or " — "..m.description)
        elseif p.ward or p.weakness then out[#out+1]=p.label.." (shared 11–88% ladder)"
        else out[#out+1]=p.label..string.format(" %+.1f%s",r.amount,p.unit or "") end
    end
    if self:Definition(item).weapon then out[#out+1]="Active weapon only; damage has the named element" end
    if not compact then out[#out+1]="Wintery = Ice. Hit chances attempt normal saves; up to two riders per target/attack. Gear totals use shared caps." end
    return table.concat(out,"; ")
end

function E:Contributions(state)
    local abilities,moves,block,seen,extras={},{},0,{},{}
    for _,a in ipairs(self.Abilities) do abilities[a]=0 end
    for _,slot in ipairs(self.SlotOrder) do
        local item,id=self:Equipped(state,slot)
        local def=self:Definition(item)
        if item and not seen[id] and (not def.weapon or state.activeWeaponClass==def.weaponClass) then
            seen[id]=true
            for _,move in ipairs(def.moves or {}) do moves[move]=true end
            for _,r in ipairs(item.properties or {}) do
                local p=self:RecordDefinition(item,r)
                if p then
                    if p.ability then abilities[p.ability]=abilities[p.ability]+r.amount
                    elseif p.move then moves[p.move]=true
                    elseif r.id=="block" then block=block+r.amount/100
                    else extras[r.id]=(extras[r.id] or 0)+r.amount end
                end
            end
        end
    end
    return abilities,moves,math.min(self.BlockCap,math.max(0,block)),extras
end

function E:StoredEquipmentCount(state)
    local stored=0
    for _,owned in pairs(state and state.items or {}) do
        local def=self:Definition(owned)
        if def and (def.wearable or def.weapon) then stored=stored+1 end
    end
    return stored
end
function E:CanStore(state,item,slot)
    if not state or not self:Placement(state,item,slot) then return false end
    return self:StoredEquipmentCount(state)<self:StorageCapacity(state)
end
function E:AcquireWearable(state,item,accept,slot)
    if not self:CanStore(state,item,slot) then return false end
    return acquire(self,state,item,accept,slot)
end

function E:Discard(state,id)
    local item=state and state.items[id]
    local def=self:Definition(item)
    if not def or def.essential or def.protected or item.bound then return false end
    for _,value in pairs(state.slots) do
        if value==id and (not def.weapon or state.activeWeaponClass==def.weaponClass) then return false end
    end
    self:UnequipItem(state,id)
    state.items[id]=nil
    return true
end
