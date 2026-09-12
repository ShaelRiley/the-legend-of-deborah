LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Killer Instinct requires catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Killer Instinct requires ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "Killer Instinct requires ability rules")

Feats.WIS_KILLER_INSTINCT = {
    featId = "WIS_KILLER_INSTINCT", displayName = "Killer Instinct", featFamilyId = "wis_killer_instinct", rankIndex = 1,
    replacesLowerRank = false, repeatableFallback = false,
    governingAbilities = {"wis"}, abilityRequirements = {wis = 15},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
    allowedActorTypes = {"hero", "human_soldier"}, requiredSubsystemTags = {"damage", "hostile_visibility"},
    synergyTags = {"wisdom", "combat", "information"}, oneRank = true,
    effectHandlerId = "private_killer_instinct_priority",
    effectParams = {activationHoldSeconds = 0.50, reevaluateSeconds = 1.00, minimumVisibleHostiles = 2},
    directorBaseWeight = 1.0, eligibilityText = "WIS 15",
    actorText = "Human-controlled Heroes and Soldiers"
}
Catalog.OrdinaryFeats = Feats

local NET_TARGET = "LOD_RPGKillerInstinctTarget"
util.AddNetworkString(NET_TARGET)
local HOLD_SECONDS = 0.50
local REEVALUATE_SECONDS = 1.00

-- Runtime Primary.Damage/NumShots is preferred. These values are compatibility
-- fallbacks for stock Source weapons whose Lua weapon table omits those fields.
-- They model one ordinary primary trigger pull only; no proc/Boom prediction.
local STOCK_PRIMARY = {
    weapon_pistol = {damage = 5, count = 1},
    weapon_357 = {damage = 40, count = 1},
    weapon_smg1 = {damage = 4, count = 1},
    weapon_ar2 = {damage = 8, count = 1},
    weapon_shotgun = {damage = 8, count = 7},
    weapon_crossbow = {damage = 100, count = 1}
}

local function owns(state, id)
    for _, owned in ipairs(state and state.featIds or {}) do if owned == id then return true end end
    return false
end

local function livingHostile(ent)
    return IsValid(ent) and ent.LODHostile == true and ent.LODDead ~= true and ent:Health() > 0
end

