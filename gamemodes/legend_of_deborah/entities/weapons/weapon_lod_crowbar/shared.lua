SWEP.Base = "weapon_base"
SWEP.PrintName = "Crowbar"
SWEP.Author = "The Legend of Deborah"
SWEP.Category = "The Legend of Deborah"
SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.ViewModelFOV = 62
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Slot = 0
SWEP.SlotPos = 0
SWEP.Weight = 5
SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.45

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local CROWBAR_RANGE = 75
local HULL_MINS = Vector(-10, -10, -8)
local HULL_MAXS = Vector(10, 10, 8)
local DAMAGE_PROFILE = {label = "CROWBAR", source = "crowbar", count = 1, sides = 3}
local MISS_SOUND = "weapons/crowbar/crowbar_swing1.wav"
local HIT_SOUND = "physics/body/body_medium_impact_soft2.wav"

function SWEP:Initialize()
    self:SetHoldType("melee")
end

function SWEP:Deploy()
    self:SetHoldType("melee")
    self:SendWeaponAnim(ACT_VM_DRAW)
    return true
end

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_MISSCENTER)

    if CLIENT then return end

    owner:LagCompensation(true)
    local startPos = owner:GetShootPos()
    local direction = owner:GetAimVector()
    local trace = util.TraceHull({
        start = startPos,
        endpos = startPos + direction * CROWBAR_RANGE,
        mins = HULL_MINS,
        maxs = HULL_MAXS,
        filter = owner,
        mask = MASK_SHOT_HULL
    })
    owner:LagCompensation(false)

    local target = trace.Entity
    if not IsValid(target) or not target.LODHostile or target.LODDead then
        self:EmitSound(MISS_SOUND, 68, 100, 0.82, CHAN_WEAPON)
        return
    end

    local rolls = LOD and LOD.CombatRolls
    if not rolls or not rolls._RNG or not rolls._RollFormula then
        self:EmitSound(MISS_SOUND, 68, 100, 0.82, CHAN_WEAPON)
        return
    end

    local total, values = rolls:_RollFormula(DAMAGE_PROFILE, rolls:_RNG("player:weapon_lod_crowbar"))
    total = math.max(1, math.floor(tonumber(total) or 1))
    local healthBefore = target:Health()

    local damage = DamageInfo()
    damage:SetAttacker(owner)
    damage:SetInflictor(self)
    damage:SetDamage(total)
    damage:SetDamageType(DMG_CLUB)
    damage:SetDamagePosition(trace.HitPos)
    damage:SetDamageForce(direction * 2200)
    target:TakeDamageInfo(damage)

    rolls.Stats.playerAttacks = (rolls.Stats.playerAttacks or 0) + 1
    if rolls._Send and rolls._DamageEventText then
        local detail = values and values[1] and string.format("[roll %d]", values[1]) or nil
        rolls:_Send(owner, 0, rolls:_DamageEventText(owner, "1d3", total,
            target, detail, nil, "Hostile", "crowbar"))
    end

    if total < healthBefore and IsValid(target) and not target.LODDead
        and LOD.M3HitFeedback and LOD.M3HitFeedback.ApplyHitStun then
        LOD.M3HitFeedback:ApplyHitStun(target)
    end

    if util.NetworkStringToID("LOD_HitConfirm") ~= 0 then
        net.Start("LOD_HitConfirm")
        net.Send(owner)
    end

    self:EmitSound(HIT_SOUND, 66, 100, 0.72, CHAN_WEAPON)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.25)
end

function SWEP:Reload()
end
