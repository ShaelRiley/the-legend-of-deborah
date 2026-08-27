DeriveGamemode("base")

GM.Name = "The Legend of Deborah"
GM.Author = "Shael Riley"
GM.Email = ""
GM.Website = ""

-- Deborah is cooperative. We still use one real team for teammate collision and
-- friendly-fire semantics, but there is no player-facing team-selection game.
GM.TeamBased = false

LOD = LOD or {}
LOD.Version = "0.2.0-dev"

include("lod/sh_config.lua")
include("lod/sh_rng.lua")

if SERVER then
    AddCSLuaFile("lod/cl_container_wayfinding_projection.lua")
    AddCSLuaFile("lod/cl_container_section_recolor.lua")
    AddCSLuaFile("lod/cl_container_marking_panel.lua")
end

-- Base gamemode's TeamBased example creates Blue/Orange/Sexy teams. Override
-- CreateTeams explicitly so those sample teams never become part of Deborah.
function GM:CreateTeams()
    team.SetUp(LOD.Config.PlayerTeam, "Expedition", Color(220, 140, 48), false)
end

local function giveLoaded(ply, weaponClass, clip)
    local weapon = ply:Give(weaponClass, true)
    if IsValid(weapon) and clip and clip >= 0 then weapon:SetClip1(clip) end
    return weapon
end

-- First-time join-in-progress kits are a multiplayer recovery rule, not ordinary
-- randomized weapon acquisition. Keep every eligible family at exactly its
-- shipping one-reload/33% regeneration-floor quantity: loaded magazine only,
-- zero reserve. Ordinary individualized loot remains free to use the peer firearm
-- weighting defined elsewhere.
local CATCHUP_FIREARMS = {
    {class = "weapon_smg1", clip = 25, ammo = "SMG1", minLevel = 1},
    {class = "weapon_shotgun", clip = 7, ammo = "Buckshot", minLevel = 1},
    {class = "weapon_357", clip = 6, ammo = "357", minLevel = 2},
    {class = "weapon_ar2", clip = 20, ammo = "AR2", minLevel = 3}
}

local function giveCatchupFirearms(ply, catchupLevel)
    for _, spec in ipairs(CATCHUP_FIREARMS) do
        if catchupLevel >= spec.minLevel then
            giveLoaded(ply, spec.class, spec.clip)
            ply:SetAmmo(0, spec.ammo)
        end
    end

    -- Catch-up never creates consumable Grenades or AR2 secondary ammunition.
    ply:SetAmmo(0, "Grenade")
    ply:SetAmmo(0, "AR2AltFire")
end

-- Initial Level-1 participants receive the baseline Pistol + emergency Crowbar.
-- A first-time identity entering an already-running expedition receives the live
-- GDD catch-up kit: Level 1 adds SMG + Shotgun, Level 2 also adds Magnum, and
-- Level 3+ also adds AR2. Each firearm begins at exactly one reload-equivalent.
-- Once an inventory snapshot exists, RunManager owns every later respawn/level
-- restore and this first-entry loadout is never regenerated.
function GM:PlayerLoadout(ply)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    if not ps or ps.inventory or ps.initialLoadoutGranted then return end

    ply:StripWeapons()
    ply:RemoveAllAmmo()

    local pistol = giveLoaded(ply, "weapon_pistol", 18)
    ply:Give("weapon_lod_crowbar", true)
    ply:SetAmmo(0, "Pistol")

    local catchupLevel = math.max(0, math.floor(tonumber(ps.catchupLevel) or 0))
    if catchupLevel >= 1 then
        giveCatchupFirearms(ply, catchupLevel)
        ps.catchupGrantedLevel = catchupLevel
    else
        -- Normal initial participants also never receive free explosives.
        ply:SetAmmo(0, "Grenade")
        ply:SetAmmo(0, "AR2AltFire")
    end

    ps.initialLoadoutGranted = true
    if IsValid(pistol) then ply:SelectWeapon("weapon_pistol") end
end

function GM:PlayerNoClip()
    return false
end

function GM:PlayerSpawnProp()
    return false
end

function GM:PlayerSpawnNPC()
    return false
end

function GM:PlayerSpawnSENT()
    return false
end

function GM:PlayerSpawnSWEP()
    return false
end

function GM:PlayerGiveSWEP()
    return false
end

function GM:CanTool()
    return false
end

function GM:PlayerShouldTakeDamage(victim, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        return false
    end
    return true
end

function GM:ShouldCollide(ent1, ent2)
    if IsValid(ent1) and IsValid(ent2) and ent1:IsPlayer() and ent2:IsPlayer() then
        return false
    end
end

-- The base gamemode normally permits manual respawn input after death. Deborah's
-- life system owns respawn timing authoritatively: a consumed life means exactly
-- 20 seconds of restricted allied spectating before the server respawns the
-- participant at the latest checkpoint. Returning true prevents base respawn input.
function GM:PlayerDeathThink()
    return true
end
