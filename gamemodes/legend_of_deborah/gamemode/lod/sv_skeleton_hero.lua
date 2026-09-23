-- LOD-EVENT-SKELETON-001: Hero synthesis, with the existing hostile controllers.
LOD.SkeletonHero = LOD.SkeletonHero or {}
local S = LOD.SkeletonHero
local P, RPG = LOD.CharacterProgressionSystem, LOD.RPG
S.Model = "models/player/skeleton.mdl"
S.Classes = {"fighter", "rogue", "wizard"}
S.Archetypes = {fighter = "runner", rogue = "soldier", wizard = "arccaster"}
S.Colors = {fighter = Color(255, 185, 165), rogue = Color(145, 235, 255), wizard = Color(210, 160, 255)}
S.ArcBaseCost = 12

-- The ordinary draft owns requirements, replacements, weights and selection.
-- Advertise only actions this AI can perform; ownership is never a substitute
-- for an implemented controller. Other actors keep their exact original gates.
local baseCapability = P._HasCapability
function P:_HasCapability(ps, state, tag)
    if state and state.skeletonHero then
        local wizard, rogue = state.classId == "wizard", state.classId == "rogue"
        if tag == "magic_pool" or tag == "offensive_magic_activation" then return wizard end
        if tag == "elemental_magic_attack" then return wizard and #(state.contentIds or {}) > 0 end
        if tag == "magic_push" then
            if not wizard then return false end
            for _, id in ipairs(state.contentIds or {}) do if id == "earth" then return true end end
            return false
        end
        if tag == "firearm" or tag == "smg" or tag == "multi_fire_burst" then return rogue end
        if tag == "pushable_weapon" or tag == "attributable_nonmagical_damaging_attack" then return not wizard end
        if tag == "attributable_damaging_attack" then return true end
        if tag == "magic_form_owned" or tag == "magic_form_summon" or tag == "magic_form_grant_available"
            or tag == "magic_content_grant_available" or tag == "discrete_magic_activation"
            or tag == "crowbar" or tag == "minimap" or tag == "cooperative_hero" or tag == "tetris"
            or tag == "reloadable_firearm" or tag == "hit_stun_source" or tag == "magnum" then return false end
    end
    return baseCapability(self, ps, state, tag)
end
local basePhysical = P.HasAuthoredPhysicalAttack
function P:HasAuthoredPhysicalAttack(state)
    if state and state.skeletonHero then return state.classId ~= "wizard" end
    return basePhysical(self, state)
end
local baseGrant = LOD.MagicProgression._GrantDistinct
function LOD.MagicProgression:_GrantDistinct(state, kind, milestone, seed)
    if state and state.skeletonHero and (kind == "form" or state.classId ~= "wizard") then
        return false, "controller unavailable"
    end
    return baseGrant(self, state, kind, milestone, seed)
end

