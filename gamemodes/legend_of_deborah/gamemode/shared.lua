DeriveGamemode("base")

GM.Name = "The Legend of Deborah"
GM.Author = "Shael Riley"
GM.Email = ""
GM.Website = ""
GM.TeamBased = true

LOD = LOD or {}
LOD.Version = "0.1.0-dev"

include("lod/sh_config.lua")
include("lod/sh_rng.lua")

function GM:Initialize()
    team.SetUp(LOD.Config.PlayerTeam, "Expedition", Color(220, 140, 48), true)
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
