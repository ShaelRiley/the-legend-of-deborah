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

local CATCHUP_FIREARMS = {
    {class = "weapon_shotgun", clip = 6, ammo = "Buckshot"},
    {class = "weapon_smg1", clip = 45, ammo = "SMG1"},
    {class = "weapon_357", clip = 6, ammo = "357"},
    {class = "weapon_ar2", clip = 30, ammo = "AR2"}
}

local function giveEqualCatchupFirearms(ply, run)
    local levelSeed = run and run.State and run.State.LevelSeed or 1
    local identity = run and run.IdentityOf and run:IdentityOf(ply) or ply:SteamID64()
    local rng = LOD.RNG.New(LOD.Seeds.Derive(levelSeed,
        "catchup-firearms:" .. tostring(identity or ply:EntIndex())))
    local pool = table.Copy(CATCHUP_FIREARMS)

    for _ = 1, math.min(2, #pool) do
        local index = rng:Int(1, #pool)
        local spec = table.remove(pool, index)
        giveLoaded(ply, spec.class, spec.clip)
        ply:SetAmmo(0, spec.ammo)
    end

    ply:SetAmmo(0, "AR2AltFire")
end

-- Initial Level-1 participants receive the baseline Pistol + emergency Crowbar.
-- A first-time identity entering an already-running expedition receives two
-- distinct firearms selected uniformly from Shotgun/SMG/Magnum/AR2. Catch-up no
-- longer encodes a weapon power tier; ordinary LootDirector acquisition does not
-- privilege any of those four guns either. Once an inventory snapshot exists,
-- RunManager owns every later respawn/level restore.
function GM:PlayerLoadout(ply)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    if not ps or ps.inventory then return end

    ply:StripWeapons()
    ply:RemoveAllAmmo()

    local pistol = giveLoaded(ply, "weapon_pistol", 18)
    ply:Give("weapon_lod_crowbar", true)
    ply:SetAmmo(0, "Pistol")

    local catchupLevel = math.max(0, math.floor(tonumber(ps.catchupLevel) or 0))
    if catchupLevel >= 1 then
        giveEqualCatchupFirearms(ply, run)
    end

    -- Catch-up kits never include free grenades or AR2 secondary ammunition.
    ply:SetAmmo(0, "Grenade")
    ply:SetAmmo(0, "AR2AltFire")

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
