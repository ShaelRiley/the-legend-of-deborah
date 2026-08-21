LOD = LOD or {}

-- The production labyrinth should never inherit gm_flatgrass's familiar daytime
-- sky. Use a stock Source night sky so the otherwise-open map reads as an
-- anomalous midnight prison rather than ordinary Flatgrass. sv_skyname is a
-- replicated server convar, so one authoritative change updates every client
-- without bundling a custom skybox texture or adding a Workshop dependency.
local SKY_NAME = "sky_borealis01"

local function applyMidnightSky()
    local cv = GetConVar("sv_skyname")
    if not cv then return end
    if cv:GetString() == SKY_NAME then return end

    RunConsoleCommand("sv_skyname", SKY_NAME)
    print(string.format("[LOD] Midnight skybox applied: %s", SKY_NAME))
end

-- Apply after map entities exist, and reassert after a map cleanup because some
-- sandbox/map flows may restore map-authored presentation state.
hook.Add("InitPostEntity", "LOD.MidnightSkybox", function()
    timer.Simple(0, applyMidnightSky)
end)

hook.Add("PostCleanupMap", "LOD.MidnightSkybox", function()
    timer.Simple(0, applyMidnightSky)
end)

-- Also cover late Lua initialization on a listen server.
timer.Simple(0, applyMidnightSky)
