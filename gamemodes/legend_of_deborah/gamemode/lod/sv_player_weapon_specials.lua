LOD = LOD or {}
LOD.PlayerWeaponSpecials = LOD.PlayerWeaponSpecials or {}

local Specials = LOD.PlayerWeaponSpecials

local TICK = 0.05

local SMG_MAX_HEAT = 6
local SMG_COOL_INTERVAL = 0.25
local SMG_OVERHEAT_LOCK = 2.0
local SMG_WARM_STAGE = 3
local SMG_NEAR_STAGE = 5

local AR2_TELEGRAPH = 0.45
local AR2_BASE_BURST_SHOTS = 3
local AR2_BURST_SPACING = 0.09
local AR2_RECOVERY = 0.25

Specials.SMGConfig = {
    baselineThreshold = SMG_MAX_HEAT,
    coolInterval = SMG_COOL_INTERVAL,
    overheatLock = SMG_OVERHEAT_LOCK,
    warmStage = SMG_WARM_STAGE,
    nearStage = SMG_NEAR_STAGE
}
Specials.SMGHeatFeatAuthority = "gate_e_batch_8_dex_smg_heat_v1"

Specials.AR2Config = {
    telegraph = AR2_TELEGRAPH,
    baseBurstShots = AR2_BASE_BURST_SHOTS,
    burstSpacing = AR2_BURST_SPACING,
    recovery = AR2_RECOVERY,
    ammoPerTriggerBurst = 1,
    multiFireBurst = true
}

local SMG_WARM_SOUND = "legend_of_deborah/feedback/heat_warm.wav"
local SMG_NEAR_SOUND = "legend_of_deborah/feedback/heat_near.wav"
local SMG_OVERHEAT_SOUND = "ambient/machines/steam_release_2.wav"
local SMG_COOL_SOUND = "ambient/machines/steam_release_1.wav"
local SMG_READY_SOUND = "legend_of_deborah/feedback/weapon_ready.wav"
local AR2_TELEGRAPH_SOUND = "legend_of_deborah/feedback/ar2_warning.wav"

Specials.PlayerState = Specials.PlayerState or setmetatable({}, {__mode = "k"})
Specials.Stats = Specials.Stats or {
    smgShots = 0,
    smgOverheats = 0,
    ar2Bursts = 0,
    ar2Rounds = 0
}
Specials.Stats.lastAR2BurstRounds = Specials.Stats.lastAR2BurstRounds or 0
Specials.Stats.lastAR2BurstTarget = Specials.Stats.lastAR2BurstTarget or 0
Specials.Stats.lastAR2BurstDesired = Specials.Stats.lastAR2BurstDesired or 0
Specials.Stats.ar2AmmoCommitted = Specials.Stats.ar2AmmoCommitted or 0

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return IsValid(ply) and ply:IsAdmin()
end

local function stateFor(ply)
    local state = Specials.PlayerState[ply]
    if not state then
        state = {
            smg = {heat = 0},
            ar2 = {attackHeld = false, active = false, readyAt = 0}
        }
        Specials.PlayerState[ply] = state
    end
    state.smg = state.smg or {heat = 0}
    state.ar2 = state.ar2 or {attackHeld = false, active = false, readyAt = 0}
    return state
end

local function activeWeapon(ply)
    if not IsValid(ply) then return nil end
    local weapon = ply:GetActiveWeapon()
    return IsValid(weapon) and weapon or nil
end

local function clearAR2Network(ply)
    if not IsValid(ply) then return end
    ply:SetNW2Bool("LOD_PlayerAR2Telegraph", false)
    ply:SetNW2Vector("LOD_PlayerAR2Direction", vector_origin)
    ply:SetNW2Float("LOD_PlayerAR2TelegraphUntil", 0)
end

-- SPOT-16: only the exact disposable Soldier loadout owns infinite ammunition.
-- These bindings live in the existing per-player weapon state and service.
function Specials:IsSoldierAR2Actor(ply)
    local run = LOD.RunManager
    return IsValid(ply) and ((run and run:IsSoldierControl(ply))
        or ply.LODHumanSoldierProgressionState ~= nil) or false
end

