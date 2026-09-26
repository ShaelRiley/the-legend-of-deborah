-- SPOT-09 is a finite utility item, not another weapon or Magic system.
LOD.DamselRevenge=LOD.DamselRevenge or {}
local D=LOD.DamselRevenge
D.Config={service=.2,arming=.6,lease=.6,drift=4,rangeCells=4,muzzle=52,
    portWidth=160,portHeight=64,inset=4,dropAttempts=3,collectRange=96}
D.Firearms={
    {class='weapon_pistol',gap=.6,sound='weapons/pistol/pistol_fire2.wav'},
    {class='weapon_smg1',gap=.3,sound='weapons/smg1/smg1_fire1.wav'},
    {class='weapon_ar2',gap=.4,sound='weapons/ar2/fire1.wav'}
}
function D:Firearm(class)
    for _,spec in ipairs(self.Firearms) do if spec.class==class then return spec end end
end
function D:PortSize()
    return math.min(self.Config.portWidth,LOD.Config.Progression.GateWidth-8),self.Config.portHeight
end
LOD.Equipment.Definitions.damsel_revenge={id='damsel_revenge',name="Damsel's Revenge",
    slots={'throwable'},throwable=true,drinkable=true,effect='damsel_revenge',maxStack=3,
    model='models/props_lab/clipboard.mdl',heldScale=.35,heldColor=Color(220,75,135),
    prompt='LMB / RMB: USE — ARM DAMSEL',description="Use in Gordon's court to arm the jailed Damsel with a random Pistol, SMG or Pulse Rifle. One use per encounter; invalid use spends nothing. She shoots the visible real Gordon, not Hector. Her gun's properties activate only after collection. On successful rescue, its frozen pickup belongs to the Hero who used this item; collect it during the victory window. No Magic or ammunition cost."}
