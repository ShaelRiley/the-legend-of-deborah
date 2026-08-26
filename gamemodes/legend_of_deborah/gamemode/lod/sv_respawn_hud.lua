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

-- Publish the authoritative server-side mandatory death wait for the local HUD.
-- Death Tetris may shorten ps.respawnAt by two seconds per cleared line, so this
-- remains derived from RunManager state rather than a client stopwatch.
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
            end

            ply:SetNW2Float("LOD_RespawnRemaining", remaining)
            -- Compatibility value for older HUD/debug code. Production F is now
            -- owned exclusively by the death/Tetris interaction.
            ply:SetNW2Bool("LOD_RespawnFastUsed", false)
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
    local legacyFastRespawn = thinkHooks["LOD_DeveloperRespawnFastInput"] ~= nil
    local passed = enabled == loaded and not legacyTestkitThink and not legacyFastRespawn
        and ((loaded and moduleCount == 8) or (not loaded and moduleCount == 0))
    local line = string.format(
        "default=0 enabled=%s toolsLoaded=%s modules=%d legacyTestkitThink=%s legacyFastRespawn=%s result=%s",
        tostring(enabled), tostring(loaded), moduleCount, tostring(legacyTestkitThink),
        tostring(legacyFastRespawn), passed and "PASS" or "FAIL"
    )
    print("[LOD:DEVELOPER-TOOLS] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