function S:Generate(seed, dungeonLevel)
    seed = tonumber(seed) or 1
    dungeonLevel = math.max(1, math.floor(tonumber(dungeonLevel) or 1))
    local classId = self.Classes[LOD.RNG.New(LOD.Seeds.Derive(seed, "skeleton:class")):Int(1, #self.Classes)]
    local state = P:NewProgressionState("skeleton:" .. tostring(seed), self.Archetypes[classId], "ai")
    state.skeletonHero = true
    state.dungeonLevel, state.tierId = dungeonLevel, "champion"
    state.classId, state.startingHP = classId, 100
    state.progressionHitDieSides = RPG.Classes[classId].heroProgressionHitDieSides
    state.usesMagic = classId == "wizard"
    state.capabilityTags = {}
    local abilities, total, attempts, audit = LOD.HeroAbilityRolls:Generate(LOD.Seeds.Derive(seed, "skeleton:abilities"))
    state.baseAbilities, state.baseAbilityRollTotal = abilities, total
    state.baseAbilityRollAttempts, state.baseAbilityRollAudit = attempts, audit
    state.baseAbilityRollMethod = "4d6_drop_lowest_74_then_weakness"
    -- A private allocation scope uses the normal name/identity generator without
    -- consuming or perturbing any human Hero's campaign roster slots.
    local identityRun = {State = {RosterSeed = seed, PlayerState = {}}}
    local ps = {identity = state.actorId, ordinal = 1}
    if classId == "rogue" then ps.starterWeaponClass = "weapon_smg1" end
    local sex = LOD.RNG.New(LOD.Seeds.Derive(seed, "skeleton:sex")):Int(1, 2) == 1 and "male" or "female"
    state.characterIdentityPackage = P:_BuildIdentityPackage(identityRun, ps, {presentationSex = sex, model = self.Model})
    state.identityAbilityDelta = table.Copy(state.characterIdentityPackage.identityAbilityDelta)
    state.skeletonName = "Skeleton of " .. state.characterIdentityPackage.fullDisplayName
    P:_AssignAutomaticGrowthProfile(state, seed)
    P:_RecomputeProgressionState(state)
    local draft = P:_GenerateOrdinaryDraft(ps, state, seed, 1)
    P:_CommitAutomaticFeat(ps, state, draft, seed)
    P:_RecomputeProgressionState(state)
    assert(P:AdvanceAutomaticActor(ps, state, seed, math.min(20, dungeonLevel + 2)))
    return state
end

function S:Live(ent)
    if not IsValid(ent) or ent.LODDead or ent:Health() <= 0 then return false end
    local event, director = LOD.EventSkeletonBlockade, LOD.EventDirector
    local instance, run = ent.LODEventInstance, LOD.RunManager and LOD.RunManager.State
    if not event or not director or not instance or instance.hostile ~= ent
        or not event.Owned(director, instance) then return false end
    if not run or not run.BuildReady or run.Failed or run.LevelCleared or run.SimulationFrozen then return false end
    local clock = run.CampaignClock
    return not clock or not (clock.expired or clock.scene or clock.deadline and SysTime() >= clock.deadline)
end

function S:Spawn(events, instance, graph)
    if util.IsValidModel and not util.IsValidModel(self.Model) then return nil, "stock skeleton model unavailable" end
    local profile = self:Generate(instance.seed, graph.DungeonLevel or instance.level)
    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then return nil, "skeleton entity creation failed" end
    if not events:Track(instance, ent) then ent:Remove();return nil, "stale skeleton creation" end
    instance.hostile = ent
    ent.LODSkeletonHero, ent.LODVarianceApplied = true, true
    ent.LODInstanceSeed, ent.LODProgressionState = instance.seed, profile
    ent.LODArchetypeId, ent.LODHomeCellKey = profile.archetypeId, instance.cellKey
    ent.LODEncounterId = instance.id
    ent:SetPos(LOD.MazeBuilder:CellCenter(instance.cell) + Vector(0, 0, 4))
    ent:Spawn();ent:Activate()
    if not IsValid(ent) or not events:Track(instance, ent) then return nil, "skeleton lost during creation" end
    ent.LODConfig = table.Copy(LOD.Config.Encounter.Archetypes[profile.archetypeId])
    ent.LODConfig.name, ent.LODConfig.model = profile.skeletonName, self.Model
    ent:SetModel(self.Model);ent:SetColor(self.Colors[profile.classId])
    ent:SetNW2Bool("LOD_SkeletonHero", true)
    ent:SetNW2String("LOD_MonsterName", profile.skeletonName)
    ent:SetNW2Float("LOD_SizeScale", 1)
    ent:SetNW2Int("LOD_InstanceSeed", instance.seed)
    ent.LODCharacterLevel, ent.LODMonsterTier = profile.level, profile.tierId
    ent:SetNW2Int("LOD_CharacterLevel", profile.level)
    ent:SetNW2String("LOD_MonsterTier", profile.tierId)
    P:SyncMonsterIdentity(ent, profile)
    ent:SetMaxHealth(profile.derivedStats.maxHP);ent:SetHealth(profile.derivedStats.maxHP)
    if IsValid(ent.LODWeaponVisual) then ent.LODWeaponVisual:SetModel("models/weapons/w_smg1.mdl") end
    if profile.usesMagic then LOD.Magic:_Sync(ent, LOD.Magic:_EnsureState(ent)) end
    return ent
end

-- Begin seals one actually owned Content; release pays once through the existing
-- cost/pool authority. Interrupted warnings cost nothing and never release.
function S:ArcContent(ent)
    local state = ent.LODProgressionState
    local ids = state and state.contentIds or {}
    if #ids == 0 then return nil end
    local index = ((ent.LODSkeletonArcSerial or 0) % #ids) + 1
    return RPG.MagicContents[ids[index]]
end
function S:ArcCost(ent, content)
    return LOD.RPGAbilityRules:OffensiveMagicCost(ent, self.ArcBaseCost + (content and content.surcharge or 0))
end
function S:CanBeginArc(ent, now)
    if not self:Live(ent) then return false end
    local content = self:ArcContent(ent)
    local pool = LOD.Magic:_EnsureState(ent)
    if not pool or pool.magic < self:ArcCost(ent, content) then
        ent.LODNextAttack = now + .5
        return false
    end
    ent.LODSkeletonPendingContent = content
    return true
end
function S:CommitArc(ent, attack)
    if not self:Live(ent) or ent.LODRosterAttack ~= attack or attack.skeletonCommitting then return false end
    if attack.skeletonPaid then return true end
    local content = attack.skeletonContent
    local pool, cost = LOD.Magic:_EnsureState(ent), self:ArcCost(ent, content)
    if not pool or pool.magic < cost then return false end
    local fullMagicBonus = LOD.RPGWizardOffense:FullMagicBonus(ent)
    -- Claim the debit, serial and delivery before native synchronization can
    -- reenter release. The old profile may retain its committed cost after
    -- teardown, but it can never release an attack in a replacement dungeon.
    attack.skeletonPaid, attack.skeletonCommitting = true, true
    attack.event.skeletonFullMagicBonus = fullMagicBonus
    attack.event.skeletonContent = content
    ent.LODSkeletonArcSerial = (ent.LODSkeletonArcSerial or 0) + 1
    pool.magic = pool.magic - cost
    local ok = pcall(LOD.Magic._Sync, LOD.Magic, ent, pool)
    attack.skeletonCommitting = nil
    return ok and self:Live(ent) and ent.LODRosterAttack == attack
end
