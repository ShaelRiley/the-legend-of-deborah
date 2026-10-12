if SERVER then return end

LOD = LOD or {}
LOD.RPGMajorFX = LOD.RPGMajorFX or {}

local FX = LOD.RPGMajorFX
local NET_NAME = "LOD_RPGMajorFX"
local ACK_NAME = "LOD_RPGMajorFXAck"
local FX_FEEDBACK = 1
local FX_LEVEL_UP = 2
local FX_FEAT_CONFIRM = 3
local FX_MAP_FOUND = 5
local LEVEL_UP_FX_SECONDS = 1.80

FX.ClientVersion = 5
FX.active = FX.active or nil

surface.CreateFont("LOD_RPGMajorFXPrimary", {
    font = "DejaVu Sans",
    size = 58,
    weight = 1000,
    antialias = true
})

surface.CreateFont("LOD_RPGMajorFXSecondary", {
    font = "DejaVu Sans",
    size = 22,
    weight = 900,
    antialias = true
})

local function playLevelSound()
    if LOD.AdventurePresentation then LOD.AdventurePresentation:Play(5, false) end
end
local function playFeatSound()
    if LOD.AdventurePresentation then LOD.AdventurePresentation:Play(7, false) end
end

function FX:Trigger(kind, primary, secondary, serial, origin, target)
    kind = math.floor(tonumber(kind) or 0)
    -- Wizard reactions have their own brief layer; a level-up cannot mute them.
    if kind == FX_FEEDBACK or kind == 4 then
        return LOD.WizardFX and LOD.WizardFX:Trigger(kind, primary, secondary, serial, origin, target) or false
    end
    if kind == FX_FEAT_CONFIRM then
        playFeatSound()
        return true
    end

    self.active = {
        kind = kind,
        primary = tostring(primary or ""),
        secondary = tostring(secondary or ""),
        serial = math.floor(tonumber(serial) or 0),
        created = CurTime()
    }

    if kind==FX_MAP_FOUND then
        if LOD.AdventurePresentation then LOD.AdventurePresentation:Play(1,false) end
    else
        playLevelSound()
    end
    return true
end

net.Receive(NET_NAME, function()
    local serial = net.ReadUInt(16)
    local kind = net.ReadUInt(3)
    local primary = net.ReadString()
    local secondary = net.ReadString()

    local origin, target
    if kind == FX_FEEDBACK or kind == 4 then origin, target = net.ReadVector(), net.ReadVector() end
    local triggered = FX:Trigger(kind, primary, secondary, serial, origin, target)

    net.Start(ACK_NAME)
    net.WriteUInt(serial, 16)
    net.WriteUInt(kind, 3)
    net.WriteBool(triggered == true)
    net.SendToServer()
end)

local function alphaEnvelope(age, duration)
    local fadeIn = math.Clamp(age / 0.08, 0, 1)
    local fadeOut = math.Clamp((duration - age) / 0.42, 0, 1)
    return math.min(fadeIn, fadeOut)
end

