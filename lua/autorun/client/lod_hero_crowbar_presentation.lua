if not CLIENT then return end

local HERO_CLASS = "lod_hero_crowbar_pulse"
local LAUNCH_NET = "LOD_HeroLaunchShimmerCue"
local AUDIO_DATA_PATH = "lod/hero_of_legend_launch_shimmer.wav"
local AUDIO_PLAY_PATH = "data/" .. AUDIO_DATA_PATH
local AUDIO_REVISION = "two_part_laser_v1"
local PRESENTATION_REVISION = "hero_shimmer_translucent_v1"

local SAMPLE_RATE = 22050
local DURATION = 0.52
local SECOND_BEAT = 0.165
local TWO_PI = math.pi * 2

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function u16le(value)
    value = math.floor(value) % 65536
    return string.char(value % 256, math.floor(value / 256) % 256)
end

local function u32le(value)
    value = math.floor(value)
    return string.char(
        value % 256,
        math.floor(value / 256) % 256,
        math.floor(value / 65536) % 256,
        math.floor(value / 16777216) % 256)
end

local function pcm16le(value)
    local sample = math.floor(clamp(value, -1, 1) * 32767)
    if sample < 0 then sample = sample + 65536 end
    return u16le(sample)
end

local function envelope(localTime, attack, hold, release)
    if localTime < 0 then return 0 end
    if localTime < attack then
        local x = localTime / attack
        return math.sin(x * math.pi * 0.5) ^ 2
    end
    if localTime < attack + hold then return 1 end
    if localTime < attack + hold + release then
        local x = (localTime - attack - hold) / release
        return math.cos(x * math.pi * 0.5) ^ 2
    end
    return 0
end

