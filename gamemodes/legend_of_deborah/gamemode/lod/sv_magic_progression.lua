LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.MagicProgression = LOD.MagicProgression or {}
LOD.Magic = LOD.Magic or {}

local RPG = LOD.RPG
local Progression = LOD.CharacterProgressionSystem
local MagicProgression = LOD.MagicProgression

if not Progression or not RPG then return end

MagicProgression.SourceDocumentId = "1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY"
MagicProgression.SourceRevisionId = "ANLCKQmboT5nux5Lm3q62ObxvAeLRflm1f4D_IsXIOK2bLIp8MfCOfAm5qRLQK7SvE1sWB6zV3Gn_CnaE__-w6fMnNlO9w6XqCYtQQcD_g"

RPG.MagicForms = RPG.MagicForms or {
    blast = {id = "blast", displayName = "Blast", damageDice = 2, damageSides = 6, magicCost = 45},
    beam = {id = "beam", displayName = "Beam", damageDice = 2, damageSides = 6, magicCost = 20},
    bomb = {id = "bomb", displayName = "Bomb", damageDice = 3, damageSides = 6, magicCost = 20},
    missile = {id = "missile", displayName = "Missile", damageDice = 3, damageSides = 6, magicCost = 25},
    bolt = {id = "bolt", displayName = "Bolt", damageDice = 4, damageSides = 6, magicCost = 15},
    summon = {id = "summon", displayName = "Summon", damageDice = 0, damageSides = 0, magicCost = 40}
}

RPG.MagicContents = RPG.MagicContents or {
    earth = {id = "earth", displayName = "Earth", ability = "str", surcharge = 10, element = "earth", rider = "push"},
    fire = {id = "fire", displayName = "Fire", ability = "dex", surcharge = 15, element = "fire", rider = "immolated"},
    dark = {id = "dark", displayName = "Dark", ability = "con", surcharge = 15, element = "dark", rider = "poisoned"},
    ice = {id = "ice", displayName = "Ice", ability = "int", surcharge = 10, element = "ice", rider = "held"},
    light = {id = "light", displayName = "Light", ability = "wis", surcharge = 5, element = "light", rider = "muted"},
    electric = {id = "electric", displayName = "Electric", ability = "cha", surcharge = 10, element = "electric", rider = "morale"}
}

local FORM_ORDER = {"blast", "beam", "bomb", "missile", "bolt", "summon"}
local CONTENT_ORDER = {"earth", "fire", "dark", "ice", "light", "electric"}
MagicProgression.FormOrder = FORM_ORDER
MagicProgression.ContentOrder = CONTENT_ORDER

util.AddNetworkString("LOD_MagicSpellbookSnapshot")
util.AddNetworkString("LOD_MagicSpellbookSelect")

