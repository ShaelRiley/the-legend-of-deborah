LOD = LOD or {}

local Specials = LOD.PlayerWeaponSpecials
if not Specials then return end

-- PlayerWeaponSpecials now exists, making this the canonical integration point
-- for Gate-E feat families that alter the authored AR2 burst transaction. Load the
-- burst-size definitions first, then the Rate-of-Fire composition bridge, then the
-- finite Burst-Size validator/testkit against the final shared authority.
include("sv_rpg_gate_e_burst_size.lua")
include("sv_rpg_gate_e_rate_of_fire_ar2.lua")
include("sv_rpg_gate_e_burst_size_validation.lua")

util.AddNetworkString("LOD_PlayerAR2Activate")

net.Receive("LOD_PlayerAR2Activate", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_ar2" then return end

    -- Client prediction suppresses the stock automatic-fire input and only asks
    -- to begin the authored burst. The server revalidates weapon, ammo, cadence,
    -- burst size, and current aim direction before publishing the laser.
    local startedAt = CurTime()
    if not Specials:BeginAR2Burst(ply, weapon, ply:EyeAngles():Forward()) then return end

    -- Begin the cadence transaction from the same authoritative activation event.
    -- The BeginAR2Burst wrapper normally already created it; the plan function is
    -- idempotent per player, so this remains a safe network-path backstop.
    local RPG = LOD.RPG
    local Effects = RPG and RPG.FeatEffectSystem
    if Effects and isfunction(Effects.BeginAR2RateOfFirePlan) then
        Effects:BeginAR2RateOfFirePlan(ply, weapon, startedAt)
    end
end)
