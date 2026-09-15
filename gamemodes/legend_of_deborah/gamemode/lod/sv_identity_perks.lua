LOD = LOD or {}
LOD.IdentityPerkDirector = LOD.IdentityPerkDirector or {}
local Director = LOD.IdentityPerkDirector
local ABILITIES = {"str", "dex", "con", "int", "wis", "cha"}
local SLOTS = {"origin", "background", "motive"}
local FAMILIES = {"FAVORED_WEAPON", "FAVORED_ENEMY", "ABILITY_BONUS"}
-- Canonical permanent ability contribution; duplicate targets stack.
Director.AbilityBonus = 2
Director.Version = "identity-three-handlers-v2"
local ABILITY_COPY = {
    str={name="Strength",home="Foundry Row",job="Freight Handler",practice="lifting heavy loads"},
    dex={name="Dexterity",home="Rooftop Quarter",job="Watch Repairer",practice="working with precise hands"},
    con={name="Constitution",home="Quarry Town",job="Endurance Courier",practice="enduring exhausting shifts"},
    int={name="Intelligence",home="Library District",job="Archive Researcher",practice="solving intricate problems"},
    wis={name="Wisdom",home="Border Watch",job="Trail Scout",practice="noticing what others overlook"},
    cha={name="Charisma",home="Market Square",job="Union Negotiator",practice="winning people over"}
}
local WEAPON_NAMES = {crowbar="Crowbar",pistol="Pistol",shotgun="Shotgun",smg="SMG",magnum="Revolver",ar2="Pulse Rifle"}
local ENEMY_NAMES = {ZOMBIE="Zombie",FAST_ZOMBIE="Fast Zombie",SOLDIER="Soldier",HEADCRAB="Headcrab",ROLLER="Roller"}
local function friendlyName(id)
    local name=tostring(id):match("([^/]+)%.mdl$") or tostring(id)
    return (name:gsub("_"," "):lower():gsub("%a[%w']*",function(word) return word:sub(1,1):upper()..word:sub(2) end))
