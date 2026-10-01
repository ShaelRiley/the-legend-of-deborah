-- Optional VRMod adapter. Tracking, stereo rendering and network poses belong
-- to VRMod; Deborah keeps its ordinary equipment, movement and action authority.
LOD.VR = LOD.VR or {}
local VR = LOD.VR
VR.AddonRevision = "2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc"
VR.Channels = {"vrutil_net_join", "vrutil_net_tick", "vrutil_net_exit",
    "vrutil_net_requestvrplayers", "vrutil_net_switchweapon"}
VR.ContentFiles = {
    "materials/vrmod/tpbeam.vmt", "materials/vrmod/tpbeam.vtf",
    "models/player/vr_hands.dx80.vtx", "models/player/vr_hands.dx90.vtx",
    "models/player/vr_hands.mdl", "models/player/vr_hands.phy", "models/player/vr_hands.vvd",
    "models/vrmod/tpbeam.dx80.vtx", "models/vrmod/tpbeam.dx90.vtx",
    "models/vrmod/tpbeam.mdl", "models/vrmod/tpbeam.vvd"
}

function VR:ServerReady()
    for _, name in ipairs(self.Channels) do
        if util.NetworkStringToID(name) == 0 then return false, "missing network channel " .. name end
    end
    if SERVER then
        for _, name in ipairs({"IsPlayerInVR", "NetReceiveLimited", "GetHMDPose", "GetRightHandPose", "GetLeftHandPose"}) do
            if not vrmod or not isfunction(vrmod[name]) then return false, "missing VRMod API " .. name end
        end
        for _, name in ipairs(self.ContentFiles) do
            if not file.Exists(name, "GAME") then return false, "missing VR content " .. name end
        end
    elseif not GetGlobalBool("LOD_VRServerReady", false) then
        return false, "server VR startup check did not pass"
    end
    return true
end

function VR:IsActive(ply)
    if not vrmod or not vrmod.IsPlayerInVR or not IsValid(ply) then return false end
    if CLIENT and ply == LocalPlayer() then
        return g_VR ~= nil and g_VR.active == true
    end
    return vrmod.IsPlayerInVR(ply) == true
end

if SERVER then
    local function applyGameplayPolicy()
        -- Stock HL2 weapons already use VRMod's tracked muzzle and command aim.
        -- Replacing them with ArcVR weapons would discard Deborah's item state.
        for _, name in ipairs({"vrmod_weapon_swap", "vrmod_allow_teleport"}) do
            local setting = GetConVar(name)
            if setting then setting:SetBool(false) end
        end
    end
    hook.Add("Initialize", "LOD_VRGameplayPolicy", applyGameplayPolicy)
    hook.Add("InitPostEntity", "LOD_VRServerStartup", function()
        -- Addon initialization/config can run after gamemode Initialize. Apply
        -- the same policy again once every addon and its convars have loaded.
        applyGameplayPolicy()
        local ready, reason = VR:ServerReady()
        SetGlobalBool("LOD_VRServerReady", ready)
        SetGlobalString("LOD_VRAddonRevision", ready and VR.AddonRevision or "")
        if not ready then
            print("[LOD VR] Server runtime unavailable: " .. reason)
            return
        end
        -- The upstream loader distributes Lua. These small model/material files
        -- also need distribution for clients without a local addon subscription.
        for _, name in ipairs(VR.ContentFiles) do resource.AddSingleFile(name) end
        print("[LOD VR] Server runtime ready: vrmod-x64 " .. VR.AddonRevision
            .. ", " .. #VR.Channels .. " channels, " .. #VR.ContentFiles .. " content files")
    end)
    concommand.Add("lod_vr_status", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local ready, reason = VR:ServerReady()
        print("[LOD VR] Server VRMod: " .. (ready and "available " .. VR.AddonRevision or "unavailable — " .. reason))
    end)
end
