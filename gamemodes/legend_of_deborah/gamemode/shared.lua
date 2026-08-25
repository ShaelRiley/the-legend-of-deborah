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

-- Base gamemode's TeamBased example creates Blue/Orange/Sexy teams. Override
-- CreateTeams explicitly so those sample teams never become part of Deborah.
function GM:CreateTeams()
    team.SetUp(LOD.Config.PlayerTeam, "Expedition", Color(220, 140, 48), false)
end

-- A brand-new expedition identity begins with the GDD baseline: both the Pistol
-- and the emergency Crowbar. The Pistol begins with exactly one loaded magazine
-- and no reserve ammunition. RunManager owns every later inventory restore, so
-- respawns and level transitions never use this path as an ammunition refill.
function GM:PlayerLoadout(ply)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    if not ps or ps.inventory then return end

    ply:StripWeapons()
    ply:RemoveAllAmmo()

    local pistol = ply:Give("weapon_pistol", true)
    ply:Give("weapon_lod_crowbar", true)

    if IsValid(pistol) then
        pistol:SetClip1(18)
        ply:SelectWeapon("weapon_pistol")
    end
    ply:SetAmmo(0, "Pistol")
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