-- This is an original deterministic synthesis. It follows the supplied
-- reference only at the structural level: a compact launch syllable followed
-- by a separate answering zap. No source samples or melody are reproduced.
local function synthesizeLaunchCue()
    local sampleCount = math.floor(SAMPLE_RATE * DURATION)
    local samples = {}
    local phaseLaunch = 0
    local phaseAnswerDown = 0
    local phaseAnswerUp = 0
    local noiseSeed = 51966
    local previousNoise = 0

    for i = 0, sampleCount - 1 do
        local t = i / SAMPLE_RATE

        local launchX = clamp(t / 0.18, 0, 1)
        local launchFrequency = 720 + (1840 - 720) * (launchX ^ 0.55)
        phaseLaunch = phaseLaunch + TWO_PI * launchFrequency / SAMPLE_RATE
        local launchEnvelope = envelope(t, 0.004, 0.030, 0.145)
        local launchTone = 0.62 * math.sin(phaseLaunch)
            + 0.22 * math.sin(phaseLaunch * 2.02 + 0.4)
            + 0.12 * (math.sin(phaseLaunch * 0.51) >= 0 and 1 or -1)

        noiseSeed = (noiseSeed * 25173 + 13849) % 65536
        local noise = noiseSeed / 32768 - 1
        local highNoise = noise - previousNoise * 0.90
        previousNoise = noise
        local crackle = t < 0.095 and math.exp(-t / 0.026) * highNoise or 0
        local firstBeat = launchEnvelope * launchTone + 0.16 * crackle

        local answerTime = t - SECOND_BEAT
        local secondBeat = 0
        if answerTime >= 0 then
            local answerDuration = DURATION - SECOND_BEAT
            local answerX = clamp(answerTime / answerDuration, 0, 1)
            local downFrequency = 1320 + (430 - 1320) * (answerX ^ 0.72)
            local upFrequency = 460 + (1160 - 460) * (answerX ^ 1.35)
            phaseAnswerDown = phaseAnswerDown + TWO_PI * downFrequency / SAMPLE_RATE
            phaseAnswerUp = phaseAnswerUp + TWO_PI * upFrequency / SAMPLE_RATE
            local answerEnvelope = envelope(answerTime, 0.003, 0.025, 0.285)
            local metallic = 0.50 * math.sin(phaseAnswerDown + 0.25)
                + 0.27 * math.sin(phaseAnswerDown * 1.51)
                + 0.19 * math.sin(phaseAnswerUp + 1.1)
            metallic = math.floor(metallic * 18 + 0.5) / 18
            secondBeat = answerEnvelope * metallic
        end

        local shimmer = 0
        if answerTime >= 0 then
            shimmer = 0.07 * math.exp(-answerTime / 0.19)
                * math.sin(TWO_PI * (2380 * t + 620 * t * t))
        end

        local value = 0.52 * firstBeat + 0.64 * secondBeat + shimmer
        local edgeFade = 0.008
        if t < edgeFade then value = value * (t / edgeFade) end
        if t > DURATION - edgeFade then
            value = value * ((DURATION - t) / edgeFade)
        end
        samples[#samples + 1] = pcm16le(value)
    end

    local data = table.concat(samples)
    local byteRate = SAMPLE_RATE * 2
    local header = "RIFF" .. u32le(36 + #data) .. "WAVE"
        .. "fmt " .. u32le(16) .. u16le(1) .. u16le(1)
        .. u32le(SAMPLE_RATE) .. u32le(byteRate) .. u16le(2) .. u16le(16)
        .. "data" .. u32le(#data)
    return header .. data
end

local function installAudioAsset()
    file.CreateDir("lod")
    local markerPath = "lod/hero_of_legend_launch_shimmer_revision.txt"
    if file.Exists(AUDIO_DATA_PATH, "DATA")
        and file.Read(markerPath, "DATA") == AUDIO_REVISION then
        return true
    end

    file.Write(AUDIO_DATA_PATH, synthesizeLaunchCue())
    file.Write(markerPath, AUDIO_REVISION)
    return file.Exists(AUDIO_DATA_PATH, "DATA")
end

installAudioAsset()

local function playLaunchCue(pos)
    if not installAudioAsset() then return end
    sound.PlayFile(AUDIO_PLAY_PATH, "3d mono noblock noplay", function(channel, errId, errName)
        if not IsValid(channel) then
            ErrorNoHalt(string.format(
                "[LOD:RPG-E] Hero launch cue failed id=%s error=%s\n",
                tostring(errId), tostring(errName)))
            return
        end
        channel:SetPos(pos)
        channel:SetVolume(0.74)
        channel:Play()
    end)
end

net.Receive(LAUNCH_NET, function()
    playLaunchCue(net.ReadVector())
end)

local MODEL_ALPHA = 82 -- approximately 32% opacity
local SHELL_ALPHA = 24
local GLOW_ALPHA = 34
local GLOW_MATERIAL = Material("sprites/light_glow02_add")
local SHELL_MATERIAL = Material("models/debug/debugwhite")

local PALETTE = {
    Color(255, 188, 42),
    Color(255, 104, 28),
    Color(44, 118, 236),
    Color(16, 31, 84),
    Color(255, 205, 68)
}

local function gradientColor(phase)
    local count = #PALETTE
    local scaled = (phase % 1) * count
    local index = math.floor(scaled) + 1
    local fraction = scaled - math.floor(scaled)
    local a = PALETTE[index]
    local b = PALETTE[(index % count) + 1]
    return Color(
        Lerp(fraction, a.r, b.r),
        Lerp(fraction, a.g, b.g),
        Lerp(fraction, a.b, b.b),
        255)
end

local function drawHeroPulse(self)
    if not IsValid(self) then return end

    local now = CurTime()
    local phase = (now * 0.52 + self:EntIndex() * 0.071) % 1
    local mainColor = gradientColor(phase)
    local center = self:WorldSpaceCenter()
    local baseAngles = self:GetAngles()
    self:SetRenderAngles(Angle(
        baseAngles.p + math.sin(now * 5.2) * 4,
        baseAngles.y,
        baseAngles.r + now * 430))

    render.SuppressEngineLighting(true)
    render.SetBlend(MODEL_ALPHA / 255)
    render.SetColorModulation(
        mainColor.r / 255,
        mainColor.g / 255,
        mainColor.b / 255)
    self:DrawModel()

    render.MaterialOverride(SHELL_MATERIAL)
    render.SetBlend(SHELL_ALPHA / 255)
    local shellColor = gradientColor(phase + 0.17)
    render.SetColorModulation(
        shellColor.r / 255,
        shellColor.g / 255,
        shellColor.b / 255)
    self:DrawModel()
    render.MaterialOverride()
    render.SetColorModulation(1, 1, 1)
    render.SetBlend(1)
    render.SuppressEngineLighting(false)
    self:SetRenderAngles(nil)

    render.SetMaterial(GLOW_MATERIAL)
    local forward = self:GetForward()
    for i = -2, 2 do
        local nodePhase = phase + (i + 2) * 0.095
        local nodeColor = gradientColor(nodePhase)
        local pulse = 0.72 + 0.28 * math.sin(now * 8.5 + i * 1.4)
        local size = (28 + (2 - math.abs(i)) * 5) * pulse
        local alpha = math.floor(GLOW_ALPHA * pulse)
        render.DrawSprite(
            center + forward * (i * 9),
            size,
            size,
            Color(nodeColor.r, nodeColor.g, nodeColor.b, alpha))
    end

    local auraColor = gradientColor(phase + 0.31)
    local auraPulse = 0.82 + 0.18 * math.sin(now * 6.2)
    render.DrawSprite(
        center,
        58 * auraPulse,
        58 * auraPulse,
        Color(auraColor.r, auraColor.g, auraColor.b, 20))

    local light = DynamicLight(self:EntIndex())
    if light then
        light.pos = center
        light.r = mainColor.r
        light.g = mainColor.g
        light.b = mainColor.b
        light.brightness = 0.65
        light.decay = 320
        light.size = 105
        light.dietime = now + 0.08
    end
end

local function installPresentation()
    local stored = scripted_ents.GetStored(HERO_CLASS)
    local class = stored and stored.t
    if not class then return false end
    if class.LODHeroPresentationRevision == PRESENTATION_REVISION then return true end

    class.LODHeroPresentationRevision = PRESENTATION_REVISION
    class.RenderGroup = RENDERGROUP_TRANSLUCENT
    class.Draw = drawHeroPulse
    class.DrawTranslucent = drawHeroPulse
    return true
end

hook.Add("InitPostEntity", "LOD_HeroShimmerPresentation", installPresentation)
hook.Add("OnEntityCreated", "LOD_HeroShimmerPresentationLateBind", function(ent)
    if IsValid(ent) and ent:GetClass() == HERO_CLASS then
        installPresentation()
    end
end)

timer.Create("LOD_HeroShimmerPresentationBootstrap", 0.25, 40, function()
    if installPresentation() then
        timer.Remove("LOD_HeroShimmerPresentationBootstrap")
    end
end)