local function addSchemaField(name)
    local fields = RPG.Schema and RPG.Schema.ProgressionState
    if not fields then return end
    for _, existing in ipairs(fields) do if existing == name then return end end
    fields[#fields + 1] = name
end
for _, field in ipairs({
    "magicFormIds", "selectedMagicFormId", "selectedMagicContentId",
    "magicGrantMilestones", "classMilestoneAbilityDelta",
    "favoredEnemyStacks", "favoredWeaponStacks"
}) do addSchemaField(field) end
RPG.SystemBootstrap = RPG.SystemBootstrap or {}
RPG.SystemBootstrap.MagicProgressionSystem = "integrated_checkpoint_c"
RPG.SystemBootstrap.SpellbookUI = "integrated_checkpoint_c"

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local function copyArray(values)
    local out = {}
    for i, value in ipairs(values or {}) do out[i] = value end
    return out
end

local function derive(seed, label)
    return LOD.Seeds.Derive(seed or 1, "rpg:magic_progression:" .. tostring(label))
end

local function campaignSeed()
    local state = LOD.RunManager and LOD.RunManager.State
    return state and state.CampaignSeed or 1
end

function MagicProgression:EnsureState(state)
    if not state then return nil end
    state.magicFormIds = state.magicFormIds or {}
    state.contentIds = state.contentIds or {}
    state.magicGrantMilestones = state.magicGrantMilestones or {}
    state.favoredEnemyStacks = tonumber(state.favoredEnemyStacks) or 0
    state.favoredWeaponStacks = tonumber(state.favoredWeaponStacks) or 0
    if state.selectedMagicFormId and not contains(state.magicFormIds, state.selectedMagicFormId) then
        state.selectedMagicFormId = nil
    end
    if state.selectedMagicContentId and not contains(state.contentIds, state.selectedMagicContentId) then
        state.selectedMagicContentId = nil
    end
    return state
end

function MagicProgression:_GrantDistinct(state, kind, milestone, seed)
    self:EnsureState(state)
    local catalog = kind == "form" and RPG.MagicForms or RPG.MagicContents
    local order = kind == "form" and FORM_ORDER or CONTENT_ORDER
    local owned = kind == "form" and state.magicFormIds or state.contentIds
    local key = kind .. ":" .. tostring(milestone)
    if state.magicGrantMilestones[key] then return false, "already" end

    local available = {}
    for _, id in ipairs(order) do
        if catalog[id] and not contains(owned, id) then available[#available + 1] = id end
    end
    state.magicGrantMilestones[key] = true
    if #available == 0 then return false, "exhausted" end

    local rng = LOD.RNG.New(derive(seed, tostring(state.actorId) .. ":" .. kind .. ":" .. milestone))
    local selected = available[rng:Int(1, #available)]
    owned[#owned + 1] = selected
    if kind == "form" and not state.selectedMagicFormId then state.selectedMagicFormId = selected end
    return true, selected
end

function MagicProgression:ClassMilestoneAbilityDelta(state)
    local delta = RPG.NewAbilityBlock(0)
    if not state or not state.classId then return delta end
    local level = math.max(1, math.floor(tonumber(state.level) or 1))
    if state.classId == "wizard" and level >= 7 then
        delta.int = delta.int + 1
    elseif state.classId == "rogue" then
        if level >= 8 then delta.dex = delta.dex + 1 end
        if level >= 14 then delta.dex = delta.dex + 1 end
    elseif state.classId == "fighter" then
        if level >= 8 then delta.str = delta.str + 1 end
        if level >= 14 then delta.str = delta.str + 1 end
    end
    return delta
end

function MagicProgression:FavoredMilestoneStacks(state)
    if not state or not state.classId then return 0, 0 end
    local level = math.max(1, math.floor(tonumber(state.level) or 1))
    local count = 0
    if level >= 2 then count = count + 1 end
    if level >= 7 then count = count + 1 end
    if level >= 10 then count = count + 1 end
    if state.classId == "rogue" then return count, 0 end
    if state.classId == "fighter" then return 0, count end
    return 0, 0
end

function MagicProgression:ApplyScheduledGrants(state, seed)
    if not state then return false end
    self:EnsureState(state)
    seed = seed or campaignSeed()
    local level = math.max(1, math.floor(tonumber(state.level) or 1))
    local changed = false

    local function form(at, key)
        if level >= at then
            local granted = self:_GrantDistinct(state, "form", key or ("level_" .. at), seed)
            changed = granted or changed
        end
    end
    local function content(at, key)
        if level >= at then
            local granted = self:_GrantDistinct(state, "content", key or ("level_" .. at), seed)
            changed = granted or changed
        end
    end

    -- Level 1 occurs before class choice and is always one deterministic Form.
    form(1, "level_1_all")
    if state.classId == "wizard" then form(2, "level_2_wizard") end
    content(4, "level_4_all")
    form(5, "level_5_all")
    if state.classId == "wizard" then
        content(8, "level_8_wizard")
        form(10, "level_10_wizard")
        content(14, "level_14_wizard")
    end

    state.favoredEnemyStacks, state.favoredWeaponStacks = self:FavoredMilestoneStacks(state)
    return changed
end

-- Scheduled Magic ownership must exist before any same/later-level feat draft is
-- generated. Heroes can gain multiple banked levels in one transaction and AI
-- actors are synthesized through Level 20 in one call, so hook the existing
-- per-level progression seams rather than applying all grants only afterward.
if not Progression.LODMagicOrdinaryDraftOrderingWrapped then
    Progression.LODMagicOrdinaryDraftOrderingWrapped = true
    local base = Progression._GenerateOrdinaryDraft
    function Progression:_GenerateOrdinaryDraft(ps, state, seed, earnedAtLevel)
        MagicProgression:ApplyScheduledGrants(state, seed or 1)
        return base(self, ps, state, seed, earnedAtLevel)
    end
end

if not Progression.LODMagicHeroHitDieOrderingWrapped then
    Progression.LODMagicHeroHitDieOrderingWrapped = true
    local base = Progression._GenerateProgressionHitDie
    function Progression:_GenerateProgressionHitDie(ps, state, seed, level)
        MagicProgression:ApplyScheduledGrants(state, seed or 1)
        return base(self, ps, state, seed, level)
    end
end

if Progression._GenerateAutomaticHitDie and not Progression.LODMagicAutomaticHitDieOrderingWrapped then
    Progression.LODMagicAutomaticHitDieOrderingWrapped = true
    local base = Progression._GenerateAutomaticHitDie
    function Progression:_GenerateAutomaticHitDie(state, actorSeed, level)
        MagicProgression:ApplyScheduledGrants(state, actorSeed or 1)
        return base(self, state, actorSeed, level)
    end
end

function MagicProgression:MaxActiveSummons(state)
    local cap = 1
    if contains(state and state.featIds, "INT_MIDDLE_MANAGER") then cap = 2 end
    if contains(state and state.featIds, "INT_TASKMASTER") then cap = 3 end
    if contains(state and state.featIds, "INT_OVERLORD") then cap = 4 end
    return cap
end

-- Fold the class milestone ability increases into the existing recomputation
-- transaction without creating a second derived-stat authority. The persisted
-- feat delta remains untouched so source attribution stays truthful.
if not Progression.LODMagicMilestoneRecomputeWrapped then
    Progression.LODMagicMilestoneRecomputeWrapped = true
    local base = Progression._RecomputeProgressionState
    function Progression:_RecomputeProgressionState(state)
        if not state then return base(self, state) end
        local original = state.featAbilityDelta or RPG.NewAbilityBlock(0)
        local merged = {}
        for _, ability in ipairs(RPG.Abilities or {}) do merged[ability] = tonumber(original[ability]) or 0 end
        local milestone = MagicProgression:ClassMilestoneAbilityDelta(state)
        for _, ability in ipairs(RPG.Abilities or {}) do
            merged[ability] = (merged[ability] or 0) + (milestone[ability] or 0)
        end
        state.classMilestoneAbilityDelta = milestone
        state.featAbilityDelta = merged
        local results = {base(self, state)}
        state.featAbilityDelta = original
        return unpack(results)
    end
end

if not Progression.LODMagicInitializeHeroWrapped then
    Progression.LODMagicInitializeHeroWrapped = true
    local base = Progression.InitializeHero
    function Progression:InitializeHero(runManager, ps, character)
        local state = base(self, runManager, ps, character)
        if state then MagicProgression:ApplyScheduledGrants(state,
            runManager and runManager.State and runManager.State.CampaignSeed or 1) end
        return state
    end
end

if not Progression.LODMagicCommitClassWrapped then
    Progression.LODMagicCommitClassWrapped = true
    local base = Progression.CommitClass
    function Progression:CommitClass(ply, classId)
        local ok, err = base(self, ply, classId)
        if not ok then return ok, err end
        local run = LOD.RunManager
        local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState
        if state then
            MagicProgression:ApplyScheduledGrants(state,
                run and run.State and run.State.CampaignSeed or 1)
            self:_RecomputeProgressionState(state)
            self:SyncPlayer(ply)
        end
        return true
    end
end

if not Progression.LODMagicAdvanceHeroWrapped then
    Progression.LODMagicAdvanceHeroWrapped = true
    local base = Progression.AdvanceHeroToLevel
    function Progression:AdvanceHeroToLevel(ply, targetLevel)
        local ok, err = base(self, ply, targetLevel)
        if not ok then return ok, err end
        local run = LOD.RunManager
        local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState
        if state then
            MagicProgression:ApplyScheduledGrants(state,
                run and run.State and run.State.CampaignSeed or 1)
            self:_RecomputeProgressionState(state)
            self:_ApplyPlayerMaxHP(ply, state)
            self:SyncPlayer(ply)
        end
        return true
    end
end

if not Progression.LODMagicMonsterProgressionWrapped then
    Progression.LODMagicMonsterProgressionWrapped = true
    local base = Progression.GenerateMonsterProgression
    function Progression:GenerateMonsterProgression(archetypeId, actorSeed, dungeonLevel, startingHP, actorType)
        local state, err = base(self, archetypeId, actorSeed, dungeonLevel, startingHP, actorType)
        if not state then return state, err end
        MagicProgression:ApplyScheduledGrants(state, actorSeed or 1)
        self:_RecomputeProgressionState(state)
        return state
    end
end

function MagicProgression:Snapshot(state)
    self:EnsureState(state)
    local forms, contents = {}, {{id = "raw", displayName = "RAW", owned = true,
        selected = state and state.selectedMagicContentId == nil}}
    for _, id in ipairs(FORM_ORDER) do
        local def = RPG.MagicForms[id]
        forms[#forms + 1] = {
            id = id, displayName = def.displayName, magicCost = def.magicCost,
            owned = contains(state and state.magicFormIds, id),
            selected = state and state.selectedMagicFormId == id or false
        }
    end
    for _, id in ipairs(CONTENT_ORDER) do
        local def = RPG.MagicContents[id]
        contents[#contents + 1] = {
            id = id, displayName = def.displayName, surcharge = def.surcharge,
            owned = contains(state and state.contentIds, id),
            selected = state and state.selectedMagicContentId == id or false
        }
    end
    return {
        forms = forms,
        contents = contents,
        selectedFormId = state and state.selectedMagicFormId or nil,
        selectedContentId = state and state.selectedMagicContentId or nil,
        magicFormIds = copyArray(state and state.magicFormIds),
        contentIds = copyArray(state and state.contentIds),
        favoredEnemyStacks = tonumber(state and state.favoredEnemyStacks) or 0,
        favoredWeaponStacks = tonumber(state and state.favoredWeaponStacks) or 0,
        maxActiveSummons = self:MaxActiveSummons(state)
    }
end

function MagicProgression:SendSnapshot(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState
    if not state then return end
    net.Start("LOD_MagicSpellbookSnapshot")
    net.WriteTable(self:Snapshot(state))
    net.Send(ply)
end

if not Progression.LODMagicSnapshotSyncWrapped then
    Progression.LODMagicSnapshotSyncWrapped = true
    local base = Progression.SyncPlayer
    function Progression:SyncPlayer(ply)
        local result = base(self, ply)
        MagicProgression:SendSnapshot(ply)
        return result
    end
end

net.Receive("LOD_MagicSpellbookSelect", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local kind = net.ReadUInt(1) == 0 and "form" or "content"
    local id = string.lower(net.ReadString() or "")
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState
    if not state or state.actorType ~= "hero" then return end
    MagicProgression:EnsureState(state)

    if kind == "form" then
        if RPG.MagicForms[id] and contains(state.magicFormIds, id) then
            state.selectedMagicFormId = id
        end
    else
        if id == "raw" then
            state.selectedMagicContentId = nil
        elseif RPG.MagicContents[id] and contains(state.contentIds, id) then
            state.selectedMagicContentId = id
        end
    end
    MagicProgression:SendSnapshot(ply)
end)

function MagicProgression:Validate()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    expect(#FORM_ORDER == 6, "six Forms")
    expect(#CONTENT_ORDER == 6, "six Contents")
    local seen = {}
    for _, id in ipairs(FORM_ORDER) do
        expect(RPG.MagicForms[id] ~= nil, "Form catalog " .. id)
        seen[id] = true
    end
    expect(seen.blast and seen.beam and seen.bomb and seen.missile and seen.bolt and seen.summon,
        "canonical Form IDs")

    local synthetic = Progression:NewProgressionState("magic-validation", "hero", "hero")
    synthetic.classId = "wizard"
    synthetic.level = 14
    self:ApplyScheduledGrants(synthetic, 424242)
    expect(#synthetic.magicFormIds == 4, "Wizard four scheduled Forms by 14")
    expect(#synthetic.contentIds == 3, "Wizard three scheduled Contents by 14")
    local replay = Progression:NewProgressionState("magic-validation", "hero", "hero")
    replay.classId = "wizard"
    replay.level = 14
    self:ApplyScheduledGrants(replay, 424242)
    expect(table.concat(synthetic.magicFormIds, ",") == table.concat(replay.magicFormIds, ","),
        "deterministic Form replay")
    expect(table.concat(synthetic.contentIds, ",") == table.concat(replay.contentIds, ","),
        "deterministic Content replay")
    local delta = self:ClassMilestoneAbilityDelta(synthetic)
    expect(delta.int == 1, "Wizard Level-7 intrinsic INT milestone")

    local fighter = Progression:NewProgressionState("fighter-validation", "hero", "hero")
    fighter.classId = "fighter"
    fighter.level = 14
    self:ApplyScheduledGrants(fighter, 9)
    local fdelta = self:ClassMilestoneAbilityDelta(fighter)
    expect(#fighter.magicFormIds == 2 and #fighter.contentIds == 1,
        "Fighter scheduled Magic ownership")
    expect(fdelta.str == 2 and fighter.favoredWeaponStacks == 3,
        "Fighter synchronized milestones")

    return #errors == 0, errors
end

concommand.Add("lod_magic_progression_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = MagicProgression:Validate()
    local line = "Magic progression validation " .. (ok and "PASS" or "FAILED")
    print("[LOD:MAGIC-PROGRESSION] " .. line)
    for _, err in ipairs(errors) do ErrorNoHalt("[LOD:MAGIC-PROGRESSION] - " .. err .. "\n") end
    if IsValid(ply) then ply:ChatPrint(line) end
end)
