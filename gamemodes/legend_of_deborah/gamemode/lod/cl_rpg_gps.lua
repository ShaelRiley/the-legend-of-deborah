LOD = LOD or {}
LOD.RPGWisGPS = LOD.RPGWisGPS or {}
local GPS = LOD.RPGWisGPS
local NET_STATE = "LOD_RPGWisGPSState"
local NET_TOGGLE = "LOD_RPGWisGPSToggle"
local NET_BARK = "LOD_RPGWisGPSBark"
local fallbackLatch = false

local BANK = "sound/lod/gps_voice_bank.mp3"
local VOICE = {
    turn_left={0.0000,0.5107}, turn_right={0.5507,0.5015}, turn_around={1.0922,0.5652},
    continue_forward={1.6974,0.9076}, ["in"]={2.6450,0.2570}, square={2.9420,0.4118},
    squares={3.3938,0.4922}, stairs_up={3.9260,0.8946}, stairs_down={4.8606,0.9926},
    arrived={5.8932,1.5404}, zero={7.4735,0.3878}, one={7.9013,0.3236},
    two={8.2649,0.2666}, three={8.5714,0.2927}, four={8.9042,0.3189},
    five={9.2631,0.3838}, six={9.6869,0.3763}, seven={10.1032,0.4023},
    eight={10.5455,0.2719}, nine={10.8574,0.3849}
}
local DIGIT = {["0"]="zero",["1"]="one",["2"]="two",["3"]="three",["4"]="four",
    ["5"]="five",["6"]="six",["7"]="seven",["8"]="eight",["9"]="nine"}

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

local function voiceTokens(text)
    if text == "TURN LEFT" then return {"turn_left"} end
    if text == "TURN RIGHT" then return {"turn_right"} end
    if text == "TURN AROUND" then return {"turn_around"} end
    if text == "CONTINUE FORWARD" then return {"continue_forward"} end
    if text == "TAKE THE STAIRS UP" then return {"stairs_up"} end
    if text == "TAKE THE STAIRS DOWN" then return {"stairs_down"} end
    if text == "YOU HAVE ARRIVED AT YOUR DESTINATION" then return {"arrived"} end

    local n, noun, action = string.match(text, "^IN (%d+) (SQUARES?) (.+)$")
    if not n then return nil end
    local out = {"in"}
    for digit in string.gmatch(n, ".") do out[#out + 1] = DIGIT[digit] end
    out[#out + 1] = noun == "SQUARE" and "square" or "squares"
    if action == "TURN LEFT" then out[#out + 1] = "turn_left"
    elseif action == "TURN RIGHT" then out[#out + 1] = "turn_right"
    elseif action == "TAKE THE STAIRS UP" then out[#out + 1] = "stairs_up"
    elseif action == "TAKE THE STAIRS DOWN" then out[#out + 1] = "stairs_down"
    else return nil end
    return out
end

local function speak(text)
    local tokens = voiceTokens(text)
    if not tokens then surface.PlaySound("buttons/blip1.wav"); return end
    sound.PlayFile(BANK, "mono noblock noplay", function(channel, errCode)
        if not channel or errCode then surface.PlaySound("buttons/blip1.wav"); return end
        local index = 1
        local function playNext()
            local marker = VOICE[tokens[index]]
            if not marker then channel:Stop(); return end
            channel:SetTime(marker[1])
            channel:Play()
            timer.Simple(marker[2], function()
                if not channel then return end
                channel:Pause()
                index = index + 1
                if index > #tokens then channel:Stop(); return end
                timer.Simple(0.035, playNext)
            end)
        end
        playNext()
    end)
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