function Specials:SoldierAR2BindingValid(ply, binding)
    local run, system = LOD.RunManager, LOD.SoldierProgression
    local s = run and run.State
    if not binding or not s or not system or not IsValid(ply) or not ply:IsPlayer()
        or not ply:Alive() or ply.LODHandledRunDeath or not run:IsSoldierControl(ply)
        or s ~= binding.run or s.Graph ~= binding.graph or s.LevelSeed ~= binding.seed
        or s.CampaignEpoch ~= binding.epoch or s.CampaignSeed ~= binding.campaignSeed
        or s.Level ~= binding.level or s.RunId ~= binding.runId
        or not s.BuildReady or not s.Graph or s.Failed or s.LevelCleared or s.SimulationFrozen
        or run:GetPlayerState(ply) ~= binding.ps or ply.LODRunSpawnSerial ~= binding.life
        or system:StateFor(ply) ~= binding.progression or not binding.progression.soldierIncarnation
        or ply:GetObserverMode() ~= OBS_MODE_NONE or ply:GetNW2Bool("LOD_Staged", false)
        or not ply:GetNW2Bool("LOD_Deployed", false) then return false end
    local weapon = binding.weapon
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_ar2" or weapon:GetOwner() ~= ply
        or ply:GetWeapon("weapon_ar2") ~= weapon or activeWeapon(ply) ~= weapon then return false end
    local state = self.PlayerState[ply]
    if not state or state.soldierLoadout ~= binding then return false end
    if not run:CanChangeTeam(ply) then return false end -- shared minigame/clock admission
    local status = LOD.RPGStatusElements
    return (not status or status:CanInitiateAttack(ply))
        and CurTime() >= (ply.LODHitStunUntil or 0)
end

function Specials:BindSoldierRifle(ply, weapon)
    self:ResetPlayer(ply)
    local run, system = LOD.RunManager, LOD.SoldierProgression
    local s = run and run.State
    local progression = system and system:StateFor(ply)
    if not s or not progression or not IsValid(weapon) then return false end
    local binding = {run=s, graph=s.Graph, seed=s.LevelSeed, epoch=s.CampaignEpoch,
        campaignSeed=s.CampaignSeed, level=s.Level, runId=s.RunId,
        ps=run:GetPlayerState(ply), life=ply.LODRunSpawnSerial,
        progression=progression, weapon=weapon}
    stateFor(ply).soldierLoadout = binding
    return true
end

function Specials:AR2SourceAllowed(ply, weapon, ar2)
    local binding = ar2 and ar2.soldierBinding
    if binding or self:IsSoldierAR2Actor(ply) then
        local state = self.PlayerState[ply]
        binding = binding or (not ar2 and state and state.soldierLoadout)
        return self:SoldierAR2BindingValid(ply, binding)
            and binding.weapon == weapon and (not ar2 or state.ar2 == ar2), binding
    end
    return true, nil -- Ordinary Hero rifles retain their existing finite transaction.
end

function Specials:CancelSoldierAR2(ply, state)
    if self.PlayerState[ply] ~= state then return end
    local old = state.ar2 or {}
    state.ar2 = {active=false, attackHeld=old.attackHeld, readyAt=old.readyAt or 0}
    local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    if effects and effects.AR2RateOfFirePlans then effects.AR2RateOfFirePlans[ply] = nil end
    clearAR2Network(ply)
    if LOD.SoldierMovement then LOD.SoldierMovement:ClearProjection(ply) end
end

-- The existing burst is the only owner, including final cadence-adjusted recovery.
function Specials:SoldierMovementLock(ply)
    local state = self.PlayerState[ply]
    local ar2 = state and state.ar2
    if not ar2 or not ar2.soldierBinding then return false, 0 end
    local now = CurTime()
    if not self:AR2SourceAllowed(ply, ar2.weapon, ar2)
        or (ar2.active and now - (ar2.nextShotAt or math.huge) > 0.20) then
        self:CancelSoldierAR2(ply, state)
        return false, 0
    end
    local deadline = tonumber(ar2.readyAt) or 0
    local locked = ar2.active == true or now < deadline
    return locked, locked and math.max(deadline, now + (ar2.active and TICK or 0)) or 0
end

local function syncSMG(weapon, smg)
    if not IsValid(weapon) then return end
    local threshold = math.Clamp(math.floor(tonumber(smg.threshold) or SMG_MAX_HEAT),
        SMG_MAX_HEAT, 12)
    weapon:SetNW2Float("LOD_SMGHeat", math.Clamp(smg.heat or 0, 0, threshold))
    weapon:SetNW2Bool("LOD_SMGOverheated", (smg.overheatedUntil or 0) > CurTime())
