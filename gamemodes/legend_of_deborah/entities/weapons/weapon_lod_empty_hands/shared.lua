if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_base"
SWEP.PrintName = "Empty hands"
SWEP.Spawnable = false
SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = true
SWEP.Weight = 0
SWEP.Slot = 0
SWEP.SlotPos = 9
SWEP.Primary = {ClipSize=-1, DefaultClip=-1, Automatic=false, Ammo="none"}
SWEP.Secondary = {ClipSize=-1, DefaultClip=-1, Automatic=false, Ammo="none"}
function SWEP:Initialize() self:SetHoldType("normal") end
function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end
function SWEP:PreDrawViewModel() return true end
