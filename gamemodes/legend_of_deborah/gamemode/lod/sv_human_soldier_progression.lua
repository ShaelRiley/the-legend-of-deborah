LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.SoldierProgression = LOD.SoldierProgression or {}

-- A Soldier is a disposable combat incarnation, never a replacement Hero
-- progression state.  This module intentionally provides only RPG authority;
-- the role/queue UI can attach and retire it without owning XP or leveling.
local System = LOD.SoldierProgression
local Progression = assert(LOD.CharacterProgressionSystem,
    "Soldier progression requires CharacterProgressionSystem")
local Rules = assert(LOD.RPGAbilityRules, "Soldier progression requires AbilityRules")

local THRESHOLDS = {100, 250, 450}
System.THRESHOLDS = THRESHOLDS
System.Stats = System.Stats or {damageXP = 0, lifeXP = 0, levels = 0, retired = 0}

local function dungeonLevel()
    local state = LOD.RunManager and LOD.RunManager.State
    return math.max(1, math.floor(tonumber(state and state.Level) or 1))
end

function System:EarnedLevelsForXP(xp)
    xp = math.max(0, math.floor(tonumber(xp) or 0))
    if xp >= THRESHOLDS[3] then return 3 end
    if xp >= THRESHOLDS[2] then return 2 end
    if xp >= THRESHOLDS[1] then return 1 end
    return 0
end

function System:NextThreshold(xp)
    xp = math.max(0, math.floor(tonumber(xp) or 0))
    for _, threshold in ipairs(THRESHOLDS) do
        if xp < threshold then return threshold end
    end
    return nil
end

function System:CreateIncarnation(actorSeed, startingHP, level)
    local seed = math.max(1, math.floor(tonumber(actorSeed) or 1))
    local baseHp = (LOD.Config and LOD.Config.Encounter and LOD.Config.Encounter.Archetypes and LOD.Config.Encounter.Archetypes.soldier and LOD.Config.Encounter.Archetypes.soldier.baseHP) or 35
    local state, err = Progression:GenerateMonsterProgression("soldier", seed,
        level or dungeonLevel(), startingHP or baseHp, "human_soldier")
    if not state then return nil, err end
    state.soldierActorSeed = seed
    state.soldierSpawnLevel = state.level
    state.soldierXP = 0
    state.soldierEarnedLevels = 0
    state.soldierIncarnation = true
    return state
end

function System:Attach(ply, actorSeed, startingHP, level)
    if not IsValid(ply) or not ply:IsPlayer() then return nil, "invalid Soldier controller" end
    -- Repeated admission must not reroll an already occupied incarnation.
    local current = self:StateFor(ply)
    if current then return current end
    local state, err = self:CreateIncarnation(actorSeed, startingHP, level)
    if not state then return nil, err end
    ply.LODHumanSoldierProgressionState = state
    return state
end

function System:Retire(target)
    local state = self:StateFor(target)
    if not state then return false end
    if target ~= state then target.LODHumanSoldierProgressionState = nil end
    -- Revoke captured references too: delayed damage cannot develop a retired body.
    state.soldierIncarnation = false
    state.soldierXP, state.soldierEarnedLevels = 0, 0
    self.Stats.retired = (self.Stats.retired or 0) + 1
    return true
end

function System:Reset(target)
    return self:Retire(target)
end

function System:StateFor(actor)
    -- GMod type(player) is "Player", not "table". Plain profiles remain useful
    -- for automatic generation/validation, but are never mistaken for controllers.
    if not IsValid(actor) and type(actor) ~= "table" then return nil end
    local state = actor.LODHumanSoldierProgressionState or actor
    if state.actorType == "human_soldier" and state.soldierIncarnation == true then return state end
end