end

-- AR2 ammo units are trigger bursts, not projectiles. Resolve projectile count from
-- authored burst state only; Clip1 is checked/charged separately at burst commit.
local function resolveAR2BurstTarget(ply)
    local rules = LOD.RPGAbilityRules
    local bonus = rules and isfunction(rules.BurstBonusRounds)
        and rules:BurstBonusRounds(ply)
        or (rules and isfunction(rules.BurstSizeBonus) and rules:BurstSizeBonus(ply) or 0)
    if rules and isfunction(rules.ResolveBurstCount) then
        return rules:ResolveBurstCount(AR2_BASE_BURST_SHOTS, bonus), bonus
    end
    return AR2_BASE_BURST_SHOTS + math.max(0, math.floor(tonumber(bonus) or 0)), bonus
end

function Specials:ResetPlayer(ply)
    local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    if effects and effects.AR2RateOfFirePlans then effects.AR2RateOfFirePlans[ply] = nil end
    local state = self.PlayerState[ply]
    if state and state.smg and IsValid(state.smg.weapon) then
        state.smg.weapon:SetNW2Float("LOD_SMGHeat", 0)
        state.smg.weapon:SetNW2Bool("LOD_SMGOverheated", false)
    end
    clearAR2Network(ply)
    self.PlayerState[ply] = nil
    if LOD.SoldierMovement then LOD.SoldierMovement:ClearProjection(ply) end
end

function Specials:ResetSMGState(ply)
    local state = stateFor(ply)
    local previous = state.smg or {}
    if IsValid(previous.weapon) then
        previous.weapon:SetNW2Float("LOD_SMGHeat", 0)
        previous.weapon:SetNW2Bool("LOD_SMGOverheated", false)
    end
    state.smg = {heat = 0, threshold = SMG_MAX_HEAT}
    return state.smg
end

function Specials:OnSMGShot(ply, weapon)
    local state = stateFor(ply)
    local smg = state.smg
    local now = CurTime()

    if (smg.overheatedUntil or 0) > now then return end

    local rules = LOD.RPGAbilityRules
    local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    local chance = rules and isfunction(rules.SMGHeatSuppressionChance)
        and rules:SMGHeatSuppressionChance(ply) or 0
    local threshold = rules and isfunction(rules.SMGOverheatThreshold)
        and rules:SMGOverheatThreshold(ply) or SMG_MAX_HEAT
    local suppressed, roll = false, 1
    if effects and isfunction(effects.ResolveSMGHeatSuppression) then
        suppressed, roll = effects:ResolveSMGHeatSuppression(ply, chance)
    end

    local previous = smg.heat or 0
    smg.weapon = weapon
    smg.threshold = threshold
    smg.suppressionChance = chance
    smg.heat = math.min(threshold, previous + (suppressed and 0 or 1))
    smg.nextCoolAt = now + SMG_COOL_INTERVAL
    smg.lastShotAt = now
    self.Stats.smgShots = (self.Stats.smgShots or 0) + 1

    if previous < SMG_WARM_STAGE and smg.heat >= SMG_WARM_STAGE then
        weapon:EmitSound(SMG_WARM_SOUND, 56, 118, 0.46, CHAN_ITEM)
    end
    if previous < SMG_NEAR_STAGE and smg.heat >= SMG_NEAR_STAGE then
        weapon:EmitSound(SMG_NEAR_SOUND, 62, 132, 0.62, CHAN_ITEM)
    end

    local overheated = smg.heat >= threshold
    if overheated then
        smg.overheatedUntil = now + SMG_OVERHEAT_LOCK
        smg.coolCueAt = now + 0.85
        smg.coolCuePlayed = false
        weapon:SetNextPrimaryFire(smg.overheatedUntil)
        weapon:SetNextSecondaryFire(smg.overheatedUntil)
        weapon:EmitSound(SMG_OVERHEAT_SOUND, 70, 112, 0.78, CHAN_WEAPON)
        self.Stats.smgOverheats = (self.Stats.smgOverheats or 0) + 1
    end

    if effects and isfunction(effects.RecordSMGHeatShot) then
        effects:RecordSMGHeatShot(ply, {
            roll = roll,
            chance = chance,
            suppressed = suppressed,
            heat = smg.heat,
            threshold = threshold,
            overheated = overheated,
            lockSeconds = overheated and SMG_OVERHEAT_LOCK or 0
        })
    end

    syncSMG(weapon, smg)
