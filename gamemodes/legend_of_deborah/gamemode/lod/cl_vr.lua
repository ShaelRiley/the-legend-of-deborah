local VR = LOD.VR
local savedSettings = {}
local stickDirection
local menuRegistered = false

function VR:InputCovered()
    return gui.IsGameUIVisible() or gui.IsConsoleVisible()
        or vgui.CursorVisible() or IsValid(vgui.GetKeyboardFocus())
        or (chat and chat.IsTyping and chat.IsTyping())
        or LOD.UI.ActivePage ~= nil or (g_VR and g_VR.menuFocus ~= nil and g_VR.menuFocus ~= false)
end

function VR:TetrisClient()
    local death = LOD.TetrisClient
    local ply = LocalPlayer()
    if death and death.active and IsValid(ply) and not ply:Alive() then return death end
    local victory = LOD.IntermissionTetrisClient
    if victory and victory.active then return victory end
end

function VR:ContextAction()
    local timeout = LOD.CampaignTimeout
    if timeout and timeout:IsCinematic() then return timeout:RequestRestart() end
    if LOD.ClientState and LOD.ClientState.failed then return LOD.RequestCampaignRestart() end
    local death = LOD.TetrisClient
    if death and death:ContextAction() then return true end
    local victory = LOD.IntermissionTetrisClient
    if victory then return victory:ContextAction() end
    return false
end

function VR:OpenPlayerMenu()
    if LOD.CampaignTimeout and LOD.CampaignTimeout:IsCinematic() then return end
    if LOD.UI:IsMinigameLocked() then return end
    LOD.CharacterSheet:Toggle()
end

local function registerMenu()
    if menuRegistered or not vrmod or not vrmod.AddInGameMenuItem then return end
    vrmod.AddInGameMenuItem("Deborah Player Menu", 2, 1, function() VR:OpenPlayerMenu() end)
    vrmod.AddInGameMenuItem("Deborah: Pay respects / Tetris", 2, 2, function() VR:ContextAction() end)
    vrmod.AddInGameMenuItem("Deborah Team Menu", 2, 3, function() LOD.SoldierQueueUI:Open() end)
    vrmod.AddInGameMenuItem("Deborah Map", 2, 4, function() RunConsoleCommand("lod_minimap_toggle") end)
    vrmod.AddInGameMenuItem("Deborah Haste", 2, 5, function() RunConsoleCommand("lod_haste_toggle") end)
    vrmod.AddInGameMenuItem("Deborah GPS", 2, 0, function() RunConsoleCommand("lod_gps_toggle") end)
    menuRegistered = true
end

local function start(ply)
    if ply ~= LocalPlayer() then return end
    stickDirection = "blocked"
    registerMenu()
    -- gVRMod's separate vitals plate omits gamemode HUDPaint/PostDrawHUD unless
    -- engine HUD is enabled. These temporary settings also support classic VRMod.
    for _, name in ipairs({"vrmod_hud", "vrmod_hud_engine"}) do
        local setting = GetConVar(name)
        if setting and savedSettings[name] == nil then
            savedSettings[name] = setting:GetString()
            setting:SetString("1")
        end
    end
end

local function stop(ply)
    if ply ~= LocalPlayer() then return end
    stickDirection = nil
    for name, value in pairs(savedSettings) do
        local setting = GetConVar(name)
        if setting and setting:GetString() == "1" then setting:SetString(value) end
    end
    savedSettings = {}
end
hook.Add("VRMod_Start", "LOD_VRStart", start)
hook.Add("VRMod_Exit", "LOD_VRExit", stop)
hook.Add("InitPostEntity", "LOD_VRMenu", function()
    registerMenu()
    if VR:IsActive(LocalPlayer()) then start(LocalPlayer()) end
end)

-- Intercept only actions with a Deborah replacement. Returning nil for all
-- others leaves VRMod's fire, reload, use, locomotion and quick menu intact.
hook.Add("VRMod_AllowDefaultAction", "LOD_VRDefaultActions", function(action)
    if not VR:IsActive(LocalPlayer()) then return end
    if action == "boolean_menucontext" then return false end
    if VR:TetrisClient() and action == "boolean_jump" then return false end
    if action == "boolean_use" then
        local ply = LocalPlayer()
        if not ply:Alive() or (LOD.IntermissionTetrisClient and LOD.IntermissionTetrisClient.available)
            or (LOD.ClientState and LOD.ClientState.failed)
            or (LOD.CampaignTimeout and LOD.CampaignTimeout:IsCinematic()) then return false end
    end
    if action == "boolean_primaryfire" and not LocalPlayer():Alive() then return false end
end)

hook.Add("VRMod_Input", "LOD_VRInput", function(action, pressed)
    if not VR:IsActive(LocalPlayer()) then return end
    if action == "boolean_menucontext" and pressed then
        if not gui.IsGameUIVisible() and not gui.IsConsoleVisible() then VR:OpenPlayerMenu() end
        return
    end
    if VR:InputCovered() then return end
    if action == "boolean_use" and pressed then VR:ContextAction()
    elseif action == "boolean_primaryfire" and pressed and not LocalPlayer():Alive() then
        LOD.TetrisClient:RequestRespawn()
    elseif action == "boolean_jump" and pressed then
        local client = VR:TetrisClient()
        if client then client:SendInput(5) end
    end
end)

-- VRMod's analog stick does not generate PlayerBindPress. One token per stick
-- excursion reproduces keyboard Tetris presses; return to center to repeat.
-- This stream deliberately never feeds Equipment Special Move recipes.
hook.Add("Think", "LOD_VRTetrisStick", function()
    if not VR:IsActive(LocalPlayer()) then return end
    local client = VR:TetrisClient()
    local axis = g_VR and g_VR.input and g_VR.input.vector2_walkdirection
    if not client or VR:InputCovered() or not axis then stickDirection = "blocked";return end
    local x, y = axis.x or 0, axis.y or 0
    if math.max(math.abs(x), math.abs(y)) < 0.25 then stickDirection = nil;return end
    if stickDirection or math.max(math.abs(x), math.abs(y)) < 0.65 then return end
    stickDirection = math.abs(x) > math.abs(y) and (x < 0 and 1 or 2) or (y > 0 and 3 or 4)
    client:SendInput(stickDirection)
end)

concommand.Add("lod_vr_status", function()
    local server = util.NetworkStringToID("vrutil_net_join") ~= 0
    print("[LOD VR] Server VRMod: " .. (server and "available" or "missing — install the server Lua addon"))
    print("[LOD VR] Local tracking: " .. (VR:IsActive(LocalPlayer()) and "active" or "inactive"))
end)
