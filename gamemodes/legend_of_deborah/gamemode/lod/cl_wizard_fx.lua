-- First-person Wizard reactions observe committed server events. No gameplay,
-- camera shake, opaque screen wash, persistent emitters or extra network receiver.
LOD = LOD or {}
LOD.WizardFX = LOD.WizardFX or {}
local FX = LOD.WizardFX
FX.active, FX.sounds = {}, {}
local glow = Material("sprites/light_glow02_add")
local arcMaterial = Material("cable/blue_elec")
local DURATION = 0.80
local colors = {[1] = Color(125, 185, 255), [4] = Color(95, 240, 220)}
local sounds = {[1] = "legend_of_deborah/feedback/feedback.wav", [4] = "legend_of_deborah/feedback/diversion.wav"}
surface.CreateFont("LOD_WizardCue", {font="Trebuchet MS", size=21, weight=900, antialias=true})
surface.CreateFont("LOD_WizardDetail", {font="Trebuchet MS", size=16, weight=700, antialias=true})

local function reduced()
    local cv = GetConVar("lod_reduced_effects")
    return cv and cv:GetBool()
end
function FX:Reset()
    self.active, self.sounds = {}, {}
end
function FX:Trigger(kind, primary, secondary, serial, origin, target)
    local ply, now = LocalPlayer(), CurTime()
    if not colors[kind] or not IsValid(ply) then return false end
    -- Capture the world path now. Turning after a proc must not move its target.
    origin = origin or ply:GetShootPos()
    target = target or (origin + ply:GetAimVector() * 220)
    self.active[kind] = {kind=kind, created=now, primary=primary, secondary=secondary,
        origin=origin, target=target, owner=ply, serial=serial}
    -- Independent cues: simultaneous absorption and retaliation remain audible,
    -- while rapid chip damage cannot create an unbounded sound chorus.
    if now >= (self.sounds[kind] or 0) then
        surface.PlaySound(sounds[kind])
        self.sounds[kind] = now + (kind == 4 and 0.18 or 0.10)
    end
    return true
end

local function live(kind, now)
    local fx = FX.active[kind]
    if not fx then return end
    if now - fx.created >= DURATION or fx.owner ~= LocalPlayer() or not IsValid(fx.owner) then
        FX.active[kind] = nil
        return
    end
    return fx
end

-- Analytical motes are bounded to two short events. Nothing is spawned or scanned.
hook.Add("PostDrawTranslucentRenderables", "LOD_WizardReactionWorld", function(depth, skybox)
    if depth or skybox then return end
    local now = CurTime()
    for _, kind in ipairs({1,4}) do
        local fx = live(kind, now)
        if fx then
            local p = math.Clamp((now - fx.created) / DURATION, 0, 1)
            local tint = colors[kind]
            local color = Color(tint.r, tint.g, tint.b, math.floor(240 * (1-p)))
            local direction = (fx.target - fx.origin):GetNormalized()
            local start = fx.origin + direction * 18 + Vector(0,0,-8)
            if kind == 1 then
                -- Two crooked filaments travel outward along the actual return path.
                local ending = LerpVector(math.min(1, p / 0.20), start, fx.target)
                local side = direction:Angle():Right()
                local previous = start
                render.SetMaterial(arcMaterial)
                for i=1,8 do
                    local point = LerpVector(i/8, start, ending)
                        + side * (i == 8 and 0 or math.sin(i*2.7 + p*18) * (reduced() and 2 or 9))
                    render.DrawBeam(previous, point, 3.5 * (1-p) + 0.5, 0, 1, color)
                    previous = point
                end
                render.SetMaterial(glow)
                render.DrawSprite(ending, 22*(1-p)+4, 22*(1-p)+4, color)
                for i=1,(reduced() and 3 or 10) do
                    local angle = i*2.4
                    local mote = ending + Vector(math.cos(angle), math.sin(angle), math.sin(i*1.7)) * p*32
                    render.DrawSprite(mote, 4, 4, color)
                end
            else
                local side, up = direction:Angle():Right(), Vector(0,0,1)
                render.SetMaterial(glow)
                for i=1,(reduced() and 4 or 14) do
                    local angle = i*2.4 + p*1.4
                    local radius = 32*(1-p)+5
                    local mote = start + direction*24 + side*math.cos(angle)*radius + up*math.sin(angle)*radius
                    render.DrawSprite(mote, 5, 5, color)
                end
            end
        end
    end
end)

hook.Add("PostDrawHUD", "LOD_WizardReactionHUD", function()
    local now, scale = CurTime(), math.Clamp(ScrH()/800, 0.8, 1.3)
    for _, kind in ipairs({1,4}) do
        local fx = live(kind, now)
        if fx then
            local p = math.Clamp((now-fx.created)/DURATION, 0, 1)
            local tint = colors[kind]
            local alpha = math.floor(255 * math.min(1, (1-p)*3))
            local color, outline = Color(tint.r,tint.g,tint.b,alpha), Color(0,0,0,alpha)
            local cx, cy = ScrW()*0.5, ScrH()*(kind == 1 and 0.61 or 0.70)
            local radius = (reduced() and 25 or (kind == 4 and 44-20*p or 20+24*p))*scale
            surface.SetDrawColor(color)
            -- Inward diamond sparks = absorption; outward forked sparks = return.
            for i=1,(reduced() and 4 or 8) do
                local a = i*math.pi/4
                local x,y = cx+math.cos(a)*radius, cy-18*scale+math.sin(a)*radius*0.34
                surface.DrawLine(x-3,y,x,y-3)
                surface.DrawLine(x,y-3,x+3,y)
                surface.DrawLine(x+3,y,x,y+3)
                surface.DrawLine(x,y+3,x-3,y)
            end
            draw.SimpleTextOutlined(fx.primary or "", "LOD_WizardCue", cx, cy, color,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, outline)
            draw.SimpleTextOutlined(fx.secondary or "", "LOD_WizardDetail", cx, cy+23*scale,
                Color(220,250,255,alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, outline)
        end
    end
end)
hook.Add("PreCleanupMap", "LOD_WizardReactionCleanup", function() FX:Reset() end)
hook.Add("ShutDown", "LOD_WizardReactionShutdown", function() FX:Reset() end)