local function cachedHostiles()
    local out, seen = {}, {}
    local function add(source)
        for _, hostile in ipairs(source or {}) do
            if livingHostile(hostile) and not seen[hostile] then
                seen[hostile] = true
                out[#out + 1] = hostile
            end
        end
    end
    add(LOD.EncounterDirector and LOD.EncounterDirector.Entities)
    add(LOD.WanderingDirector and LOD.WanderingDirector.Entities)
    table.sort(out, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return out
end

local function inForwardView(ply, hostile)
    local eye = ply:EyePos()
    local delta = hostile:WorldSpaceCenter() - eye
    local length = delta:Length()
    if length <= 0 then return true end
    local halfFov = math.Clamp((tonumber(ply:GetFOV()) or 90) * 0.5, 1, 89)
    local minimumDot = math.cos(math.rad(halfFov))
    return ply:EyeAngles():Forward():Dot(delta / length) >= minimumDot
end

local function ordinaryVisible(ply, hostile)
    return livingHostile(hostile) and inForwardView(ply, hostile) and ply:Visible(hostile)
end

local function scalarProfile(weapon)
    if not IsValid(weapon) then return nil end
    local primary = weapon.Primary or {}
    local damage = tonumber(primary.Damage)
    local count = tonumber(primary.NumShots or primary.NumberofShots or primary.NumberOfShots)
    if damage and damage > 0 then
        return {kind = "scalar", damage = damage, count = math.max(1, math.floor(count or 1))}
    end
    local fallback = STOCK_PRIMARY[weapon:GetClass()]
    if fallback then return {kind = "scalar", damage = fallback.damage, count = fallback.count} end
    return nil
end

function RPG:CheckpointDKillerInstinctWeaponProfile(ply)
    if not IsValid(ply) then return nil end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then return nil end
    if weapon:GetClass() == "weapon_lod_crowbar" then
        local effects = self.FeatEffectSystem
        local profile = effects and effects.CrowbarDamageProfile and effects:CrowbarDamageProfile(ply)
            or {count = 1, sides = 3}
        local count = math.max(1, math.floor(tonumber(profile.count) or 1))
        local sides = math.max(1, math.floor(tonumber(profile.sides) or 3))
        return {kind = "dice", count = count, sides = sides}
    end
    return scalarProfile(weapon)
end

function RPG:CheckpointDKillerInstinctEstimatedDamage(ply, target, profile)
    if not profile or not IsValid(ply) or not livingHostile(target) then return 0 end
    local values = {}
    local count = math.max(1, math.floor(tonumber(profile.count) or 1))
    if profile.kind == "dice" then
        local mean = (math.max(1, tonumber(profile.sides) or 1) + 1) * 0.5
        for index = 1, count do values[index] = mean end
    else
        local damage = math.max(0, tonumber(profile.damage) or 0)
        for index = 1, count do values[index] = damage end
    end
    if #values == 0 then return 0 end
    -- Mirror the deterministic physical-damage arithmetic without invoking the
    -- live resolver: an informational estimate must never mutate combat telemetry.
    local sourceDerived = Rules:Derived(ply) or {}
    local targetDerived = Rules:Derived(target) or {}
    local resistance = math.Clamp(math.floor(tonumber(targetDerived.damageResistancePerDie) or 0), 0, 3)
    local total = 0
    for _, value in ipairs(values) do
        local before = math.max(0, tonumber(value) or 0)
        total = total + (before > 0 and math.max(1, before - resistance) or 0)
    end
    total = total * math.Clamp(tonumber(sourceDerived.physicalDamageMultiplier) or 1, 0.50, 1.50)
    total = total * math.max(0, tonumber(sourceDerived.fighterCapstonePhysicalDamageMultiplier) or 1)
    return math.max(0, total)
end

function RPG:CheckpointDKillerInstinctRecord(damage, hp, stableId, entity)
    damage = math.max(0, tonumber(damage) or 0)
    hp = math.max(0, tonumber(hp) or 0)
    local effective = math.max(1, damage)
    return {
        entity = entity,
        damage = damage,
        hp = hp,
        stableId = tonumber(stableId) or 0,
        shots = math.max(1, math.ceil(hp / effective)),
        margin = damage - hp
    }
end

function RPG:CheckpointDKillerInstinctSelect(records)
    local oneShot = false
    for _, record in ipairs(records or {}) do if record.shots == 1 then oneShot = true break end end
    local candidates = {}
    for _, record in ipairs(records or {}) do
        if not oneShot or record.shots == 1 then candidates[#candidates + 1] = record end
    end
    table.sort(candidates, function(a, b)
        if oneShot and a.margin ~= b.margin then return a.margin > b.margin end
        if not oneShot and a.shots ~= b.shots then return a.shots < b.shots end
        if a.hp ~= b.hp then return a.hp < b.hp end
        return a.stableId < b.stableId
    end)
    return candidates[1]
end

local function sendTarget(ply, target)
    net.Start(NET_TARGET)
    net.WriteEntity(IsValid(target) and target or NULL)
    net.Send(ply)
end

local states = setmetatable({}, {__mode = "k"})
local function resetState(ply, state)
    if state and IsValid(state.selected) then sendTarget(ply, nil) end
    states[ply] = nil
end

local function eligiblePlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    local state = Rules:ProgressionState(ply)
    return state ~= nil and owns(state, "WIS_KILLER_INSTINCT")
end

local function visibleCandidates(ply, hostiles)
    local out = {}
    for _, hostile in ipairs(hostiles) do
        if ordinaryVisible(ply, hostile) then out[#out + 1] = hostile end
    end
    return out
end

RPG.CheckpointDKillerInstinctStats = RPG.CheckpointDKillerInstinctStats or {evaluations = 0, selections = 0}
timer.Create("LOD_CheckpointDKillerInstinct", 0.10, 0, function()
    local now = CurTime()
    local hostiles = cachedHostiles()
    for _, ply in ipairs(player.GetHumans()) do
        local state = states[ply]
        if not eligiblePlayer(ply) then
            if state then resetState(ply, state) end
        else
            local profile = RPG:CheckpointDKillerInstinctWeaponProfile(ply)
            if not profile then
                if state then resetState(ply, state) end
            else
                local visible = visibleCandidates(ply, hostiles)
                if #visible < 2 then
                    if state then resetState(ply, state) end
                else
                    if not state then
                        state = {conditionSince = now, lastEvaluationAt = nil, selected = nil}
                        states[ply] = state
                    end
                    if IsValid(state.selected) and not ordinaryVisible(ply, state.selected) then
                        state.selected = nil
                        sendTarget(ply, nil)
                    end
                    local held = now - state.conditionSince >= HOLD_SECONDS
                    local cadenceReady = state.lastEvaluationAt == nil
                        or now - state.lastEvaluationAt >= REEVALUATE_SECONDS
                    if held and cadenceReady then
                        local records = {}
                        for _, hostile in ipairs(visible) do
                            records[#records + 1] = RPG:CheckpointDKillerInstinctRecord(
                                RPG:CheckpointDKillerInstinctEstimatedDamage(ply, hostile, profile),
                                hostile:Health(), hostile:EntIndex(), hostile)
                        end
                        local selected = RPG:CheckpointDKillerInstinctSelect(records)
                        state.lastEvaluationAt = now
                        RPG.CheckpointDKillerInstinctStats.evaluations = RPG.CheckpointDKillerInstinctStats.evaluations + 1
                        local target = selected and selected.entity or nil
                        if target ~= state.selected then
                            state.selected = target
                            sendTarget(ply, target)
                            if IsValid(target) then
                                RPG.CheckpointDKillerInstinctStats.selections = RPG.CheckpointDKillerInstinctStats.selections + 1
                            end
                        end
                    end
                end
            end
        end
    end
end)

function RPG:ValidateCheckpointDKillerInstinctFeat()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local def = Feats.WIS_KILLER_INSTINCT
    expect(def and def.abilityRequirements.wis == 15, "Killer Instinct WIS 15 definition")
    expect(def and #def.allowedActorTypes == 2 and def.allowedActorTypes[1] == "hero"
        and def.allowedActorTypes[2] == "human_soldier", "Killer Instinct human actor restriction")
    expect(HOLD_SECONDS == 0.50 and REEVALUATE_SECONDS == 1.00, "Killer Instinct cadence")
    local pick = self:CheckpointDKillerInstinctSelect({
        self:CheckpointDKillerInstinctRecord(12, 10, 2),
        self:CheckpointDKillerInstinctRecord(20, 18, 1),
        self:CheckpointDKillerInstinctRecord(30, 12, 3)
    })
    expect(pick and pick.stableId == 3, "one-shot kill margin selection")
    pick = self:CheckpointDKillerInstinctSelect({
        self:CheckpointDKillerInstinctRecord(6, 15, 4),
        self:CheckpointDKillerInstinctRecord(6, 12, 8),
        self:CheckpointDKillerInstinctRecord(6, 12, 3)
    })
    expect(pick and pick.stableId == 3, "shots HP stable-id selection")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_killer_instinct", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDKillerInstinctFeat()
    print("[LOD:KILLER-INSTINCT] " .. (ok and "PASS" or "FAIL")
        .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
