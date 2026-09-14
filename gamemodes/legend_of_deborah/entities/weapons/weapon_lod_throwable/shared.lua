if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_base"
SWEP.PrintName = "Throwable"
SWEP.Spawnable = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/props_junk/garbage_glassbottle003a.mdl"
SWEP.Slot = 4
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = true
SWEP.Weight = 1
SWEP.Primary = {ClipSize=-1, DefaultClip=-1, Automatic=false, Ammo="none"}
SWEP.Secondary = {ClipSize=-1, DefaultClip=-1, Automatic=false, Ammo="none"}
function SWEP:Initialize() self:SetHoldType("slam") end
function SWEP:PrimaryAttack()
    if SERVER and LOD.Equipment then LOD.Equipment:Use(self:GetOwner(), "throw") end
    self:SetNextPrimaryFire(CurTime() + LOD.Equipment.UseCooldown)
end
function SWEP:SecondaryAttack()
    if SERVER and LOD.Equipment then LOD.Equipment:Use(self:GetOwner(), "drink") end
    self:SetNextSecondaryFire(CurTime() + LOD.Equipment.UseCooldown)
end
-- The contextual bottle presentation is drawn by cl_equipment; never show a frag.
function SWEP:PreDrawViewModel() return true end
function SWEP:Reload() end
