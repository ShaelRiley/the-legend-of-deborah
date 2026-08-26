LOD = LOD or {}
LOD.WatcherFX = LOD.WatcherFX or {}

local FX = LOD.WatcherFX
local beamMaterial = Material("cable/redlaser")
local glowMaterial = Material("sprites/light_glow02_add")
local SCAN_COLOR = Color(90, 225, 255, 235)
local SCAN_COLOR_HOT = Color(205, 250, 255, 255)

FX.Active = FX.Active or setmetatable({}, {__mode = "k"})

net.Receive("LOD_WatcherScanState", function()
    local watcher = net.ReadEntity()
    local active = net.ReadBool()
    if not IsValid(watcher) then return end

    if not active then
        FX.Active[watcher] = nil
        return
    end

    local target = net.ReadEntity()
    local duration = math.max(0.05, net.ReadFloat())
    FX.Active[watcher] = {
        target = target,
        startedAt = CurTime(),
        duration = duration
    }
end)

hook.Add("EntityRemoved", "LOD_WatcherFXCleanup", function(ent)
    FX.Active[ent] = nil
end)

local function watcherOrigin(watcher)
    if not IsValid(watcher) then return nil end
    local attachment = watcher:LookupAttachment("light")
    if attachment and attachment > 0 then
        local data = watcher:GetAttachment(attachment)
        if data and data.Pos then return data.Pos end
    end
    return watcher:WorldSpaceCenter()
end

local function targetPoint(target)
    if not IsValid(target) then return nil end
    if target:IsPlayer() then return target:EyePos() end
    return target:WorldSpaceCenter()
end

hook.Add("PostDrawTranslucentRenderables", "LOD_WatcherScanBeam", function()
    local now = CurTime()
    for watcher, state in pairs(FX.Active) do
        local target = state and state.target
        if not IsValid(watcher) or not IsValid(target) then
            FX.Active[watcher] = nil
        else
            local origin = watcherOrigin(watcher)
            local destination = targetPoint(target)
            if origin and destination then
                local progress = math.Clamp((now - (state.startedAt or now)) / math.max(0.05, state.duration or 1.25), 0, 1)
                local pulse = 0.5 + 0.5 * math.sin(now * (14 + progress * 16))
                local width = 2.0 + progress * 3.0 + pulse * 1.2
                local color = progress > 0.70 and SCAN_COLOR_HOT or SCAN_COLOR

                render.SetMaterial(beamMaterial)
                render.DrawBeam(origin, destination, width, 0, 1, color)
                render.DrawBeam(origin, destination, math.max(1, width * 0.35), 0, 1,
                    Color(255, 255, 255, 170 + math.floor(70 * pulse)))

                render.SetMaterial(glowMaterial)
                local glow = 7 + progress * 7 + pulse * 3
                render.DrawSprite(origin, glow, glow, color)
                render.DrawSprite(destination, glow * 0.65, glow * 0.65, color)
            end
        end
    end
end)
