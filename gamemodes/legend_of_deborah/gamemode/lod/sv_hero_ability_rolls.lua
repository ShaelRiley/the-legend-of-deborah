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
    local lowest = 7
    for _ = 1, 4 do
        local value = rng:Int(1, 6)
        total = total + value
        if value < lowest then lowest = value end
    end
    return total - lowest
end

function Rolls:Generate(seed)
    local rng = LOD.RNG.New(seed)
    for attempt = 1, self.MaxGenerationAttempts do
        local abilities = RPG.NewAbilityBlock(0)
        local total = 0
        for _, ability in ipairs(ABILITIES) do
            local score = roll4d6DropLowest(rng)
            abilities[ability] = score
            total = total + score
        end
        if total >= self.ExpectedTotalMean then
            return abilities, total, attempt
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
        local abilities, total, attempts = Rolls:Generate(seed)
        state.baseAbilities = abilities
        state.baseAbilityRollTotal = total
        state.baseAbilityRollAttempts = attempts
        state.baseAbilityRollMethod = "4d6_drop_lowest_reroll_below_average_total"
        self:_RecomputeProgressionState(state)

        local testLog = LOD.RPGTestLog
        if testLog and testLog.Write then
            testLog:Write("HERO_ABILITY_ROLL", {
                player = tostring(ps.identity or ""),
                total = total,
                attempts = attempts,
                str = abilities.str,
                dex = abilities.dex,
                con = abilities.con,
                int = abilities.int,
                wis = abilities.wis,
                cha = abilities.cha
            })
        end

        print(string.format("[LOD:RPG-ABILITIES] generated %s total=%d attempts=%d minimum=%d",
            formatAbilities(abilities), total, attempts, Rolls.MinimumAcceptedTotal))
        return state
    end
end

concommand.Add("lod_rpg_ability_roll_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local a1, total1 = Rolls:Generate(123456789)
    local a2, total2 = Rolls:Generate(123456789)
    local ok = total1 >= Rolls.MinimumAcceptedTotal and total1 == total2
    for _, ability in ipairs(ABILITIES) do
        ok = ok and a1[ability] >= 3 and a1[ability] <= 18 and a1[ability] == a2[ability]
    end

    local line = string.format(
        "Hero ability roll validation %s - method=4d6-drop-lowest meanTotal=%.4f minimumAccepted=%d sampleTotal=%d %s",
        ok and "PASS" or "FAILED", Rolls.ExpectedTotalMean, Rolls.MinimumAcceptedTotal,
        total1, formatAbilities(a1))
    print("[LOD:RPG-ABILITIES] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