end

local function finishAR2(ply, ar2, cooldown)
    local rounds = math.max(0, math.floor(tonumber(ar2.shotsFired) or 0))
    local target = math.max(0, math.floor(tonumber(ar2.targetShots) or 0))
    local bonus = math.max(0, math.floor(tonumber(ar2.burstSizeBonus) or 0))
    Specials.Stats.lastAR2BurstRounds = rounds
    Specials.Stats.lastAR2BurstTarget = target
    Specials.Stats.lastAR2BurstDesired = target

    local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    if effects and isfunction(effects.RecordBurstSizeResult) and target > 0 then
        effects:RecordBurstSizeResult(
            ply, "weapon_ar2", rounds, AR2_BASE_BURST_SHOTS, target, bonus)
    end

    ar2.active = false
    ar2.shotsFired = 0
    ar2.targetShots = nil
    ar2.desiredShots = nil
    ar2.burstSizeBonus = nil
    ar2.ammoCommitted = nil
    ar2.fireAt = nil
    ar2.nextShotAt = nil
    ar2.direction = nil
    ar2.readyAt = CurTime() + (cooldown or AR2_RECOVERY)
    if IsValid(ar2.weapon) then
        ar2.weapon:SetNextPrimaryFire(ar2.readyAt)
    end
    clearAR2Network(ply)
    if LOD.SoldierMovement then LOD.SoldierMovement:Publish(ply) end
end

function Specials:BeginAR2Burst(ply, weapon, direction)
    local allowed, soldierBinding = self:AR2SourceAllowed(ply, weapon)
    if not allowed then return false end
    local state = stateFor(ply)
    local ar2 = state.ar2
    local now = CurTime()

    if ar2.active or now < (ar2.readyAt or 0) then return false end
    if now < weapon:GetNextPrimaryFire() then return false end

    -- Ordinary Hero bursts cost one AR2 round total. Only an exactly bound
    -- SPOT-16 Soldier loadout bypasses that cost; committed projectile resolution
    -- is independent of later Clip1/reserve changes.
    if not soldierBinding and weapon:Clip1() < 1 then
        weapon:EmitSound("Weapon_AR2.Empty", 62, 100, 0.72, CHAN_WEAPON)
        return false
    end

    direction = direction and direction:GetNormalized() or ply:GetAimVector():GetNormalized()
    if direction == vector_origin then return false end

    local targetShots, burstSizeBonus = resolveAR2BurstTarget(ply)

    -- Commit the one ammunition unit only after every pre-burst validity check.
    if not soldierBinding then
        weapon:SetClip1(math.max(0, weapon:Clip1() - 1))
        self.Stats.ar2AmmoCommitted = (self.Stats.ar2AmmoCommitted or 0) + 1
    end

    ar2.attackEvent = {}
    ar2.active = true
    ar2.weapon = weapon
    ar2.direction = direction
    ar2.fireAt = now + AR2_TELEGRAPH
    ar2.nextShotAt = ar2.fireAt
    ar2.shotsFired = 0
    ar2.targetShots = targetShots
    ar2.desiredShots = targetShots
    ar2.burstSizeBonus = burstSizeBonus
    ar2.ammoCommitted = soldierBinding and 0 or 1
    ar2.soldierBinding = soldierBinding
    ar2.readyAt = ar2.fireAt + (targetShots - 1) * AR2_BURST_SPACING + AR2_RECOVERY
    if LOD.SoldierMovement then LOD.SoldierMovement:Publish(ply) end

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
    if not self:AR2SourceAllowed(ply, weapon, ar2) then return false end
    if not ar2.soldierBinding and ar2.ammoCommitted ~= 1 then return false end

    -- No Clip1 check/decrement here. The trigger burst already paid exactly one
    -- AR2 round at commit, and all authored/feat-added projectiles are free inside
    -- that committed burst.
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

    -- Presentation hooks above may retire or replace the body. Recheck at firing.
    if not self:AR2SourceAllowed(ply, weapon, ar2) then return false end
    ply:LagCompensation(true)
    local previousEvent = ply.LODCommittedAttackEvent
    ply.LODCommittedAttackEvent = ar2.attackEvent
    local ok, err = xpcall(function() ply:FireBullets(bullet) end, debug.traceback)
    ply.LODCommittedAttackEvent = previousEvent
    ply:LagCompensation(false)
    if not ok then ErrorNoHalt("[LOD:AR2] " .. tostring(err) .. "\n"); return false end

    self.Stats.ar2Rounds = (self.Stats.ar2Rounds or 0) + 1
    return true
