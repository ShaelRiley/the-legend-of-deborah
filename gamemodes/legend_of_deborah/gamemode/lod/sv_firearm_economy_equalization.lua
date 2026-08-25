LOD = LOD or {}

local Specials = LOD.PlayerWeaponSpecials
local Loot = LOD.LootDirector

local FIREARMS = {
    "weapon_shotgun",
    "weapon_smg1",
    "weapon_357",
    "weapon_ar2"
}

local STATIC_REWARD_WEIGHTS = {
    weapon_shotgun = 1.0,
    weapon_smg1 = 1.0,
    weapon_357 = 1.0,
    weapon_ar2 = 1.0,
    weapon_frag = 0.55
}

local AMMO_PROFILES = {
    weapon_pistol = {ammo = "Pistol", cap = 54},
    weapon_shotgun = {ammo = "Buckshot", cap = 18},
    weapon_smg1 = {ammo = "SMG1", cap = 135},
    weapon_357 = {ammo = "357", cap = 18},
    weapon_ar2 = {ammo = "AR2", cap = 90}
}

local function weightedPick(rng, entries)
    local total = 0
    for _, entry in ipairs(entries or {}) do total = total + math.max(0, entry.weight or 0) end
    if total <= 0 then return nil end
    local roll = rng:Float(0, total)
    local cursor = 0
    for _, entry in ipairs(entries) do
        cursor = cursor + math.max(0, entry.weight or 0)
        if roll <= cursor then return entry.value end
    end
    return entries[#entries] and entries[#entries].value or nil
end

local function sameCell(a, b)
    return a and b and a.x == b.x and a.y == b.y and a.z == b.z
end

local function chooseDistinctTwo(rng)
    local pool = table.Copy(FIREARMS)
    local firstIndex = rng:Int(1, #pool)
    local first = table.remove(pool, firstIndex)
    local second = pool[rng:Int(1, #pool)]
    return first, second
end

if Loot and not Loot.LODEqualFirearmAvailabilityInstalled then
    Loot.LODEqualFirearmAvailabilityInstalled = true

    function Loot:_AllowedWeaponClasses()
        return table.Copy(FIREARMS)
    end

    function Loot:_MissingWeaponReward(ply, rng)
        local missing = {}
        for _, weaponClass in ipairs(FIREARMS) do
            if not IsValid(ply:GetWeapon(weaponClass)) then missing[#missing + 1] = weaponClass end
        end
        if #missing == 0 then return nil end
        return missing[rng:Int(1, #missing)]
    end

    -- Ammo drops are contextual only by depletion. No firearm family gets a
    -- built-in scarcity penalty; the weapon mechanic, magazine size and cap own
    -- the economy instead of a hidden rarity coefficient.
    function Loot:_ChooseAmmoFamily(ply, rng, preferredClass)
        local function usable(weaponClass)
            local profile = AMMO_PROFILES[weaponClass]
            if not profile then return false end
            local weapon = ply:GetWeapon(weaponClass)
            if not IsValid(weapon) then return false end
            if weaponClass == "weapon_pistol" and ply.LODM3InfiniteTestPistol == true then return false end
            local total = math.max(0, weapon:Clip1()) + math.max(0, ply:GetAmmoCount(profile.ammo))
            return total < profile.cap, total, profile
        end

        if preferredClass then
            local ok = usable(preferredClass)
            if ok then return preferredClass end
        end

        local choices = {}
        for weaponClass, profile in pairs(AMMO_PROFILES) do
            local ok, total = usable(weaponClass)
            if ok then
                local ratio = total / math.max(1, profile.cap)
                local weight = 0.35 + (1 - ratio) * 1.65
                if ratio < 0.50 then weight = weight * 2.25 end
                choices[#choices + 1] = {value = weaponClass, weight = weight}
            end
        end
        return weightedPick(rng, choices)
    end

    -- Preserve two guaranteed early firearm upgrades, but remove the old
    -- Shotgun/SMG privilege. Dungeon 1 deterministically chooses two distinct
    -- guns from the full four-gun pool with equal probability.
    local baseBuildStaticPlan = Loot.BuildStaticPlan
    function Loot:BuildStaticPlan(graph)
        local ok, plan = baseBuildStaticPlan(self, graph)
        if not ok then return ok, plan end

        local level = math.max(1, tonumber(plan.level) or 1)
        local levelSeed = plan.levelSeed or (LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed) or 1

        if level == 1 and graph and graph.Progression then
            local rng = LOD.RNG.New(LOD.Seeds.Derive(levelSeed, "loot-level1-equal-firearms"))
            local first, second = chooseDistinctTwo(rng)
            local cards = graph.Progression.Keycards or {}

            for _, node in ipairs(plan.nodes or {}) do
                if node.kind == "weapon" and node.payload then
                    if cards[1] and sameCell(node.cell, cards[1].cell) then
                        node.payload.weaponClass = first
                        node.equalFirearmGuarantee = 1
                    elseif cards[2] and sameCell(node.cell, cards[2].cell) then
                        node.payload.weaponClass = second
                        node.equalFirearmGuarantee = 2
                    end
                end
            end
        end

        -- The optional static reward also treats every gun equally. Grenades are
        -- still a separate consumable reward and therefore retain their own lower
        -- weight rather than joining the four-gun equality contract.
        local rewardRng = LOD.RNG.New(LOD.Seeds.Derive(levelSeed, "loot-static-equal-firearm-reward"))
        local choices = {}
        for weaponClass, weight in pairs(STATIC_REWARD_WEIGHTS) do
            choices[#choices + 1] = {value = weaponClass, weight = weight}
        end
        table.sort(choices, function(a, b) return a.value < b.value end)
        local rewardClass = weightedPick(rewardRng, choices)
        if rewardClass then
            for _, node in ipairs(plan.nodes or {}) do
                if node.kind == "weapon" and node.role == "reward" and node.payload then
                    node.payload.weaponClass = rewardClass
                    node.equalAvailabilityRolled = true
                    break
                end
            end
        end

        graph.LootPlan = plan
        self.StaticPlan = plan
        return true, plan
    end
end

if Specials and not Specials.LODOneRoundBurstEconomyInstalled then
    Specials.LODOneRoundBurstEconomyInstalled = true

    local AR2_TELEGRAPH = 0.45
    local AR2_BURST_SHOTS = 3
    local AR2_BURST_SPACING = 0.09
    local AR2_RECOVERY = 0.25
    local AR2_TELEGRAPH_SOUND = "buttons/button17.wav"

    local function activeWeapon(ply)
        if not IsValid(ply) then return nil end
        local weapon = ply:GetActiveWeapon()
        return IsValid(weapon) and weapon or nil
    end

    local function ar2StateFor(ply)
        local state = Specials.PlayerState[ply]
        if not state then
            state = {smg = {heat = 0}, ar2 = {attackHeld = false, active = false, readyAt = 0}}
            Specials.PlayerState[ply] = state
        end
        state.smg = state.smg or {heat = 0}
        state.ar2 = state.ar2 or {attackHeld = false, active = false, readyAt = 0}
        return state.ar2
    end

    function Specials:BeginAR2Burst(ply, weapon, direction)
        local ar2 = ar2StateFor(ply)
        local now = CurTime()

        if ar2.active or now < (ar2.readyAt or 0) then return false end
        if now < weapon:GetNextPrimaryFire() then return false end
        if weapon:Clip1() < 1 then
            weapon:EmitSound("Weapon_AR2.Empty", 62, 100, 0.72, CHAN_WEAPON)
            return false
        end

        direction = direction and direction:GetNormalized() or ply:GetAimVector():GetNormalized()
        if direction == vector_origin then return false end

        ar2.active = true
        ar2.weapon = weapon
        ar2.direction = direction
        ar2.fireAt = now + AR2_TELEGRAPH
        ar2.nextShotAt = ar2.fireAt
        ar2.shotsFired = 0
        ar2.readyAt = ar2.fireAt + (AR2_BURST_SHOTS - 1) * AR2_BURST_SPACING + AR2_RECOVERY

        weapon:SetNextPrimaryFire(ar2.readyAt)
        ply:SetNW2Vector("LOD_PlayerAR2Direction", direction)
        ply:SetNW2Float("LOD_PlayerAR2TelegraphUntil", ar2.fireAt)
        ply:SetNW2Bool("LOD_PlayerAR2Telegraph", true)
        weapon:EmitSound(AR2_TELEGRAPH_SOUND, 62, 115, 0.66, CHAN_ITEM)
        self.Stats.ar2Bursts = (self.Stats.ar2Bursts or 0) + 1
        return true
    end

    function Specials:FireAR2Round(ply, ar2)
        local weapon = ar2.weapon
        if not IsValid(ply) or not ply:Alive() or not IsValid(weapon) then return false end
        if activeWeapon(ply) ~= weapon or weapon:GetClass() ~= "weapon_ar2" then return false end

        -- One ammunition unit buys the complete authored three-projectile burst.
        -- Spend that unit only when the first projectile actually releases, so a
        -- telegraph cancelled by death/weapon switch does not consume ammo.
        if (ar2.shotsFired or 0) == 0 then
            if weapon:Clip1() <= 0 then return false end
            weapon:SetClip1(math.max(0, weapon:Clip1() - 1))
        end

        weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        ply:SetAnimation(PLAYER_ATTACK1)
        ply:MuzzleFlash()
        weapon:EmitSound("Weapon_AR2.Single", 72, 100, 0.88, CHAN_WEAPON)
        ply:ViewPunch(Angle(-0.35, 0, 0))

        local direction = ar2.direction:GetNormalized()
        local bullet = {
            Num = 1,
            Src = ply:GetShootPos(),
            Dir = direction,
            Spread = vector_origin,
            Tracer = 1,
            TracerName = "AR2Tracer",
            Force = 4,
            Damage = 1,
            AmmoType = "AR2",
            Attacker = ply,
            Inflictor = weapon
        }

        ply:LagCompensation(true)
        ply:FireBullets(bullet)
        ply:LagCompensation(false)

        self.Stats.ar2Rounds = (self.Stats.ar2Rounds or 0) + 1
        return true
    end
end
