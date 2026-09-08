LOD = LOD or {}
local RPG = LOD.RPG
local Catalog = RPG and RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG and RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
if not Feats or not Effects or not Rules or not Progression then return end

-- Live GDD, 2026-09-08: highest owned rank replaces all lower ranks.
local IDS = {'INT_WORLD_WALKER_1', 'INT_GLOBETROTTER_2', 'INT_MIND_STRIDER_3'}
local NAMES = {'World Walker', 'Globetrotter', 'Mind Strider'}
local RANKS = {}
for rank, id in ipairs(IDS) do
    RANKS[id] = rank
    Feats[id] = {
        featId = id, displayName = NAMES[rank], featFamilyId = 'int_map_movement',
        rankIndex = rank, replacesLowerRank = rank > 1, repeatableFallback = false,
        governingAbilities = {'int'}, abilityRequirements = {int = 11 + 2 * rank},
        prerequisiteFeatIds = rank > 1 and {IDS[rank - 1]} or {},
        requiredCapabilityTags = {'minimap'}, incompatibleFeatIds = {},
        allowedActorTypes = {'hero', 'human_soldier'}, requiredSubsystemTags = {},
        synergyTags = {'minimap', 'movement'}, oneRank = true,
        effectHandlerId = 'map_open_movement', directorBaseWeight = 1,
        effectParams = {multiplier = 1 + rank * 0.25, description = string.format(
            'While your personal minimap is legally open, ordinary movement speed is multiplied by %.2f. Only the highest rank applies; closes, lost access and exhausted Magic end the bonus. Does not modify jump velocity or forced movement.', 1 + rank * 0.25)}
    }
end
Catalog.OrdinaryFeats = Feats

function Effects:MapMovementProfile(state)
    local rank = 0
    for _, id in ipairs(state and state.featIds or {}) do rank = math.max(rank, RANKS[id] or 0) end
    return rank, 1 + rank * 0.25
end

if not Effects.LODMapMovementDerivedWrapped then
    Effects.LODMapMovementDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        derived.mapOpenMovementRank, derived.mapOpenMovementMultiplier = self:MapMovementProfile(state)
    end
end

Effects.MapMovementStats = Effects.MapMovementStats or setmetatable({}, {__mode = 'k'})
if not Rules.LODMapMovementWrapped then
    Rules.LODMapMovementWrapped = true
    local base = Rules.MovementMultiplier
    function Rules:MovementMultiplier(actor)
        local ordinary = base(self, actor)
        local derived = self:Derived(actor)
        local bonus = tonumber(derived and derived.mapOpenMovementMultiplier) or 1
        local map = LOD.MinimapMagic
        local open = bonus > 1 and map and map.IsOpen and map:IsOpen(actor) or false
        local multiplier = open and bonus or 1
        -- Telemetry is opt-in per tester; no per-frame tables for ordinary play.
        local stats = Effects.MapMovementStats[actor]
        if stats then
            stats.last = multiplier
            stats.peak = math.max(stats.peak, multiplier)
            if open then stats.openSamples = stats.openSamples + 1
            elseif stats.openSamples > 0 then stats.closedAfterOpen = true end
        end
        return ordinary * multiplier
    end
end

function Effects:ValidateMapMovement()
    local errors = {}
    for rank, id in ipairs(IDS) do
        local def = Feats[id]
        local owned = {}
        for i = 1, rank do owned[#owned + 1] = IDS[i] end
        local actual, multiplier = self:MapMovementProfile({featIds = owned})
        if actual ~= rank or multiplier ~= 1 + rank * 0.25
            or def.abilityRequirements.int ~= 11 + 2 * rank
            or (rank > 1 and def.prerequisiteFeatIds[1] ~= IDS[rank - 1]) then
            errors[#errors + 1] = id .. ' rank/prerequisite/replacement mismatch'
        end
    end
    local _, baseline = self:MapMovementProfile({featIds = {}})
    if baseline ~= 1 then errors[#errors + 1] = 'baseline multiplier' end
    return #errors == 0, errors
end

local validation = LOD.RPGValidation
if validation and not validation.LODMapMovementWrapped then
    validation.LODMapMovementWrapped = true
    local base = validation.Run
    function validation:Run(printResult)
        local ok, errors = base(self, printResult)
        local familyOK, familyErrors = Effects:ValidateMapMovement()
        errors = errors or {}
        for _, err in ipairs(familyErrors) do errors[#errors + 1] = err end
        return ok and familyOK, errors
    end
end

local function allowed(ply)
    local cv = GetConVar('lod_developer_mode')
    return cv and cv:GetBool() and IsValid(ply) and ply:IsAdmin()
end
concommand.Add('lod_rpg_mapwalk_validate', function(ply)
    if not allowed(ply) then return end
    local ok, errors = Effects:ValidateMapMovement()
    local line = '[LOD:MAPWALK] ' .. (ok and 'PASS' or 'FAIL') .. ' rank multipliers 1.25/1.50/1.75; ' .. table.concat(errors, '; ')
    print(line)
    ply:ChatPrint(line)
end)
concommand.Add('lod_rpg_mapwalk_testkit', function(ply, _, args)
    if not allowed(ply) or not ply:Alive() then return end
    local state = Rules:ProgressionState(ply)
    if not state then return end
    local rank = math.Clamp(math.floor(tonumber(args[1]) or 3), 0, 3)
    local kept = {}
    for _, id in ipairs(state.featIds or {}) do if not RANKS[id] then kept[#kept + 1] = id end end
    state.featIds = kept
    state.featStackCounts = state.featStackCounts or {}
    for _, id in ipairs(IDS) do state.featStackCounts[id] = nil end
    for i = 1, rank do
        state.featIds[#state.featIds + 1] = IDS[i]
        state.featStackCounts[IDS[i]] = 1
    end
    Progression:_RecomputeProgressionState(state)
    Progression:SyncPlayer(ply)
    if LOD.RunManager and LOD.RunManager.MarkUnranked then LOD.RunManager:MarkUnranked('Map movement feat test') end
    Effects.MapMovementStats[ply] = {last = 1, peak = 1, openSamples = 0, closedAfterOpen = false}
    ply:ChatPrint('Map movement rank ' .. rank .. ': press M, walk briefly, press M to close, then run lod_rpg_mapwalk_status.')
end)
concommand.Add('lod_rpg_mapwalk_status', function(ply)
    if not allowed(ply) then return end
    local rank, bonus = Effects:MapMovementProfile(Rules:ProgressionState(ply))
    local stats = Effects.MapMovementStats[ply] or {}
    local map = LOD.MinimapMagic
    local line = string.format('[LOD:MAPWALK] rank=%d bonus=%.2f open=%s samples=%d peak=%.2f last=%.2f closedAfterOpen=%s',
        rank, bonus, tostring(map and map.IsOpen and map:IsOpen(ply) or false), stats.openSamples or 0,
        stats.peak or 1, stats.last or 1, tostring(stats.closedAfterOpen == true))
    print(line)
    ply:ChatPrint(line)
end)
return Effects