end

function Specials:ProcessPlayer(ply, state, now)
    if not IsValid(ply) then return end

    local smg = state.smg
    if smg then
        local weapon = smg.weapon
        if (smg.overheatedUntil or 0) > 0 then
            if now < smg.overheatedUntil then
                if not smg.coolCuePlayed and now >= (smg.coolCueAt or math.huge) then
                    smg.coolCuePlayed = true
                    if IsValid(weapon) then
                        weapon:EmitSound(SMG_COOL_SOUND, 60, 105, 0.54, CHAN_ITEM)
                    end
                end
            else
                smg.overheatedUntil = nil
                smg.coolCueAt = nil
                smg.coolCuePlayed = nil
                smg.heat = 0
                smg.nextCoolAt = nil
                if IsValid(weapon) then
                    syncSMG(weapon, smg)
                    weapon:EmitSound(SMG_READY_SOUND, 58, 126, 0.54, CHAN_ITEM)
                end
            end
        elseif (smg.heat or 0) > 0 and now >= (smg.nextCoolAt or math.huge) then
            while smg.heat > 0 and now >= smg.nextCoolAt do
                smg.heat = smg.heat - 1
                smg.nextCoolAt = smg.nextCoolAt + SMG_COOL_INTERVAL
            end
            if smg.heat <= 0 then smg.nextCoolAt = nil end
            if IsValid(weapon) then syncSMG(weapon, smg) end
        end
    end

    local ar2 = state.ar2
    if ar2 and ar2.active then
        if ar2.soldierBinding and (self.PlayerState[ply] ~= state
            or not self:AR2SourceAllowed(ply, ar2.weapon, ar2)
            or now - (ar2.nextShotAt or math.huge) > 0.20) then
            self:CancelSoldierAR2(ply, state)
            return
        end
        local weapon = ar2.weapon
        if not ply:Alive() or not IsValid(weapon) or activeWeapon(ply) ~= weapon then
            finishAR2(ply, ar2, 0.15)
            return
        end

        if now >= (ar2.fireAt or math.huge) then
            ply:SetNW2Bool("LOD_PlayerAR2Telegraph", false)
            local targetShots = math.max(1,
                math.floor(tonumber(ar2.targetShots) or AR2_BASE_BURST_SHOTS))
            while ar2.shotsFired < targetShots and now >= (ar2.nextShotAt or math.huge) do
                if not self:FireAR2Round(ply, ar2) then
                    if ar2.soldierBinding then self:CancelSoldierAR2(ply, state)
                    else finishAR2(ply, ar2, 0.15) end
                    return
                end
                if ar2.soldierBinding and not self:AR2SourceAllowed(ply, weapon, ar2) then
                    self:CancelSoldierAR2(ply, state)
                    return
                end
                ar2.shotsFired = ar2.shotsFired + 1
                ar2.nextShotAt = ar2.nextShotAt + AR2_BURST_SPACING
                if ar2.soldierBinding then break end -- no backlog release after a service stall
            end

            if ar2.shotsFired >= targetShots then
                finishAR2(ply, ar2, AR2_RECOVERY)
            end
        end
    end
    if LOD.SoldierMovement then LOD.SoldierMovement:Publish(ply) end
end

hook.Add("EntityFireBullets", "LOD_PlayerWeaponSpecials_SMGHeat", function(shooter)
    if not IsValid(shooter) or not shooter:IsPlayer() then return end
    local weapon = activeWeapon(shooter)
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_smg1" then return end
    Specials:OnSMGShot(shooter, weapon)
end)

