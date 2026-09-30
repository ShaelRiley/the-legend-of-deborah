-- Optional VRMod adapter. Tracking, stereo rendering and network poses belong
-- to VRMod; Deborah keeps its ordinary equipment, movement and action authority.
LOD.VR = LOD.VR or {}
local VR = LOD.VR

function VR:IsActive(ply)
    if not vrmod or not vrmod.IsPlayerInVR or not IsValid(ply) then return false end
    if CLIENT and ply == LocalPlayer() then
        return g_VR ~= nil and g_VR.active == true
    end
    return vrmod.IsPlayerInVR(ply) == true
end

if SERVER then
    hook.Add("Initialize", "LOD_VRGameplayPolicy", function()
        -- Stock HL2 weapons already use VRMod's tracked muzzle and command aim.
        -- Replacing them with ArcVR weapons would discard Deborah's item state.
        for _, name in ipairs({"vrmod_weapon_swap", "vrmod_allow_teleport"}) do
            local setting = GetConVar(name)
            if setting then setting:SetBool(false) end
        end
    end)
end
