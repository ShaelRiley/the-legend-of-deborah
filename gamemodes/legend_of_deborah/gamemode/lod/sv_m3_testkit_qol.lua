LOD = LOD or {}

local TESTKIT_RESERVE = 999
local REFILL_THRESHOLD = 250
local nextRefill = 0

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return IsValid(ply) and ply:IsAdmin()
end

local function tell(ply, text)
    print("[LOD:M3] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end

-- Replace the original temporary M3 command after sv_m3_debug.lua loads. This
-- keeps one authoritative testkit path for both the console command and H hotkey.
concommand.Remove("lod_m3_testkit")
concommand.Add("lod_m3_testkit", function(ply)
    if not developerAllowed(ply) or not ply:Alive() then return end

    local pistol = ply:Give("weapon_pistol", true)
    ply:Give("weapon_crowbar", true)
    ply:SetAmmo(TESTKIT_RESERVE, "Pistol")
    ply.LODM3InfiniteTestPistol = true

    if IsValid(pistol) then ply:SelectWeapon("weapon_pistol") end
    if LOD.RunManager and LOD.RunManager.MarkUnranked then
        LOD.RunManager:MarkUnranked("Milestone 3 developer combat kit")
    end
    tell(ply, "developer combat kit granted: crowbar + pistol + infinite pistol ammo")
end)

-- Refill reserve invisibly in the background. Reload behavior remains normal;
-- only ammunition scarcity is removed from Milestone-3 combat iteration.
hook.Add("Think", "LOD_M3_TestkitInfinitePistolAmmo", function()
    local now = CurTime()
    if now < nextRefill then return end
    nextRefill = now + 0.10

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.LODM3InfiniteTestPistol and developerAllowed(ply) and ply:Alive() then
            if IsValid(ply:GetWeapon("weapon_pistol")) and ply:GetAmmoCount("Pistol") < REFILL_THRESHOLD then
                ply:SetAmmo(TESTKIT_RESERVE, "Pistol")
            end
        end
    end
end)

-- Testkit status is per life. Press H after a respawn to deliberately re-enable
-- the developer kit rather than leaking infinite ammo into unrelated testing.
hook.Add("PlayerSpawn", "LOD_M3_ResetInfiniteTestPistol", function(ply)
    ply.LODM3InfiniteTestPistol = false
end)