hook.Add("StartCommand", "LOD_PlayerWeaponSpecials_Input", function(ply, cmd)
    if LOD.Equipment and LOD.Equipment.ObserveStatueInput then LOD.Equipment:ObserveStatueInput(ply,cmd) end
    if not IsValid(ply) or not ply:Alive() then return end
    if LOD.SoldierMovement then LOD.SoldierMovement:FilterInput(ply, cmd) end
    local state = stateFor(ply)
    local weapon = activeWeapon(ply)
    local class = IsValid(weapon) and weapon:GetClass() or ""

    if class == "weapon_smg1" and (state.smg.overheatedUntil or 0) > CurTime() then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    end

    local ar2 = state.ar2
    if class == "weapon_ar2" then
        local down = cmd:KeyDown(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK)
        if ar2.active or Specials:IsSoldierAR2Actor(ply) then cmd:RemoveKey(IN_RELOAD) end
        if Specials:IsSoldierAR2Actor(ply) then cmd:RemoveKey(IN_ATTACK2) end

        if down and not ar2.attackHeld then
            local direction = cmd:GetViewAngles():Forward()
            Specials:BeginAR2Burst(ply, weapon, direction)
        end
        ar2.attackHeld = down
    else
        ar2.attackHeld = false
    end
end)

timer.Create("LOD_PlayerWeaponSpecialsTick", TICK, 0, function()
    local now = CurTime()
    for ply, state in pairs(Specials.PlayerState) do
        if IsValid(ply) then Specials:ProcessPlayer(ply, state, now) end
    end
end)

hook.Add("PlayerSwitchWeapon", "LOD_PlayerWeaponSpecials_SoldierSwitch", function(ply, old, new)
    local state = Specials.PlayerState[ply]
    if state and state.ar2 and state.ar2.soldierBinding and old ~= new then
        Specials:CancelSoldierAR2(ply, state)
    end
end)

hook.Add("PlayerDeath", "LOD_PlayerWeaponSpecials_ResetDeath", function(ply)
    Specials:ResetPlayer(ply)
end)

hook.Add("PlayerDisconnected", "LOD_PlayerWeaponSpecials_ResetDisconnect", function(ply)
    Specials:ResetPlayer(ply)
end)

hook.Add("PlayerSpawn", "LOD_PlayerWeaponSpecials_ResetSpawn", function(ply)
    Specials:ResetPlayer(ply)
end)

concommand.Add("lod_weapon_specials_testkit", function(ply)
    if not developerAllowed(ply) or not ply:Alive() then return end

    local smg = ply:Give("weapon_smg1", true)
    if IsValid(smg) then smg:SetClip1(45) end
    ply:SetAmmo(45, "SMG1")

    local ar2 = ply:Give("weapon_ar2", true)
    if IsValid(ar2) then ar2:SetClip1(30) end
    ply:SetAmmo(30, "AR2")
    ply:SetAmmo(0, "AR2AltFire")

    if IsValid(smg) then ply:SelectWeapon("weapon_smg1") end
    ply:ChatPrint("Weapon specials testkit: SMG + AR2 granted. SMG selected.")
end)

concommand.Add("lod_weapon_specials_status", function(ply)
    if not developerAllowed(ply) then return end
    local state = stateFor(ply)
    local now = CurTime()
    local smg = state.smg
    local ar2 = state.ar2
    local active = activeWeapon(ply)
    local ar2Clip = IsValid(active) and active:GetClass() == "weapon_ar2"
        and active:Clip1() or -1
    local line = string.format(
        "SMG heat=%d/%d suppression=%.2f overheated=%s lock=%.2f | AR2 active=%s clip=%d shots=%d/%d bursts=%d ammoCommitted=%d projectiles=%d last=%d/%d",
        math.floor((smg.heat or 0) + 0.5),
        math.floor(tonumber(smg.threshold) or SMG_MAX_HEAT),
        tonumber(smg.suppressionChance) or 0,
        ((smg.overheatedUntil or 0) > now) and "yes" or "no",
        math.max(0, (smg.overheatedUntil or 0) - now),
        ar2.active and "yes" or "no",
        ar2Clip,
        ar2.shotsFired or 0,
        ar2.targetShots or 0,
        Specials.Stats.ar2Bursts or 0,
        Specials.Stats.ar2AmmoCommitted or 0,
        Specials.Stats.ar2Rounds or 0,
        Specials.Stats.lastAR2BurstRounds or 0,
        Specials.Stats.lastAR2BurstTarget or 0)
    print("[LOD:WEAPON-SPECIALS] " .. line)
    ply:ChatPrint(line)
end)
