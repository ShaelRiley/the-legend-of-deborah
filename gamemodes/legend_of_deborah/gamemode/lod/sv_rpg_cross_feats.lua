-- Current release CROSS rules: live-GDD rows, with Shael's approved deferred scope.
LOD.RPGCrossFeats = LOD.RPGCrossFeats or {}
local Cross = LOD.RPGCrossFeats
local Rules = assert(LOD.RPGAbilityRules)
local Effects = assert(LOD.RPG.FeatEffectSystem)
local Catalog = assert(LOD.RPG.IdentityCatalog)
local Feats = Catalog.OrdinaryFeats
local Progression = LOD.CharacterProgressionSystem

function Cross:Owns(actor, id)
    local state = Rules:ProgressionState(actor)
    for _, owned in ipairs(state and state.featIds or {}) do if owned == id then return true end end
    return false
end

-- A bounded graph walk, shared by both close-range fear mechanics. Gates and
-- vertical connections have the same meaning as in ordinary navigation.
function Cross:CellsWithin(actor, radius)
    local graph = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.Graph
    local nav = LOD.MazeNavigator
    if not graph or not nav or not IsValid(actor) or not actor.GetPos then return {} end
    local cell = nav:WorldToCell(graph, actor:GetPos())
    if not cell then return {} end
    local key = LOD.MazeGenerator.CellKey(cell.x, cell.y, cell.z)
    local distances, queue, head = {[key] = 0}, {key}, 1
    while head <= #queue do
        local current = queue[head]; head = head + 1
        if distances[current] < radius then
            local neighbors = {}
            for neighbor in pairs(graph.Cells[current].neighbors or {}) do neighbors[#neighbors + 1] = neighbor end
            table.sort(neighbors)
            for _, neighbor in ipairs(neighbors) do
                if graph.Cells[neighbor] and distances[neighbor] == nil and nav:CanTraverse(graph, current, neighbor) then
                    distances[neighbor] = distances[current] + 1
                    queue[#queue + 1] = neighbor
                end
            end
        end
    end
    return distances
end

function Cross:MoraleBonus(source, target, event)
    local bonus = 0
    if self:Owns(source, "CROSS_TINY_TERROR") and self:Owns(source, "DEX_SHRINK") then
        local key = LOD.RPGStatusElements:CellKey(target)
        if key and self:CellsWithin(source, 2)[key] ~= nil then bonus = bonus + 2 end
    end
    if self:Owns(source, "CROSS_BIG_SCARY") and (event.melee or event.physicalPush or event.wallCrush) then
        bonus = bonus + 2
    end
    return bonus
end

-- Append a distinct universal d6 chain to the existing physical contract; it
-- retains its own threshold/continuations for resistance and the DIE-LOGGER.
function Cross:AugmentMeteor(actor, contract, rng)
    local state = Effects.CloudStepState[actor]
    if not self:Owns(actor, "CROSS_METEOR_STRIKE") or not state or not state.used
        or state.meteorUsed or actor:OnGround() then return contract end
    local extra = LOD.CombatRolls:RollActorDamage(actor,
        {count = 1, sides = 6, source = "meteor_strike", attackEvent = contract.attackEvent}, rng, 0)
    local offset = #contract.values
    for i, value in ipairs(extra.values) do
        contract.values[offset + i] = value
        contract.contributions[offset + i] = extra.contributions[i]
        contract.thresholds[offset + i] = extra.thresholds[i]
    end
    for _, start in ipairs(extra.chainStarts) do contract.chainStarts[#contract.chainStarts + 1] = offset + start end
    contract.total = contract.total + extra.total
    contract.baseDice = contract.baseDice + extra.baseDice
    contract.capped = contract.capped or extra.capped
    contract.formula = contract.formula .. "+" .. extra.formula
    contract.meteorState = state
    return contract
end

function Cross:ConsumeMeteor(contract)
    if contract and contract.meteorState then contract.meteorState.meteorUsed = true end
end

function Cross:BridgeMagicPush(actor, target, assembled, opts)
    if (tonumber(opts.distance) or 0) <= 0 or not opts.magicPush
        or not self:Owns(actor, "CROSS_FORCE_OF_WILL") then return assembled end
    opts.pusherFamilyEligible = true
    local extra, proc = Effects:TryPusherProc(actor, target, CurTime())
    if proc then opts.pushTagMultiplicity = (opts.pushTagMultiplicity or 1) + 1 end
    return assembled + extra
end

function Cross:RestoreBoomBattery(actor, contract)
    if not self:Owns(actor, "CROSS_BOOM_BATTERY") or contract.profile.magicDamage
        or contract.profile.magic or contract.profile.statusDamage then return 0 end
    local event = contract.attackEvent
    event.batterySeen = event.batterySeen or setmetatable({}, {__mode = "k"})
    if event.batterySeen[contract] then return 0 end
    event.batterySeen[contract] = true
    local before = math.min(5, math.floor((event.batteryContinuations or 0) / 2))
    event.batteryContinuations = (event.batteryContinuations or 0)
        + math.max(0, #contract.values - contract.baseDice)
    local award = math.min(5, math.floor(event.batteryContinuations / 2)) - before
    local magic = LOD.Magic
    local state = magic and magic._EnsureState and magic:_EnsureState(actor)
    if award <= 0 or not state then return 0 end
    local restored = math.min(award, math.max(0, 100 - state.magic))
    state.magic = state.magic + restored
    if restored > 0 then
        magic:_Sync(actor, state)
        local rolls = LOD.CombatRolls
        if actor:IsPlayer() then
            rolls:_Send(actor, 3, "BOOM BATTERY — +" .. restored .. " MAGIC", "resource",
                {event = "boom_battery", restored = restored})
        end
    end
    return restored
end

-- Eligibility must establish a usable source before weighting a draft. An
-- explosion unlock without its matching weapon is not a live capability.
local baseCapability = Progression._HasCapability
function Progression:_HasCapability(ps, state, tag)
    if tag ~= "exploding_nonmagic_damage_dice" then return baseCapability(self, ps, state, tag) end
    if not state or (state.actorType == "ai" and state.usesMagic ~= true) then return false end
    for _, value in ipairs(state.capabilityTags or {}) do if value == tag then return true end end
    local profile = Effects:ExplodingDiceProfile(state)
    for _, sides in ipairs({4, 6, 8, 10, 12, 20}) do
        local explodes = sides == 6 or sides == 12 or state.classId == "rogue" or profile.enabledBySides[sides]
        if explodes and self:_HasCapability(ps, state, "d" .. sides .. "_damage") then return true end
    end
    return false
end

assert(Feats.CROSS_METEOR_STRIKE == nil, "duplicate canonical feat CROSS_METEOR_STRIKE")
Feats.CROSS_METEOR_STRIKE = {
    featId = "CROSS_METEOR_STRIKE", displayName = "Meteor Strike", featFamilyId = "cross_meteor_strike", rankIndex = 1,
    governingAbilities = {"str", "int"}, abilityRequirements = {str = 15, int = 15},
    prerequisiteFeatIds = {"STR_CROWBAR_D6", "INT_CLOUD_STEP"}, requiredCapabilityTags = {"crowbar"},
    allowedActorTypes = {"hero", "human_soldier"}, incompatibleFeatIds = {}, requiredSubsystemTags = {},
    replacesLowerRank = false, repeatableFallback = false, oneRank = true, directorBaseWeight = 1,
    effectHandlerId = "cross_meteor_strike", synergyTags = {"crowbar"},
    effectParams = {description = [=[Once per airborne cycle, a Crowbar-family hit made after consuming Cloud Step's feat-granted second jump and before legitimate ground contact adds one extra 1d6 physical-damage chain and doubles that hit's Crowbar-origin push distance before other compatible push multipliers. The bonus d6 obeys the universal exploding rule. Missing the swing does not consume the once-per-airborne-cycle strike; landing resets it.]=]},
    eligibilityText = "STR 15 and INT 15 / Bash; Cloud Step", actorText = "Player-controlled heroes/human Soldiers with Crowbar-family access",
}
assert(Feats.CROSS_TINY_TERROR == nil, "duplicate canonical feat CROSS_TINY_TERROR")
Feats.CROSS_TINY_TERROR = {
    featId = "CROSS_TINY_TERROR", displayName = "Tiny Terror", featFamilyId = "cross_tiny_terror", rankIndex = 1,
    governingAbilities = {"dex", "cha"}, abilityRequirements = {dex = 15, cha = 15},
    prerequisiteFeatIds = {"DEX_SHRINK", "CHA_MENACE_1"}, requiredCapabilityTags = {"morale"},
    allowedActorTypes = {"hero", "human_soldier"}, incompatibleFeatIds = {}, requiredSubsystemTags = {},
    replacesLowerRank = false, repeatableFallback = false, oneRank = true, directorBaseWeight = 1,
    effectHandlerId = "cross_tiny_terror", synergyTags = {"morale"},
    effectParams = {description = [=[While Little Guy is active, MoraleDC gains an additional +2 against enemies within 2 graph cells of the actor. This stacks with the Menacing family but applies only at close range.]=]},
    eligibilityText = "DEX 15 and CHA 15 / Little Guy; Menacing", actorText = "Player-controlled heroes and human Soldiers",
}
assert(Feats.CROSS_BIG_SCARY == nil, "duplicate canonical feat CROSS_BIG_SCARY")
Feats.CROSS_BIG_SCARY = {
    featId = "CROSS_BIG_SCARY", displayName = "Big Scary", featFamilyId = "cross_big_scary", rankIndex = 1,
    governingAbilities = {"con", "str", "cha"}, abilityRequirements = {con = 15, str = 13, cha = 15},
    prerequisiteFeatIds = {"CON_BIG_GUY", "CHA_MENACE_1"}, requiredCapabilityTags = {"morale"},
    allowedActorTypes = {"hero", "human_soldier"}, incompatibleFeatIds = {}, requiredSubsystemTags = {},
    replacesLowerRank = false, repeatableFallback = false, oneRank = true, directorBaseWeight = 1,
    effectHandlerId = "cross_big_scary", synergyTags = {"morale"},
    effectParams = {description = [=[When this actor deals melee damage or a physical push/wall-crush event, that event's MoraleDC gains an additional +2. It stacks with the Menacing family and exists specifically to make an intimidating giant bruiser build possible without changing ordinary ranged intimidation.]=]},
    eligibilityText = "CON 15, STR 13, and CHA 15 / Big Guy; Menacing", actorText = "Player-controlled heroes and human Soldiers",
}
assert(Feats.CROSS_CRUSH_PANIC == nil, "duplicate canonical feat CROSS_CRUSH_PANIC")
Feats.CROSS_CRUSH_PANIC = {
    featId = "CROSS_CRUSH_PANIC", displayName = "Crash the Party", featFamilyId = "cross_crush_panic", rankIndex = 1,
    governingAbilities = {"str", "cha"}, abilityRequirements = {str = 17, cha = 17},
    prerequisiteFeatIds = {"STR_KNOCKBACK_1", "CHA_MENACE_2"}, requiredCapabilityTags = {"pushable_weapon", "morale"},
    allowedActorTypes = {"hero", "human_soldier", "ai"}, incompatibleFeatIds = {}, requiredSubsystemTags = {},
    replacesLowerRank = false, repeatableFallback = false, oneRank = true, directorBaseWeight = 1,
    effectHandlerId = "cross_crush_panic", synergyTags = {"pushable_weapon", "morale"},
    effectParams = {description = [=[A wall crush caused by this actor immediately requests a Morale check from the crushed target if it is otherwise morale-eligible, even if its normal one-second Morale recheck gate has not elapsed. This special request has a 3.0-second per-target cooldown. Other morale eligibility, immunity, and flee rules remain unchanged.]=]},
    eligibilityText = "STR 17 and CHA 17 / Pusher; Dreadful", actorText = "Heroes, human Soldiers, AI with physical push",
}
assert(Feats.CROSS_BOOM_BATTERY == nil, "duplicate canonical feat CROSS_BOOM_BATTERY")
Feats.CROSS_BOOM_BATTERY = {
    featId = "CROSS_BOOM_BATTERY", displayName = "Boom Battery", featFamilyId = "cross_boom_battery", rankIndex = 1,
    governingAbilities = {"dex", "int"}, abilityRequirements = {dex = 15, int = 15},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {"magic_pool", "exploding_nonmagic_damage_dice"},
    allowedActorTypes = {"hero", "human_soldier", "ai"}, incompatibleFeatIds = {}, requiredSubsystemTags = {},
    replacesLowerRank = false, repeatableFallback = false, oneRank = true, directorBaseWeight = 1,
    effectHandlerId = "cross_boom_battery", synergyTags = {"magic_pool", "exploding_nonmagic_damage_dice"},
    effectParams = {description = [=[Actor-owned non-Magic damage Boomchains may now feed Magic: every second continuation die generated by the same non-Magic attack restores 1 Magic, up to 5 Magic per attack event. This does not alter explosion thresholds and never raises Magic above 100.]=]},
    eligibilityText = "DEX 15 and INT 15 / Capability: exploding_nonmagic_damage_dice", actorText = "Heroes, human Soldiers, Magic-using AI",
}
assert(Feats.CROSS_FORCE_OF_WILL == nil, "duplicate canonical feat CROSS_FORCE_OF_WILL")
Feats.CROSS_FORCE_OF_WILL = {
    featId = "CROSS_FORCE_OF_WILL", displayName = "Force of Will", featFamilyId = "cross_force_of_will", rankIndex = 1,
    governingAbilities = {"str", "wis"}, abilityRequirements = {str = 15, wis = 15},
    prerequisiteFeatIds = {"STR_KNOCKBACK_1", "WIS_FORCEFUL_MAGIC"}, requiredCapabilityTags = {"magic_push", "pushable_weapon"},
    allowedActorTypes = {"hero", "human_soldier", "ai"}, incompatibleFeatIds = {}, requiredSubsystemTags = {},
    replacesLowerRank = false, repeatableFallback = false, oneRank = true, directorBaseWeight = 1,
    effectHandlerId = "cross_force_of_will", synergyTags = {"magic_push", "pushable_weapon"},
    effectParams = {description = [=[The actor's Magic-origin pushes are additionally eligible for Pusher/Shover/Space Hog processing as already-pushing events. Force Multiplier resolves first; then, only when that attacker-target pair is not inside the shared 0.50-second PusherProcTargetCooldown, the Pusher-family proc may add its +168-world-unit physical displacement on success, and any resulting valid wall slam uses the actor's active Pusher-family wall-slam die. Force of Will does not make non-pushing Magic damage eligible for a Pusher proc. This is an explicit bridge feat; without it the physical-weapon Pusher family and magic_push family remain separate.]=]},
    eligibilityText = "STR 15 and WIS 15 / Pusher; Force Multiplier", actorText = "Heroes, human Soldiers, eligible AI",
}
