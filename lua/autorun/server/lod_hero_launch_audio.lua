if not SERVER then return end

local HERO_CLASS = "lod_hero_crowbar_pulse"
local LAUNCH_NET = "LOD_HeroLaunchShimmerCue"

util.AddNetworkString(LAUNCH_NET)

-- Preserve the existing authored launch cue and add the new original two-part
-- laser response only when a genuine Hero projectile has been created.
hook.Add("OnEntityCreated", "LOD_HeroLaunchShimmerCue", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= HERO_CLASS then return end

    timer.Simple(0, function()
        if not IsValid(ent) then return end
        local pos = ent:GetPos()
        net.Start(LAUNCH_NET)
        net.WriteVector(pos)
        net.SendPVS(pos)
    end)
end)