end
local MODEL_LINEAGES = {
    ["models/zombie/classic.mdl"] = "ZOMBIE",
    ["models/zombie/fast.mdl"] = "FAST_ZOMBIE",
    ["models/combine_soldier.mdl"] = "SOLDIER",
    ["models/player/combine_soldier.mdl"] = "SOLDIER",
    ["models/headcrabclassic.mdl"] = "HEADCRAB",
    ["models/roller.mdl"] = "ROLLER"
}
local function sortedKeys(t)
    local ids = {}; for id in pairs(t) do ids[#ids + 1] = id end
    table.sort(ids); return ids
end
function Director:ModelFamily(config)
    if not config then return nil end
    local model = string.lower(tostring(config.modelLineage or config.baseModel or config.model or ""))
    if model == "" then return nil end
    return MODEL_LINEAGES[model] or model
end
function Director:EnemyFamily(actor)
    if not IsValid(actor) then return nil end
    local rules = LOD.RPGAbilityRules
    local state = rules and rules:ProgressionState(actor)
    if actor:IsPlayer() and (not state or state.actorType ~= "human_soldier") then return nil end
    if not actor:IsPlayer() and not actor.LODHostile then return nil end
    local configs = LOD.Config and LOD.Config.Encounter and LOD.Config.Encounter.Archetypes or {}
    local config = actor.LODConfig or configs[actor.LODArchetypeId or (state and state.archetypeId)]
    local family = self:ModelFamily(config)
    if not family and actor.GetModel then family = self:ModelFamily({model = actor:GetModel()}) end
    actor.EnemyModelFamilyId = family
    return family
end
function Director:TargetRegistries()
    if self.FavoredWeaponTargetRegistry then
        return self.FavoredWeaponTargetRegistry, self.EnemyModelFamilyRegistry
    end
    local weapons, enemies = {}, {}
    for _, profile in pairs(LOD.RPG.PlayerWeaponDamageProfiles) do
        if profile.weaponFamilyId then weapons[profile.weaponFamilyId] = WEAPON_NAMES[profile.weaponFamilyId] or profile.label end
    end
    weapons.crowbar = "Crowbar"
    for _, config in pairs(LOD.Config.Encounter.Archetypes) do
        local family = self:ModelFamily(config)
        if family then enemies[family] = ENEMY_NAMES[family] or friendlyName(family) end
    end
    assert(next(enemies), "identity target registry requires enabled enemy models")
    self.FavoredWeaponTargetRegistry, self.EnemyModelFamilyRegistry = weapons, enemies
    return weapons, enemies
end
function Director:Aggregate(records)
    local weapon, enemy, ability = {}, {}, LOD.RPG.NewAbilityBlock(0)
    for _, record in ipairs(records) do
        local id = record.targetId
        if record.handlerId == "ABILITY_BONUS" then
            -- Legacy records retain their permanent +2; new records explicitly
            -- store either one +2 or two distinct +1 contributions.
            for target,amount in pairs(record.abilityBonuses or {[id]=self.AbilityBonus}) do
                ability[target]=(ability[target] or 0)+amount
            end
        elseif record.handlerId == "FAVORED_WEAPON" then weapon[id] = (weapon[id] or 0) + 1
        elseif record.handlerId == "FAVORED_ENEMY" then enemy[id] = (enemy[id] or 0) + 1
        else error("unknown identity handler") end
    end
    return weapon, enemy, ability
end
function Director:WritePresentation(record)
    local slot,target=record.traitSlot,record.targetName
    if record.handlerId=="ABILITY_BONUS" then
        local names,homes,jobs,practices,amounts={},{},{},{},{}
        for _,id in ipairs(ABILITIES) do
            local amount=record.abilityBonuses[id]
            if amount then
                local c=ABILITY_COPY[id]
                names[#names+1]=c.name;homes[#homes+1]=c.home;jobs[#jobs+1]=c.job;practices[#practices+1]=c.practice
                amounts[#amounts+1]="+"..amount.." "..string.upper(id)
            end
        end
        local talents=table.concat(names," and ")
        record.targetName=table.concat(amounts,", ")
        record.displayName="Ability Bonus — "..record.targetName
        if slot=="origin" then
            record.traitName=table.concat(homes," / ")
            record.flavorText="Growing up around "..table.concat(homes," and ").." meant "..table.concat(practices," and ").."; "..talents:lower().." became second nature."
        elseif slot=="background" then
            record.traitName=table.concat(jobs," & ")
            record.flavorText="Before the labyrinth, you earned your living by "..table.concat(practices," and ")..", developing your "..talents:lower().."."
        else
            record.traitName="Bring Her Home: "..talents
            record.flavorText="Deborah once helped you find your "..talents:lower().."; now you intend to use "..(#names==1 and "it" or "both").." to bring her home."
        end
    elseif record.handlerId=="FAVORED_WEAPON" then
        record.displayName="Favored Weapon — "..target
        if slot=="origin" then
            record.traitName=target.." Range Settlement"
            record.flavorText="In your hometown, "..target.." practice was a family ritual; you learned to make each hit count."
        elseif slot=="background" then
            record.traitName=target.." Instructor"
            record.flavorText="Teaching "..target.." technique for a living left you with a practiced knack for harder hits."
        else
            record.traitName="Deborah's "..target.." Backup"
            record.flavorText="You promised Deborah you would cover her escape; your well-practiced "..target.." is how you mean to keep that promise."
        end
    else
        record.displayName="Favored Enemy — "..target
        if slot=="origin" then
            record.traitName=target.." Quarantine Zone"
            record.flavorText="You grew up behind barricades facing the "..target.." family and learned where those creatures are vulnerable."
        elseif slot=="background" then
            record.traitName=target.." Control Contractor"
            record.flavorText="Paid work against the "..target.." family taught you to exploit its vulnerabilities with whatever weapon was available."
        else
            record.traitName=target.." Vendetta"
            record.flavorText="The "..target.." family has already taken too much from you; rescuing Deborah is your refusal to lose anyone else."
        end
    end
end
function Director:EnsurePackage(package)
    if not package or package.identityPerkVersion == self.Version then return false end
    local weapons, enemies = self:TargetRegistries()
    local targets = {FAVORED_WEAPON = sortedKeys(weapons), FAVORED_ENEMY = sortedKeys(enemies), ABILITY_BONUS = ABILITIES}
    local records = {}
    local legacy=package.identityPerkVersion=="identity-three-handlers-v1" and package.identityPerkRecords
    for i, slot in ipairs(SLOTS) do
        local label = tostring(package.heroIdentityId) .. ":IdentityPerk:" .. slot .. ":" .. package[slot .. "Index"]
        local seed = LOD.Seeds.Derive(package.rosterSeed, label)
        local rng = LOD.RNG.New(seed)
        local handler = FAMILIES[rng:Int(1, #FAMILIES)]
        local target = targets[handler][rng:Int(1, #targets[handler])]
        -- Upgrade existing immutable rolls without changing handler or target.
        if legacy and legacy[i] then handler,target=legacy[i].handlerId,legacy[i].targetId end
        local targetName = handler == "ABILITY_BONUS" and string.upper(target)
            or (handler == "FAVORED_WEAPON" and weapons[target] or enemies[target]) or friendlyName(target)
        records[i] = {traitSlot = slot, traitIndex = package[slot .. "Index"], handlerId = handler,
            targetId = target, targetName = targetName, seed = seed}
        local record=records[i]
        if handler=="ABILITY_BONUS" then
            record.abilityBonuses={[target]=2}
            local shape=LOD.RNG.New(LOD.Seeds.Derive(seed,"ability-shape-v2"))
            if not legacy and shape:Int(1,2)==2 then
                local others={};for _,id in ipairs(ABILITIES) do if id~=target then others[#others+1]=id end end
                record.secondaryTargetId=others[shape:Int(1,#others)]
                record.abilityBonuses={[target]=1,[record.secondaryTargetId]=1}
            end
        end
        self:WritePresentation(record)
    end
    package.identityPerkRecords = records
    package.favoredWeaponStacks, package.favoredEnemyStacks, package.identityAbilityDelta = self:Aggregate(records)
    package.resolvedIdentityPerkIds = {}
    for i, record in ipairs(records) do
        package.resolvedIdentityPerkIds[i] = record.traitSlot .. ":" .. record.handlerId .. ":" .. record.targetId
            ..(record.secondaryTargetId and "+"..record.secondaryTargetId or "")
    end
    package.identityPerkVersion = self.Version
    return true
end
function Director:EnsureState(state)
    if not state or state.actorType ~= "hero" or not state.characterIdentityPackage then return false end
    if not self:EnsurePackage(state.characterIdentityPackage) then return false end
    state.identityAbilityDelta = table.Copy(state.characterIdentityPackage.identityAbilityDelta)
    return true
end
function Director:ActorPackage(actor)
    local rules = LOD.RPGAbilityRules
    local state = rules and rules:ProgressionState(actor)
    if not state or state.actorType ~= "hero" then return nil end
    if self:EnsureState(state) then LOD.CharacterProgressionSystem:_RecomputeProgressionState(state) end
    return state.characterIdentityPackage
end
function Director:Description(record)
    if record.handlerId == "ABILITY_BONUS" then
        local parts={}
        for _,id in ipairs(ABILITIES) do
            local amount=(record.abilityBonuses or {[record.targetId]=self.AbilityBonus})[id]
            if amount then parts[#parts+1]="+"..amount.." "..string.upper(id) end
        end
        return "Permanently grants "..table.concat(parts," and ")..". Counts toward feat qualification. Duplicate perks stack."
    elseif record.handlerId == "FAVORED_WEAPON" then
        return "Favored Weapon: +1 flat damage with " .. record.targetName
            .. " per direct attack per damaged target, after resistance and scaling. Once per shotgun target; excludes supplemental effects. Duplicate perks stack."
    end
    return "Favored Enemy: +1 copy of the attack's primary authored damage die against " .. record.targetName
        .. " model-family enemies. Uses the attack's dice and explosion rules, before resistance and scaling. Once per shotgun target; no bonus without an authored die. Duplicate perks stack."
end
function Director:Snapshot(definition, package, index)
    local record = assert(package.identityPerkRecords[index], "identity record missing")
    return {tableType = definition.tableType, tableIndex = definition.tableIndex,
        categoryName = record.traitName, flavorText = record.flavorText,
        perkDisplayName = record.displayName, mechanicalEffect = self:Description(record),
        handlerId = record.handlerId, targetId = record.targetId, secondaryTargetId=record.secondaryTargetId,
        abilityBonuses=record.abilityBonuses and table.Copy(record.abilityBonuses)}
end
-- Capture the permanent identity and die definition at commitment. A source with
-- mixed dice must declare its primary die; arbitrary damage tables are ineligible.
function Director:SealAttack(contract, actor, rng)
    if contract.profile.identityBonusDie then return end
    local package = self:ActorPackage(actor)
    if not package then return end
    contract.identityWeaponStacks = table.Copy(package.favoredWeaponStacks or {})
    contract.identityEnemyStacks = table.Copy(package.favoredEnemyStacks or {})
    contract.identityDieSeed = rng.state
    contract.primaryAuthoredDamageDie = {}
    for key, value in pairs(contract.profile) do
        if key ~= "attackEvent" then contract.primaryAuthoredDamageDie[key] = value end
    end
    contract.identityTargetViews = setmetatable({}, {__mode = "k"})
end
function Director:TargetContract(contract, actor, target, tags)
    if not contract or not contract.identityTargetViews or not IsValid(target) then return contract end
    local family = self:EnemyFamily(target)
    local count = family and (contract.identityEnemyStacks or {})[family] or 0
    if count <= 0 or not contract.primaryAuthoredDamageDie or not contract.identityDieSeed then return contract end
    local rules = LOD.RPGAbilityRules
    local identity = rules and rules:ProgressionState(target)
    local epoch = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed
    local cached = contract.identityTargetViews[target]
    if cached and cached.identity == identity and cached.epoch == epoch then return cached.contract end
    local profile = {}
    for key, value in pairs(contract.primaryAuthoredDamageDie) do profile[key] = value end
    profile.count, profile.bonus, profile.identityBonusDie = count, 0, true
    profile.attackEvent = contract.attackEvent
    local budget = (LOD.RPG.Constants.MaxDamageDicePerAttackEvent or 128)
    local event = contract.attackEvent or {}
    local used = event.damageDiceUsed or (#contract.values + (event.identityExtraDiceUsed or 0))
    local remaining = math.max(0, budget - used)
    if remaining <= 0 then return contract end
    profile.rollLimit = remaining
    local seed = LOD.Seeds.Derive(contract.identityDieSeed, "favored-enemy:" .. target:EntIndex())
    local extra = LOD.CombatRolls:RollActorDamage(actor, profile, LOD.RNG.New(seed), 0)
    -- Copy only roll arrays: preserve event/source identity and all shared observers.
    local view = {}
    for key, value in pairs(contract) do view[key] = value end
    view.originContract = contract.originContract or contract
    for _, key in ipairs({"values", "contributions", "thresholds", "chainStarts"}) do view[key] = table.Copy(contract[key] or {}) end
    local added = #extra.values
    local offset = #view.values
    view.total = contract.total
    for i = 1, added do
        view.values[offset + i] = extra.values[i]
        view.contributions[offset + i] = extra.contributions[i]
        view.thresholds[offset + i] = extra.thresholds[i]
        view.total = view.total + extra.contributions[i]
    end
    for _, start in ipairs(extra.chainStarts) do
        if start <= added then view.chainStarts[#view.chainStarts + 1] = offset + start end
    end
    if event.damageDiceUsed then event.damageDiceUsed = used + added
    else event.identityExtraDiceUsed = (event.identityExtraDiceUsed or 0) + added end
    view.baseDice = (contract.baseDice or 0) + count
    view.formula = contract.formula .. " + " .. extra.formula .. " favored enemy"
    view.favoredEnemyDice = count
    view.capped = contract.capped or extra.capped or added < #extra.values
    contract.identityTargetViews[target] = {contract = view, identity = identity, epoch = epoch}
    local continuations = math.max(0, added - #extra.chainStarts)
    if continuations > 0 and not profile.magicDamage and LOD.CombatRolls.EmitDiceExplosionFX then
        LOD.CombatRolls:EmitDiceExplosionFX(actor, contract.weaponClass or profile.weaponFamilyId or "", continuations, 1)
    end
    return view
end
function Director:WeaponBonus(contract, tags, amount)
    if amount <= 0 or not contract then return 0 end
    tags = tags or {}
    if tags.wallCrush or tags.environmental or tags.nonAttack or tags.statusDamage or tags.passiveDamage
        or tags.reactiveDamage or tags.auraBurst or tags.personalityAura then return 0 end
    local family = contract.profile and contract.profile.weaponFamilyId
    return family and (contract.identityWeaponStacks or {})[family] or 0
end
