LOD = LOD or {}
LOD.HeroAbilityRolls = LOD.HeroAbilityRolls or {}

local Rolls = LOD.HeroAbilityRolls
local Progression = LOD.CharacterProgressionSystem
local RPG = LOD.RPG
local ABILITIES = {"str", "dex", "con", "int", "wis", "cha"}

Rolls.ExpectedScoreMean = 12.244598765432098
Rolls.ExpectedTotalMean = Rolls.ExpectedScoreMean * #ABILITIES
Rolls.MinimumAcceptedTotal = math.ceil(Rolls.ExpectedTotalMean)
Rolls.MaxGenerationAttempts = 256

local function roll4d6DropLowest(rng)
    local total = 0
    local lowest, dice = 7, {}
    for _ = 1, 4 do
        local value = rng:Int(1, 6)
        dice[#dice + 1] = value
        total = total + value
        if value < lowest then lowest = value end
    end
    return total - lowest, dice
end

function Rolls:ApplyWeakness(abilities, seed)
    local order = {}; for i, ability in ipairs(ABILITIES) do order[i] = ability end
    local tieRng = LOD.RNG.New(LOD.Seeds.Derive(seed, "hero-ability:tiebreak"))
    tieRng:Shuffle(order)
    local tieOrder = {}; for i, ability in ipairs(order) do tieOrder[ability] = i end
    table.sort(order, function(a, b)
        if abilities[a] == abilities[b] then return tieOrder[a] < tieOrder[b] end
        return abilities[a] < abilities[b]
    end)
    local penaltyRng = LOD.RNG.New(LOD.Seeds.Derive(seed, "hero-ability:weakness"))
    local dice = {{penaltyRng:Int(1, 2), penaltyRng:Int(1, 2)},
        {penaltyRng:Int(1, 3)}, {penaltyRng:Int(1, 3)}}
    local post, penalties, total = {}, {}, 0
    for _, ability in ipairs(ABILITIES) do post[ability] = abilities[ability] end
    for i = 1, 3 do
        local amount = 0; for _, value in ipairs(dice[i]) do amount = amount + value end
        post[order[i]] = post[order[i]] - amount
        penalties[i] = {ability = order[i], dice = dice[i], amount = amount, before = abilities[order[i]], after = post[order[i]]}
    end
    for _, value in pairs(post) do total = total + value end
    return post, total, penalties
end

function Rolls:Generate(seed)
    local rng = LOD.RNG.New(seed)
    for attempt = 1, self.MaxGenerationAttempts do
        local abilities = RPG.NewAbilityBlock(0)
        local total, rawDice = 0, {}
        for _, ability in ipairs(ABILITIES) do
            local score, dice = roll4d6DropLowest(rng)
            rawDice[ability] = dice
            abilities[ability] = score
            total = total + score
        end
        if total >= self.ExpectedTotalMean then
            local post, postTotal, penalties = self:ApplyWeakness(abilities, seed)
            return post, postTotal, attempt, {rawAbilities = abilities, rawDice = rawDice, rawTotal = total, penalties = penalties}
        end
    end
    error("hero ability generation exceeded attempt safety bound")
end

function Rolls:SeedForHero(runManager, ps)
    local rosterSeed = assert(runManager and runManager.State and runManager.State.RosterSeed,
        "RosterSeed must exist before hero ability generation")
    return LOD.Seeds.Derive(rosterSeed,
        "rpg:hero_ability_rolls:" .. tostring(ps and ps.identity or "unknown"))
end

local function formatAbilities(values)
    return string.format("STR=%d DEX=%d CON=%d INT=%d WIS=%d CHA=%d",
        values.str or 0, values.dex or 0, values.con or 0,
        values.int or 0, values.wis or 0, values.cha or 0)
end

if Progression and Progression.InitializeHero and not Rolls.Wrapped then
    Rolls.Wrapped = true
    Rolls.BaseInitializeHero = Progression.InitializeHero

    function Progression:InitializeHero(runManager, ps, character)
        if not ps then return nil end
        local existing = ps.progressionState
        local state = Rolls.BaseInitializeHero(self, runManager, ps, character)
        if not state or existing then return state end

        local seed = Rolls:SeedForHero(runManager, ps)
        local abilities, total, attempts, audit = Rolls:Generate(seed)
        state.baseAbilities = abilities
        state.baseAbilityRollTotal = total
        state.baseAbilityRollAttempts = attempts
        state.baseAbilityRollMethod = "4d6_drop_lowest_74_then_weakness"
        state.baseAbilityRollAudit = audit
        self:_RecomputeProgressionState(state)

        local testLog = LOD.RPGTestLog
        if testLog and testLog.Write then
            testLog:Write("HERO_ABILITY_ROLL", {
                player = tostring(ps.identity or ""),
                total = total,
                rawTotal = audit.rawTotal,
                weakness = audit.penalties,
                attempts = attempts,
                str = abilities.str,
                dex = abilities.dex,
                con = abilities.con,
                int = abilities.int,
                wis = abilities.wis,
                cha = abilities.cha
            })
        end

        local detail = {}
        for _, ability in ipairs(ABILITIES) do
            detail[#detail + 1] = string.upper(ability) .. " 4d6[" .. table.concat(audit.rawDice[ability], "+")
                .. "] drop lowest = " .. audit.rawAbilities[ability]
        end
        for i, penalty in ipairs(audit.penalties) do
            detail[#detail + 1] = string.format("%s %d - %s[%s] = %d", string.upper(penalty.ability),
                penalty.before, i == 1 and "2d2" or "1d3", table.concat(penalty.dice, "+"), penalty.after)
        end
        local message = string.format("Starting abilities: raw total %d >= 74; %s; final total %d. No post-weakness reroll.",
            audit.rawTotal, table.concat(detail, "; "), total)
        local ply = runManager.ConnectedPlayerForIdentity and runManager:ConnectedPlayerForIdentity(ps.identity)
        if IsValid(ply) and LOD.CombatRolls and LOD.CombatRolls._Send then
            LOD.CombatRolls:_Send(ply, 3, message, "progression", {event = "hero_ability_roll", raw_total = audit.rawTotal, total = total})
        end
        print("[LOD:RPG-ABILITIES] " .. message)
        return state
    end
end

concommand.Add("lod_rpg_ability_roll_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local a1, total1, _, audit = Rolls:Generate(123456789)
    local a2, total2 = Rolls:Generate(123456789)
    local ok = audit.rawTotal >= Rolls.MinimumAcceptedTotal and total1 == total2
    for _, ability in ipairs(ABILITIES) do
        ok = ok and a1[ability] >= -1 and a1[ability] <= 18 and a1[ability] == a2[ability]
    end

    local line = string.format(
        "Hero ability roll validation %s - method=4d6-drop-lowest-then-weakness meanTotal=%.4f minimumAccepted=%d sampleTotal=%d %s",
        ok and "PASS" or "FAILED", Rolls.ExpectedTotalMean, Rolls.MinimumAcceptedTotal,
        total1, formatAbilities(a1))
    print("[LOD:RPG-ABILITIES] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
