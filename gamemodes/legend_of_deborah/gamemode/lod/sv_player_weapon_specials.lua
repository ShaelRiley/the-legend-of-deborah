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
local AR2_BURST_SHOTS = 3
local AR2_BURST_SPACING = 0.09
local AR2_RECOVERY = 0.25

local SMG_WARM_SOUND = "buttons/button17.wav"
local SMG_NEAR_SOUND = "buttons/button15.wav"
local SMG_OVERHEAT_SOUND = "ambient/machines/steam_release_2.wav"
local SMG_COOL_SOUND = "ambient/machines/steam_release_1.wav"
local SMG_READY_SOUND = "buttons/button14.wav"
local AR2_TELEGRAPH_SOUND = "buttons/button17.wav"

Specials.PlayerState = Specials.PlayerState or setmetatable({}, {__mode = "k"})
Specials.Stats = Specials.Stats or {
    smgShots = 0,
    smgOverheats = 0,
    ar2Bursts = 0,
    ar2Rounds = 0
}

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

local function syncSMG(weapon, smg)
    if not IsValid(weapon) then return end
    weapon:SetNW2Float("LOD_SMGHeat", math.Clamp(smg.heat or 0, 0, SMG_MAX_HEAT))
    weapon:SetNW2Bool("LOD_SMGOverheated", (smg.overheatedUntil or 0) > CurTime())
end

function Specials:ResetPlayer(ply)
    local state = self.PlayerState[ply]
    if state and state.smg and IsValid(state.smg.weapon) then
        state.smg.weapon:SetNW2Float("LOD_SMGHeat", 0)
        state.smg.weapon:SetNW2Bool("LOD_SMGOverheated", false)
    end
    clearAR2Network(ply)
    self.PlayerState[ply] = nil
end

function Specials:OnSMGShot(ply, weapon)
    local state = stateFor(ply)
    local smg = state.smg
    local now = CurTime()

    if (smg.overheatedUntil or 0) > now then return end

    local previous = smg.heat or 0
    smg.weapon = weapon
    smg.heat = math.min(SMG_MAX_HEAT, previous + 1)
    smg.nextCoolAt = now + SMG_COOL_INTERVAL
    smg.lastShotAt = now
    self.Stats.smgShots = (self.Stats.smgShots or 0) + 1

    if previous < SMG_WARM_STAGE and smg.heat >= SMG_WARM_STAGE then
        weapon:EmitSound(SMG_WARM_SOUND, 56, 118, 0.46, CHAN_ITEM)
    end
    if previous < SMG_NEAR_STAGE and smg.heat >= SMG_NEAR_STAGE then
        weapon:EmitSound(SMG_NEAR_SOUND, 62, 132, 0.62, CHAN_ITEM)
    end

    if smg.heat >= SMG_MAX_HEAT then
        smg.overheatedUntil = now + SMG_OVERHEAT_LOCK
        smg.coolCueAt = now + 0.85
        smg.coolCuePlayed = false
        weapon:SetNextPrimaryFire(smg.overheatedUntil)
        weapon:SetNextSecondaryFire(smg.overheatedUntil)
        weapon:EmitSound(SMG_OVERHEAT_SOUND, 70, 112, 0.78, CHAN_WEAPON)
        self.Stats.smgOverheats = (self.Stats.smgOverheats or 0) + 1
    end

    syncSMG(weapon, smg)
end

local function finishAR2(ply, ar2, cooldown)
    ar2.active = false
    ar2.shotsFired = 0
    ar2.fireAt = nil
    ar2.nextShotAt = nil
    ar2.direction = nil
    ar2.readyAt = CurTime() + (cooldown or AR2_RECOVERY)
    if IsValid(ar2.weapon) then
        ar2.weapon:SetNextPrimaryFire(ar2.readyAt)
    end
    clearAR2Network(ply)
end

function Specials:BeginAR2Burst(ply, weapon, direction)
    local state = stateFor(ply)
    local ar2 = state.ar2
    local now = CurTime()

    if ar2.active or now < (ar2.readyAt or 0) then return false end
    if now < weapon:GetNextPrimaryFire() then return false end
    if weapon:Clip1() < AR2_BURST_SHOTS then
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
    if weapon:Clip1() <= 0 then return false end

    weapon:SetClip1(math.max(0, weapon:Clip1() - 1))
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
        local weapon = ar2.weapon
        if not ply:Alive() or not IsValid(weapon) or activeWeapon(ply) ~= weapon then
            finishAR2(ply, ar2, 0.15)
            return
        end

        if now >= (ar2.fireAt or math.huge) then
            ply:SetNW2Bool("LOD_PlayerAR2Telegraph", false)
            while ar2.shotsFired < AR2_BURST_SHOTS and now >= (ar2.nextShotAt or math.huge) do
                if not self:FireAR2Round(ply, ar2) then
                    finishAR2(ply, ar2, 0.15)
                    return
                end
                ar2.shotsFired = ar2.shotsFired + 1
                ar2.nextShotAt = ar2.nextShotAt + AR2_BURST_SPACING
            end

            if ar2.shotsFired >= AR2_BURST_SHOTS then
                finishAR2(ply, ar2, AR2_RECOVERY)
            end
        end
    end
end

hook.Add("EntityFireBullets", "LOD_PlayerWeaponSpecials_SMGHeat", function(shooter)
    if not IsValid(shooter) or not shooter:IsPlayer() then return end
    local weapon = activeWeapon(shooter)
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_smg1" then return end
    Specials:OnSMGShot(shooter, weapon)
end)

hook.Add("StartCommand", "LOD_PlayerWeaponSpecials_Input", function(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end
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
        if ar2.active then cmd:RemoveKey(IN_RELOAD) end

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

hook.Add("PlayerDeath", "LOD_PlayerWeaponSpecials_ResetDeath", function(ply)
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
    local line = string.format(
        "SMG heat=%d/6 overheated=%s lock=%.2f | AR2 active=%s shots=%d bursts=%d rounds=%d",
        math.floor((smg.heat or 0) + 0.5),
        ((smg.overheatedUntil or 0) > now) and "yes" or "no",
        math.max(0, (smg.overheatedUntil or 0) - now),
        ar2.active and "yes" or "no",
        ar2.shotsFired or 0,
        Specials.Stats.ar2Bursts or 0,
        Specials.Stats.ar2Rounds or 0)
    print("[LOD:WEAPON-SPECIALS] " .. line)
    ply:ChatPrint(line)
end)
