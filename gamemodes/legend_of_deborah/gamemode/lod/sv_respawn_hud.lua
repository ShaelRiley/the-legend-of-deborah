LOD = LOD or {}

local RunManager = LOD.RunManager
local nextSync = 0
local SYNC_INTERVAL = 0.20
local cvDeveloperMode = CreateConVar(
    "lod_developer_mode",
    "0",
    FCVAR_ARCHIVE,
    "Enable Legend of Deborah developer/testing affordances. Requires a restart when changing module availability."
)
local fastUsed = {}

-- Testing QoL: while dead with a normal respawn pending, compress the remaining
-- countdown to one tenth once per death. This is deliberately server-authoritative
-- and developer-mode-gated so it cannot become an accidental release mechanic.
concommand.Add("lod_dev_respawn_fast", function(ply)
    if not cvDeveloperMode:GetBool() or not IsValid(ply) then return end
    if not RunManager:IsPlayedIdentity(ply) or not RunManager:IsActivePlayer(ply) then return end
    if ply:Alive() then return end

    local id = RunManager:IdentityOf(ply)
    local ps = id and RunManager:GetPlayerState(id)
    if not id or not ps or ps.eliminated or ps.lives <= 0 or not ps.respawnAt then return end
    if fastUsed[id] then return end

    local remaining = math.max(0, ps.respawnAt - CurTime())
    if remaining <= 0 then return end

    fastUsed[id] = true
    ps.respawnAt = CurTime() + (remaining / 10)
    RunManager:MarkUnranked("developer respawn acceleration")
    ply:ChatPrint("Developer test: respawn countdown accelerated 10x.")
end)

-- Publish the authoritative server-side respawn countdown for the local HUD.
-- This intentionally derives from RunManager player state instead of starting a
-- client stopwatch, so reconnects, pauses/freeze adjustments, and delayed state
-- changes cannot leave the visible timer lying to the player.
hook.Add("Think", "LOD_RespawnHUDSync", function()
    if CurTime() < nextSync then return end
    nextSync = CurTime() + SYNC_INTERVAL

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local id = RunManager:IdentityOf(ply)
            local ps = id and RunManager:GetPlayerState(id)
            local remaining = 0
            local respawning = ps and not ps.eliminated and ps.lives > 0 and ps.respawnAt ~= nil
            if respawning then
                remaining = math.max(0, ps.respawnAt - CurTime())
            else
                if id then fastUsed[id] = nil end
            end

            ply:SetNW2Float("LOD_RespawnRemaining", remaining)
            ply:SetNW2Bool("LOD_RespawnFastUsed", id and fastUsed[id] == true or false)
            ply:SetNW2Bool("LOD_DeveloperMode", cvDeveloperMode:GetBool())
        end
    end
end)


concommand.Add("lod_developer_tools_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local enabled = cvDeveloperMode:GetBool()
    local loaded = LOD.DeveloperToolsLoaded == true
    local moduleCount = LOD.DeveloperToolModuleCount or 0
    local thinkHooks = hook.GetTable().Think or {}
    local legacyTestkitThink = thinkHooks["LOD_M3_TestkitInfinitePistolAmmo"] ~= nil
    local passed = enabled == loaded and not legacyTestkitThink
        and ((loaded and moduleCount == 8) or (not loaded and moduleCount == 0))
    local line = string.format(
        "default=0 enabled=%s toolsLoaded=%s modules=%d legacyTestkitThink=%s result=%s",
        tostring(enabled), tostring(loaded), moduleCount, tostring(legacyTestkitThink),
        passed and "PASS" or "FAIL"
    )
    print("[LOD:DEVELOPER-TOOLS] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
