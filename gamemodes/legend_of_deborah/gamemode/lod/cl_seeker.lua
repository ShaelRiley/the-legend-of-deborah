LOD = LOD or {}
LOD.SeekerFX = LOD.SeekerFX or {}

local FX = LOD.SeekerFX
local glowMaterial = Material("sprites/light_glow02_add")
local beamMaterial = Material("cable/blue_elec")
local WINDUP_COLOR = Color(90, 205, 255, 245)
local CHARGE_COLOR = Color(180, 240, 255, 255)
local IMPACT_COLOR = Color(255, 230, 120, 255)

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
    return seeker:WorldSpaceCenter()
end

hook.Add("PostDrawTranslucentRenderables", "LOD_SeekerChargeFX", function()
    local now = CurTime()
    for seeker, state in pairs(FX.Active) do
        if not IsValid(seeker) or not state then
            FX.Active[seeker] = nil
        else
            local origin = seekerCenter(seeker)
            if origin then
                local elapsed = now - (state.startedAt or now)
                local duration = math.max(0.05, state.duration or 0.65)
                local progress = math.Clamp(elapsed / duration, 0, 1)
                local pulse = 0.5 + 0.5 * math.sin(now * (18 + progress * 18))
                local phase = state.phase or 1
                local color = phase == 3 and IMPACT_COLOR or (phase == 2 and CHARGE_COLOR or WINDUP_COLOR)

                render.SetMaterial(glowMaterial)
                local glow = phase == 2 and (13 + pulse * 6) or (9 + progress * 9 + pulse * 5)
                render.DrawSprite(origin, glow, glow, color)
                render.DrawSprite(origin + Vector(0, 0, 10), glow * 0.65, glow * 0.65,
                    Color(255, 255, 255, 180 + math.floor(pulse * 70)))

                if phase == 1 then
                    render.SetMaterial(beamMaterial)
                    local radius = 12 + progress * 18
                    for i = 0, 2 do
                        local a = now * (150 + i * 24) + i * 120
                        local offsetA = Angle(0, a, 0):Forward() * radius
                        local offsetB = Angle(0, a + 115, 0):Forward() * radius
                        render.DrawBeam(origin + offsetA, origin + offsetB, 2 + pulse * 1.5, 0, 1, color)
                    end
                elseif phase == 2 then
                    render.SetMaterial(beamMaterial)
                    local tail = seeker:GetForward() * -42
                    render.DrawBeam(origin, origin + tail, 5 + pulse * 3, 0, 1, color)
                end
            end
        end
    end
end)
