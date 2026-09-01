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
SWEP.DrawWeaponInfoBox = false
SWEP.BounceWeaponIcon = false
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

-- Ordinary melee enemies begin around 70-74 units of reach, while the largest
-- size-variance Shambler can approach ~91. Give the player only a narrow spacing
-- advantage: enough for skilled backpedal timing, not enough to make melee safe.
local CROWBAR_RANGE = 96
local HULL_MINS = Vector(-10, -10, -8)
local HULL_MAXS = Vector(10, 10, 8)
local DAMAGE_PROFILE = {label = "CROWBAR", source = "crowbar", count = 1, sides = 3}
local MISS_SOUND = "Weapon_Crowbar.Single"
local HIT_SOUND = "physics/body/body_medium_impact_soft2.wav"
local HIT_CONFIRM_DELAY = 0.06

if CLIENT then
    -- The custom LOD Crowbar derives from weapon_base, whose default selection
    -- art is the generic SWEP icon. Draw HL2's canonical Crowbar glyph instead:
    -- weapon_crowbar uses WeaponIcons character "c" in the Source weapon script.
    killicon.AddAlias("weapon_lod_crowbar", "weapon_crowbar")

    function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
        surface.SetFont("WeaponIcons")
        local glyph = "c"
        local glyphWidth, glyphHeight = surface.GetTextSize(glyph)
        surface.SetTextColor(255, 255, 255, alpha)
        surface.SetTextPos(
            x + math.floor((wide - glyphWidth) * 0.5),
            y + math.floor((tall - glyphHeight) * 0.5)
        )
        surface.DrawText(glyph)
    end
end

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
    local rules = LOD and LOD.RPGAbilityRules
    local aceBonus = rules and rules.CommitAttack and rules:CommitAttack(owner) and 1 or 0

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
        owner:EmitSound(MISS_SOUND, 68, 100, 0.60, CHAN_WEAPON)
        return
    end

    local rolls = LOD and LOD.CombatRolls
    if not rolls or not rolls._RNG or not rolls._RollFormula then
        owner:EmitSound(MISS_SOUND, 68, 100, 0.60, CHAN_WEAPON)
        return
    end

    local contract = rolls.RollActorDamage
        and rolls:RollActorDamage(owner, DAMAGE_PROFILE,
            rolls:_RNG("player:weapon_lod_crowbar"), aceBonus) or nil
    local total = contract and rolls:ResolveActorDamage(contract, owner, target, {physical = true})
        or rolls:_RollFormula(DAMAGE_PROFILE, rolls:_RNG("player:weapon_lod_crowbar:fallback"))
    local values = contract and contract.values or nil
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
        local detail = values and #values > 0
            and string.format("[rolls %s]", table.concat(values, ">")) or nil
        rolls:_Send(owner, 0, rolls:_DamageEventText(owner,
            contract and contract.formula or "1d3", total,
            target, detail, nil, "Hostile", "crowbar"))
    end

    if total < healthBefore and IsValid(target) and not target.LODDead
        and LOD.M3HitFeedback and LOD.M3HitFeedback.ApplyHitStun then
        LOD.M3HitFeedback:ApplyHitStun(target, 1, owner)
    end

    self:EmitSound(HIT_SOUND, 66, 100, 0.72, CHAN_WEAPON)

    -- The ranged confirmation sound is deliberately non-diegetic. Delay the
    -- same LOD_HitConfirm event by one short beat so the softer impact sample
    -- cannot perceptually mask the blip when both are generated by one swing.
    timer.Simple(HIT_CONFIRM_DELAY, function()
        if not IsValid(owner) or not owner:IsPlayer() then return end
        net.Start("LOD_HitConfirm")
        net.Send(owner)
    end)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.25)
end

function SWEP:Reload()
end
