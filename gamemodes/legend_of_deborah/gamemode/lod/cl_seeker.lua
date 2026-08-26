LOD = LOD or {}
LOD.SeekerFX = LOD.SeekerFX or {}

local FX = LOD.SeekerFX
local glowMaterial = Material("sprites/light_glow02_add")
local beamMaterial = Material("cable/blue_elec")
local WINDUP_COLOR = Color(80, 220, 255, 255)
local CHARGE_COLOR = Color(205, 250, 255, 255)
local IMPACT_COLOR = Color(255, 225, 110, 255)
local SEEKER_VISUAL_LIFT = Vector(0, 0, 8)

FX.Active = FX.Active or setmetatable({}, {__mode = "k"})

net.Receive("LOD_SeekerState", function()
    local seeker = net.ReadEntity()
    local phase = net.ReadUInt(2)
    local duration = net.ReadFloat()
    if not IsValid(seeker) then return end

    if phase == 0 then
        FX.Active[seeker] = nil
        return
    end

    FX.Active[seeker] = {
        phase = phase,
        startedAt = CurTime(),
        duration = math.max(0.05, duration)
    }
end)

hook.Add("EntityRemoved", "LOD_SeekerFXCleanup", function(ent)
    FX.Active[ent] = nil
end)

local function seekerCenter(seeker)
    if not IsValid(seeker) then return nil end
    return seeker:WorldSpaceCenter() + SEEKER_VISUAL_LIFT
end

hook.Add("PreDrawHalos", "LOD_SeekerChargeHalo", function()
    local windups = {}
    local charges = {}
    local impacts = {}

    for seeker, state in pairs(FX.Active) do
        if not IsValid(seeker) or not state then
            FX.Active[seeker] = nil
        elseif state.phase == 1 then
            windups[#windups + 1] = seeker
        elseif state.phase == 2 then
            charges[#charges + 1] = seeker
        elseif state.phase == 3 then
            impacts[#impacts + 1] = seeker
        end
    end

    if #windups > 0 then halo.Add(windups, WINDUP_COLOR, 5, 5, 2, true, true) end
    if #charges > 0 then halo.Add(charges, CHARGE_COLOR, 7, 7, 2, true, true) end
    if #impacts > 0 then halo.Add(impacts, IMPACT_COLOR, 8, 8, 2, true, true) end
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_SeekerChargeFX", function()
    local now = CurTime()
    for seeker, state in pairs(FX.Active) do
        if not IsValid(seeker) or not state then
            FX.Active[seeker] = nil
        else
            local origin = seekerCenter(seeker)
            if origin then
                local elapsed = now - (state.startedAt or now)
                local duration = math.max(0.05, state.duration or 0.85)
                local progress = math.Clamp(elapsed / duration, 0, 1)
                local pulse = 0.5 + 0.5 * math.sin(now * (22 + progress * 24))
                local phase = state.phase or 1
                local color = phase == 3 and IMPACT_COLOR or (phase == 2 and CHARGE_COLOR or WINDUP_COLOR)

                local light = DynamicLight(seeker:EntIndex())
                if light then
                    light.pos = origin
                    light.r = color.r
                    light.g = color.g
                    light.b = color.b
                    light.brightness = phase == 1 and (2 + progress * 3) or 3.5
                    light.Decay = 700
                    light.Size = phase == 1 and (90 + progress * 100) or 130
                    light.DieTime = now + 0.08
                end

                render.SetMaterial(glowMaterial)
                local glow
                if phase == 1 then
                    glow = 22 + progress * 28 + pulse * 9
                elseif phase == 2 then
                    glow = 28 + pulse * 12
                else
                    glow = 38 + pulse * 16
                end
                render.DrawSprite(origin, glow, glow, color)
                render.DrawSprite(origin + Vector(0, 0, 10), glow * 0.72, glow * 0.72,
                    Color(255, 255, 255, 195 + math.floor(pulse * 60)))

                render.SetMaterial(beamMaterial)
                if phase == 1 then
                    local radius = 32 - progress * 15
                    for i = 0, 2 do
                        local a = now * (190 + i * 25) + i * 120
                        local offsetA = Angle(0, a, 0):Forward() * radius
                        local offsetB = Angle(0, a + 120, 0):Forward() * radius
                        render.DrawBeam(origin + offsetA, origin + offsetB, 4 + pulse * 2, 0, 1, color)
                    end
                    local forward = seeker:GetForward()
                    render.DrawBeam(origin, origin + forward * (90 + progress * 90),
                        5 + pulse * 2, 0, 1, color)
                elseif phase == 2 then
                    local tail = seeker:GetForward() * -64
                    render.DrawBeam(origin, origin + tail, 8 + pulse * 4, 0, 1, color)
                    render.DrawBeam(origin + Vector(0, 0, 5), origin + tail * 0.72,
                        4 + pulse * 2, 0, 1, Color(255, 255, 255, 220))
                elseif phase == 3 then
                    local radius = 26 + progress * 34
                    for i = 0, 3 do
                        local a = i * 90 + now * 80
                        local arm = Angle(0, a, 0):Forward() * radius
                        render.DrawBeam(origin, origin + arm, 5, 0, 1, color)
                    end
                end
            end
        end
    end
end)