function System:_Advance(state)
    local earned = self:EarnedLevelsForXP(state.soldierXP)
    local dLvl = state.dungeonLevel or dungeonLevel()
    local cap = Progression:EffectiveLevelCap("human_soldier", dLvl)
    local wanted = math.min((state.soldierSpawnLevel or state.level) + earned, cap)
    local before = state.level
    local ps = {identity = state.actorId, starterWeaponClass = "weapon_smg1"}
    local ok, err = Progression:AdvanceAutomaticActor(ps, state,
        state.soldierActorSeed or 1, wanted)
    if not ok then return false, err end
    state.soldierEarnedLevels = earned
    self.Stats.levels = (self.Stats.levels or 0) + math.max(0, state.level - before)
    return true
end

function System:Award(target, effectiveHeroHPDamage, lifeConsumed)
    local state = self:StateFor(target)
    if not state then return false, "not human Soldier" end
    local damage = math.max(0, math.floor(tonumber(effectiveHeroHPDamage) or 0))
    local life = lifeConsumed == true and 50 or 0
    if damage + life <= 0 then return false, "no credit" end
    state.soldierXP = math.max(0, math.floor(tonumber(state.soldierXP) or 0)) + damage + life
    self.Stats.damageXP = (self.Stats.damageXP or 0) + damage
    self.Stats.lifeXP = (self.Stats.lifeXP or 0) + life
    local before = state.level
    local ok, err = self:_Advance(state)
    if ok and IsValid(target) and target:IsPlayer() then
        if state.level ~= before then Progression:_ApplyPlayerMaxHP(target, state) end
        Progression:SyncPlayer(target)
    end
    return ok, err
end

function System:ObserveEffectiveHeroDamage(attacker, target, effectiveHeroHPDamage)
    local soldier = self:StateFor(attacker)
    if not soldier or not IsValid(target) or target == attacker then return false, "ineligible" end
    local targetState = Rules:ProgressionState(target)
    if not targetState or targetState.actorType ~= "hero" then return false, "non-Hero target" end
    local effective = math.min(math.max(0, target:Health()),
        math.max(0, tonumber(effectiveHeroHPDamage) or 0))
    return self:Award(attacker, effective, false)
end

-- Called only by the authority that actually consumes a personal Hero life.
function System:ObserveHeroLifeConsumed(attacker, target)
    if not IsValid(target) or attacker == target or not self:StateFor(attacker) then return false end
    local state = Rules:ProgressionState(target)
    if not state or state.actorType ~= "hero" then return false end
    return self:Award(attacker, 0, true)
end

-- Existing actor consumers transparently receive the Soldier incarnation state,
-- while the underlying cooperative Hero state remains untouched in RunManager.
if not Rules.LODHumanSoldierStateWrapped then
    Rules.LODHumanSoldierStateWrapped = true
    local base = Rules.ProgressionState
    function Rules:ProgressionState(actor)
        local soldier = System:StateFor(actor)
        return soldier or base(self, actor)
    end
end

function System:Validate()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    expect(self:EarnedLevelsForXP(99) == 0, "SoldierXP below first threshold")
    expect(self:EarnedLevelsForXP(100) == 1 and self:EarnedLevelsForXP(250) == 2
        and self:EarnedLevelsForXP(450) == 3, "SoldierXP thresholds")
    local state, err = self:CreateIncarnation(77331, 40, 1)
    expect(state ~= nil, err or "Soldier generation")
    if state then
        expect(state.progressionHitDieSides == 8 and state.soldierSpawnLevel == state.level,
            "AI-equivalent Soldier d8 generation")
        local before = state.level
        local ok = self:Award(state, 450, false)
        expect(ok and state.soldierXP == 450 and state.soldierEarnedLevels == 3,
            "SoldierXP records earned levels")
        expect(state.level == math.min(before + 3,
            Progression:EffectiveLevelCap("human_soldier", dungeonLevel())), "Soldier ceiling")
    end
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_soldier_progression", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = System:Validate()
    print("[LOD:SOLDIER-XP] " .. (ok and "PASS" or "FAIL")
        .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
