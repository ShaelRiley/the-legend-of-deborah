if SERVER then AddCSLuaFile() end
SWEP.Base="weapon_base"
SWEP.PrintName="Wand"
SWEP.Author="The Legend of Deborah"
SWEP.Category="The Legend of Deborah"
SWEP.Spawnable=false
SWEP.ViewModel="models/weapons/v_stunstick.mdl"
SWEP.WorldModel="models/weapons/w_stunbaton.mdl"
SWEP.UseHands=false
SWEP.DrawAmmo=false
SWEP.DrawCrosshair=true
SWEP.Slot=0
SWEP.SlotPos=1
SWEP.Weight=3
SWEP.AutoSwitchTo=false
SWEP.AutoSwitchFrom=true
SWEP.Primary={ClipSize=-1,DefaultClip=-1,Automatic=false,Ammo="none"}
SWEP.Secondary={ClipSize=-1,DefaultClip=-1,Automatic=false,Ammo="none"}
function SWEP:Initialize() self:SetHoldType("melee") end
function SWEP:PrimaryAttack()
    if SERVER then LOD.Equipment:FireWand(self:GetOwner(),self) end
    self:SetNextPrimaryFire(CurTime()+LOD.Equipment.Definitions.weapon_lod_wand.cooldown)
end
function SWEP:SecondaryAttack() end -- ordinary Spellbook binding still owns RMB
function SWEP:Reload() end
if CLIENT then
    function SWEP:DrawHUD()
        local ply=LocalPlayer()
        if not IsValid(ply) or not ply:Alive() or ply:GetActiveWeapon()~=self then return end
        local charges=self:GetNW2Int("LOD_WandCharges",0)
        local color=charges>0 and LOD.UI.HUDColor or Color(255,110,90)
        draw.SimpleText(string.format("WAND  %d / %d",charges,LOD.Equipment.Definitions.weapon_lod_wand.maxCharges),
            "Trebuchet24",ScrW()-24,ScrH()-92,color,TEXT_ALIGN_RIGHT)
        draw.SimpleText(charges>0 and "LMB: BEAM  ·  NO RELOAD" or "DEPLETED  ·  NO RELOAD",
            "DermaDefaultBold",ScrW()-24,ScrH()-62,color,TEXT_ALIGN_RIGHT)
    end
end
