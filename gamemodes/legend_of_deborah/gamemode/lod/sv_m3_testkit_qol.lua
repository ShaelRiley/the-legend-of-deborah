LOD = LOD or {}

local TESTKIT_RESERVE = 999
local REFILL_THRESHOLD = 250
local REFILL_TIMER = "LOD_M3_TestkitAmmoRefill"
local armedPlayers = setmetatable({}, {__mode = "k"})

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return IsValid(ply) and ply:IsAdmin()
end

local function tell(ply, text)
    print("[LOD:M3] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end

local function refillArmedPlayers()
    local active = 0
    for ply in pairs(armedPlayers) do
        if not IsValid(ply) or not ply.LODM3InfiniteTestPistol or not developerAllowed(ply) or not ply:Alive() then
            armedPlayers[ply] = nil
        else
            active = active + 1
            if IsValid(ply:GetWeapon("weapon_pistol")) and ply:GetAmmoCount("Pistol") < REFILL_THRESHOLD then
                ply:SetAmmo(TESTKIT_RESERVE, "Pistol")
            end
        end
    end
    if active == 0 then timer.Remove(REFILL_TIMER) end
end

local function armAmmoRefill(ply)
    armedPlayers[ply] = true
    if not timer.Exists(REFILL_TIMER) then
        timer.Create(REFILL_TIMER, 0.10, 0, refillArmedPlayers)
    end
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
    armAmmoRefill(ply)

    if IsValid(pistol) then ply:SelectWeapon("weapon_pistol") end
    if LOD.RunManager and LOD.RunManager.MarkUnranked then
        LOD.RunManager:MarkUnranked("Milestone 3 developer combat kit")
    end
    tell(ply, "developer combat kit granted: crowbar + pistol + infinite pistol ammo")
end)

-- The shared refill timer exists only while at least one living developer has
-- explicitly armed the testkit; production and ordinary development play pay no
-- permanent Think-hook cost.
-- Testkit status is per life. Press H after a respawn to deliberately re-enable
-- the developer kit rather than leaking infinite ammo into unrelated testing.
hook.Add("PlayerSpawn", "LOD_M3_ResetInfiniteTestPistol", function(ply)
    ply.LODM3InfiniteTestPistol = false
    armedPlayers[ply] = nil
end)
