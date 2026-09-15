LOD = LOD or {}
LOD.GPSVoice = {}
local Voice = LOD.GPSVoice
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

Voice.Bank, Voice.Markers, Voice.Tokens = BANK, VOICE, voiceTokens
function Voice.Duration(text)
    local tokens = voiceTokens(text)
    if not tokens then return 0 end
    local duration = math.max(0, #tokens - 1) * 0.035
    for _, token in ipairs(tokens) do duration = duration + VOICE[token][2] end
    return duration
end
