LOD = LOD or {}
LOD.RPGWisGPS = LOD.RPGWisGPS or {}
local GPS = LOD.RPGWisGPS
local NET_STATE = "LOD_RPGWisGPSState"
local NET_TOGGLE = "LOD_RPGWisGPSToggle"
local NET_BARK = "LOD_RPGWisGPSBark"
local fallbackLatch = false

include("legend_of_deborah/gamemode/lod/sh_gps_voice.lua")
local Voice = LOD.GPSVoice
local BANK, VOICE = Voice.Bank, Voice.Markers

local function notice(text)
    notification.AddLegacy(text, NOTIFY_GENERIC, 4)
    chat.AddText(Color(130, 220, 255), "[GPS] ", color_white, text)
end

local function switchChime()
    LOD.Audio:Play('gps')
end

local function requestToggle()
    if not GPS.Owned then return end
    net.Start(NET_TOGGLE)
    net.SendToServer()
end

local generation, activeChannel = 0, nil
local function stopSpeech()
    generation = generation + 1
    if IsValid(activeChannel) then activeChannel:Stop() end
    activeChannel = nil
end
local function speak(text)
    stopSpeech()
    local tokens = Voice.Tokens(text)
    if not tokens then return end
    local serial = generation
    sound.PlayFile(BANK, "mono noblock noplay", function(channel, errCode)
        if serial ~= generation or not GPS.Enabled then
            if IsValid(channel) then channel:Stop() end
            return
        end
        if not IsValid(channel) or errCode then LOD.Audio:Play('gps'); return end
        activeChannel = channel
        local index = 1
        local function current() return serial == generation and IsValid(channel) end
        local function playNext()
            if not current() then return end
            local marker = VOICE[tokens[index]]
            if not marker then stopSpeech(); return end
            channel:SetTime(marker[1])
            channel:Play()
            timer.Simple(marker[2], function()
                if not current() then return end
                channel:Pause()
                index = index + 1
                if index > #tokens then stopSpeech(); return end
                timer.Simple(0.035, playNext)
            end)
        end
        playNext()
    end)
end
hook.Add("ShutDown", "LOD_GPSStopVoice", stopSpeech)

concommand.Add("lod_gps_toggle", requestToggle)

net.Receive(NET_STATE, function()
    local enabled = net.ReadBool()
    local acquired = net.ReadBool()
    GPS.Owned = true
    GPS.Enabled = enabled
    if not enabled then stopSpeech() end
    if acquired then
        notice("GPS ENABLED — If it gets annoying, press G to turn it off. Press G again to turn it back on.")
    else
        switchChime()
        notice(enabled and "GPS ON" or "GPS OFF")
    end
end)

net.Receive(NET_BARK, function()
    local text = net.ReadString()
    if text == "" then stopSpeech(); return end
    if not GPS.Enabled then return end
    speak(text)
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

