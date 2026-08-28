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
    include("lod/sv_workshop_distribution.lua")
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

-- Every newly admitted cooperative identity has one universal baseline loadout.
-- The advanced starter is deliberately NOT granted here: StagingDeployment owns
-- that identity-instanced physical pickup and its reconnect-safe claim state.
-- Once an inventory snapshot exists, RunManager owns every later respawn/level
-- restore and this first-entry baseline is never regenerated.
function GM:PlayerLoadout(ply)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    if not ps or ps.inventory or ps.initialLoadoutGranted then return end

    ply:StripWeapons()
    ply:RemoveAllAmmo()

    local pistol = giveLoaded(ply, "weapon_pistol", 18)
    ply:Give("weapon_lod_crowbar", true)
    ply:SetAmmo(0, "Pistol")
    ply:SetAmmo(0, "Grenade")
    ply:SetAmmo(0, "AR2AltFire")

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
