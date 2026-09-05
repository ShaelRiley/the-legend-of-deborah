LOD = LOD or {}

local Specials = LOD.PlayerWeaponSpecials
if not Specials then return end

-- This file is loaded immediately after sv_player_weapon_specials.lua, so it is
-- the canonical point where the RPG cadence bridge can compose with the AR2's
-- custom input/burst authority without relying on StartCommand hook ordering.
include("sv_rpg_gate_e_rate_of_fire_ar2.lua")

util.AddNetworkString("LOD_PlayerAR2Activate")

net.Receive("LOD_PlayerAR2Activate", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_ar2" then return end

    -- Client prediction suppresses the stock automatic-fire input and only asks
    -- to begin the authored burst. The server revalidates weapon, ammo, cadence,
    -- and commits its own current aim direction before publishing the laser.
    local startedAt = CurTime()
    if not Specials:BeginAR2Burst(ply, weapon, ply:EyeAngles():Forward()) then return end

    -- Begin the feat transaction from the same authoritative activation event.
    -- Completion is observed independently after the three-round burst ends, so
    -- later PlayerWeaponSpecials method replacement cannot silently bypass it.
    local RPG = LOD.RPG
    local Effects = RPG and RPG.FeatEffectSystem
    if Effects and isfunction(Effects.BeginAR2RateOfFirePlan) then
        Effects:BeginAR2RateOfFirePlan(ply, weapon, startedAt)
    end
end)
