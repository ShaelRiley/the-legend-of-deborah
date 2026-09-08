local RPG = LOD.RPG
local Effects, Rules = RPG.FeatEffectSystem, LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
local Feats = RPG.IdentityCatalog.OrdinaryFeats
local ID = 'INT_WAS_DEBORAH'
Feats[ID] = {
    featId = ID, displayName = 'W,A,S,Deborah', featFamilyId = 'int_backpedal',
    governingAbilities = {'int'}, abilityRequirements = {int = 13},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
    allowedActorTypes = {'hero', 'human_soldier'}, requiredSubsystemTags = {},
    synergyTags = {'movement'}, oneRank = true, repeatableFallback = false,
    effectHandlerId = 'backpedal_movement', directorBaseWeight = 1,
    effectParams = {multiplier = 1.25, description =
        'Voluntary backward movement, including backward diagonals, is 25% faster. Composes with ordinary movement modes and map movement. Forward movement, pure strafing, jumping and forced motion are unchanged.'}
}
local function owns(state)
    for _, id in ipairs(state and state.featIds or {}) do if id == ID then return true end end
    return false
end
if not Effects.LODBackpedalDerivedWrapped then
    Effects.LODBackpedalDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        derived.backpedalMovementMultiplier = owns(state) and 1.25 or 1
    end
end

Effects.BackpedalStats = Effects.BackpedalStats or setmetatable({}, {__mode = 'k'})
function Rules:BackpedalMultiplier(actor, move)
    if not IsValid(actor) or not actor:IsPlayer() or not actor:Alive()
        or actor:GetMoveType() ~= MOVETYPE_WALK or not actor:OnGround()
        or actor:WaterLevel() >= 2 or move:KeyDown(IN_JUMP)
        or move:GetForwardSpeed() >= 0 then return 1 end
    local derived = self:Derived(actor)
    return derived and derived.backpedalMovementMultiplier or 1
end

-- Called inside the existing SetupMove speed pipeline after mode/DEX/map scaling.
-- Scale both desired input and its cap: this preserves analog input fractions
-- and diagonal normalization. Never write velocity, jump power or position.
function Rules:ApplyVoluntaryMovementFeats(actor, move)
    local multiplier = self:BackpedalMultiplier(actor, move)
    if multiplier > 1 then
        move:SetForwardSpeed(move:GetForwardSpeed() * multiplier)
        move:SetSideSpeed(move:GetSideSpeed() * multiplier)
        move:SetMaxSpeed(move:GetMaxSpeed() * multiplier)
        move:SetMaxClientSpeed(move:GetMaxClientSpeed() * multiplier)
    end
    local stats = Effects.BackpedalStats[actor]
    if stats then
        stats.last = multiplier
        if multiplier > 1 then
            stats.backward = stats.backward + 1
            if move:GetSideSpeed() ~= 0 then stats.diagonal = stats.diagonal + 1 end
            stats.peak = math.max(stats.peak, multiplier)
        elseif move:GetForwardSpeed() > 0 then stats.forward = stats.forward + 1
        elseif move:GetForwardSpeed() == 0 and move:GetSideSpeed() ~= 0 then stats.strafe = stats.strafe + 1 end
    end
end

function Effects:ValidateBackpedal()
    local def = Feats[ID]
    local ok = def and def.abilityRequirements.int == 13
        and def.effectParams.multiplier == 1.25 and #def.prerequisiteFeatIds == 0
    return ok == true, ok and {} or {'W,A,S,Deborah definition mismatch'}
end
local validation = LOD.RPGValidation
if validation and not validation.LODBackpedalWrapped then
    validation.LODBackpedalWrapped = true
    local base = validation.Run
    function validation:Run(printResult)
        local ok, errors = base(self, printResult)
        local valid, ownErrors = Effects:ValidateBackpedal()
        errors = errors or {}
        for _, err in ipairs(ownErrors) do errors[#errors + 1] = err end
        return ok and valid, errors
    end
end
local function allowed(ply)
    local cv = GetConVar('lod_developer_mode')
    return cv and cv:GetBool() and IsValid(ply) and ply:IsAdmin()
end
concommand.Add('lod_rpg_backpedal_testkit', function(ply, _, args)
    if not allowed(ply) or not ply:Alive() then return end
    local state = Rules:ProgressionState(ply)
    if not state then return end
    local enabled = tonumber(args[1]) ~= 0
    local kept = {}
    for _, id in ipairs(state.featIds or {}) do if id ~= ID then kept[#kept + 1] = id end end
    if enabled then kept[#kept + 1] = ID end
    state.featIds = kept
    state.featStackCounts = state.featStackCounts or {}
    state.featStackCounts[ID] = enabled and 1 or nil
    Progression:_RecomputeProgressionState(state)
    Progression:SyncPlayer(ply)
    if LOD.RunManager.MarkUnranked then LOD.RunManager:MarkUnranked('Backpedal feat test') end
    Effects.BackpedalStats[ply] = {backward=0, diagonal=0, forward=0, strafe=0, last=1, peak=1}
    ply:ChatPrint('Backpedal feat ' .. (enabled and 'ON' or 'OFF') .. ': walk S, S+A, W, then A; run lod_rpg_backpedal_status.')
end)
concommand.Add('lod_rpg_backpedal_status', function(ply)
    if not allowed(ply) then return end
    local stats = Effects.BackpedalStats[ply] or {}
    local ok, errors = Effects:ValidateBackpedal()
    local line = string.format('[LOD:BACKPEDAL] definition=%s backward=%d diagonal=%d forward=%d strafe=%d peak=%.2f last=%.2f %s',
        ok and 'PASS' or 'FAIL', stats.backward or 0, stats.diagonal or 0, stats.forward or 0,
        stats.strafe or 0, stats.peak or 1, stats.last or 1, table.concat(errors, '; '))
    print(line)
    ply:ChatPrint(line)
end)
return Effects
