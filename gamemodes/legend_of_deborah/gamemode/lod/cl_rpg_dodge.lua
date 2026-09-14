-- Presentation tunables: 120ms pulse, 4% motion afterimage, no persistent HUD.
local untilAt = 0
net.Receive("LOD_DodgePulse", function() untilAt = CurTime() + .12 end)
hook.Add("RenderScreenspaceEffects", "LOD_RPG_DodgePulse", function()
    if CurTime() >= untilAt then return end
    DrawMotionBlur(.96, .04 * math.Clamp((untilAt - CurTime()) / .12, 0, 1), .01)
end)
