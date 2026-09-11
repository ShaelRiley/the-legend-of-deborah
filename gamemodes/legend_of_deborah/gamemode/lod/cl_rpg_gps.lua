LOD = LOD or {}
LOD.RPGWisGPS = LOD.RPGWisGPS or {}
local GPS = LOD.RPGWisGPS
local NET_STATE = "LOD_RPGWisGPSState"
local NET_TOGGLE = "LOD_RPGWisGPSToggle"
local NET_BARK = "LOD_RPGWisGPSBark"
local fallbackLatch = false

local function notice(text)
    notification.AddLegacy(text, NOTIFY_GENERIC, 4)
    chat.AddText(Color(130, 220, 255), "[GPS] ", color_white, text)
end

local function switchChime()
    surface.PlaySound("buttons/button14.wav")
end

local function requestToggle()
    if not GPS.Owned then return end
    net.Start(NET_TOGGLE)
    net.SendToServer()
end

concommand.Add("lod_gps_toggle", requestToggle)

net.Receive(NET_STATE, function()
    local enabled = net.ReadBool()
    local acquired = net.ReadBool()
    GPS.Owned = true
    GPS.Enabled = enabled
    if acquired then
        notice("GPS ENABLED — If it gets annoying, press G to turn it off. Press G again to turn it back on.")
    else
        switchChime()
        notice(enabled and "GPS ON" or "GPS OFF")
    end
end)

net.Receive(NET_BARK, function()
    local text = net.ReadString()
    surface.PlaySound("buttons/blip1.wav")
    notice(text)
end)

hook.Add("Think", "LOD_RPGWisGPSDefaultBinding", function()
    if not GPS.Owned then fallbackLatch = false; return end
    if input.LookupBinding("lod_gps_toggle", true) then fallbackLatch = false; return end
    if gui.IsGameUIVisible() or vgui.GetKeyboardFocus() then fallbackLatch = false; return end
    local down = input.IsKeyDown(KEY_G)
    if down and not fallbackLatch then requestToggle() end
    fallbackLatch = down
end)