-- Level-up remains intentionally larger and longer than ordinary combat feedback.
-- This is the presentation that passed the current Wizard playtest unchanged.
local function drawLevelUpBurst(fx, now)
    local age = now - (fx.created or 0)
    if fx.kind==FX_MAP_FOUND then
        if age>=4 then FX.active=nil;return end
        local alpha=math.floor(255*alphaEnvelope(age,4))
        local x,y=ScrW()*0.5,ScrH()*0.39
        local bright,dark=Color(255,248,205,alpha),Color(32,20,3,alpha)
        surface.SetFont("LOD_RPGMajorFXPrimary")
        local textW=surface.GetTextSize("Use map with Q")
        local scale=math.min(1,math.max(0.25,(ScrW()-32)/math.max(1,textW+40)))
        local matrix
        if scale~=1 then
            matrix=Matrix();matrix:SetScale(Vector(scale,scale,1))
            matrix:SetTranslation(Vector(x*(1-scale),y*(1-scale),0))
            cam.PushModelMatrix(matrix,true)
        end
        draw.RoundedBox(8,x-(textW+40)*0.5,y-44,textW+40,144,Color(12,15,17,math.floor(alpha*0.92)))
        draw.SimpleTextOutlined("Use map with Q","LOD_RPGMajorFXPrimary",x,y-10,bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,4,dark)
        draw.SimpleTextOutlined("M works too","LOD_RPGMajorFXSecondary",x,y+40,bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,2,dark)
        draw.SimpleTextOutlined("Map consumes magic","LOD_RPGMajorFXSecondary",x,y+72,bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,2,dark)
        if matrix then cam.PopModelMatrix() end
        return
    end
    if age >= LEVEL_UP_FX_SECONDS then
        FX.active = nil
        return
    end

    local fraction = math.Clamp(age / LEVEL_UP_FX_SECONDS, 0, 1)
    local envelope = alphaEnvelope(age, LEVEL_UP_FX_SECONDS)
    local alpha = math.floor(255 * envelope)
    local w, h = ScrW(), ScrH()
    local cx, cy = w * 0.5, h * 0.39
    local expansion = 1 - math.pow(1 - fraction, 3)
    local radius = 46 + 150 * expansion
    local base = Color(255, 205, 70, alpha)
    local bright = Color(255, 248, 205, alpha)
    local dark = Color(32, 20, 3, math.floor(alpha * 0.94))

    local reduced = LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced()
    if reduced then radius = 62 end

    surface.SetDrawColor(base)
    surface.DrawCircle(cx, cy, radius, base.r, base.g, base.b, alpha)
    surface.DrawCircle(cx, cy, radius * 0.72, bright.r, bright.g, bright.b, math.floor(alpha * 0.82))
    surface.DrawCircle(cx, cy, radius * 0.46, base.r, base.g, base.b, math.floor(alpha * 0.62))

    for i = 0, (reduced and 5 or 19) do
        local angle = (i / 20) * math.pi * 2 + fraction * 0.55
        local inner = radius * 0.68
        local outer = radius * (1.08 + ((i % 2) * 0.22))
        surface.DrawLine(
            cx + math.cos(angle) * inner,
            cy + math.sin(angle) * inner,
            cx + math.cos(angle) * outer,
            cy + math.sin(angle) * outer)
    end

    draw.SimpleTextOutlined(
        fx.primary ~= "" and fx.primary or "LEVEL UP!",
        "LOD_RPGMajorFXPrimary",
        cx,
        cy - 15,
        bright,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER,
        4,
        dark)

    if fx.secondary and fx.secondary ~= "" then
        draw.SimpleTextOutlined(
            fx.secondary,
            "LOD_RPGMajorFXSecondary",
            cx,
            cy + 34,
            bright,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            2,
            dark)
    end
end

-- The rare level-up layer is independent of the Wizard reaction layer.
hook.Add("PostDrawHUD", "LOD_RPGMajorFX", function()
    if not FX.active then return end
    if FX.active.kind==FX_MAP_FOUND then
        local ply=LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then FX.active=nil;return end
    end
    drawLevelUpBurst(FX.active, CurTime())
end)

hook.Add("PreCleanupMap", "LOD_FloorMapPickupFXReset", function()
    if FX.active and FX.active.kind==FX_MAP_FOUND then FX.active=nil end
end)

-- Local presentation-only diagnostic. It does not alter progression or combat.
-- Usage: lod_rpg_major_fx_test level / feedback / diversion
concommand.Add("lod_rpg_major_fx_test", function(_, _, args)
    local mode = string.lower(tostring(args and args[1] or "level"))
    if mode == "feedback" then
        FX:Trigger(FX_FEEDBACK, "FEEDBACK!", "(7) DAMAGE — 2d4+1", 0)
    elseif mode == "diversion" then
        FX:Trigger(4, "ARCANE DIVERSION", "4 HP SAVED / -4 MAGIC", 0)
    else
        FX:Trigger(FX_LEVEL_UP, "LEVEL UP!", "PRESS P TO SEE", 0)
    end
end)
