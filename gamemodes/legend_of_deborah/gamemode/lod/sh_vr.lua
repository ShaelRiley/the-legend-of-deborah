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

VR.IdleRevision = "deborah-vr-idle-20261007-r2"
VR.SourceIdentity = nil -- Lua refresh invalidates the one-time mounted-byte check.
function VR:WorkState()
    local runtime = vrmod and vrmod.LODIdle
    local out = runtime and runtime:Snapshot() or {available = false, idle = false}
    if CLIENT and hook.GetTable then
        local think = hook.GetTable().Think or {}
        out.adapter_think = think.LOD_VRTetrisStick ~= nil
        if out.adapter_think then out.idle = false end
    end
    if not self.SourceIdentity then
        local identity = {checked = 0, bridge_checked = 0, missing = 0, mismatches = 0}
        local manifest = file.Read("legend_of_deborah/dev_vr_sources.txt", "DATA") or ""
        local version, count = manifest:match("^(%S+) (%d+)\n")
        for line in manifest:gmatch("[^\r\n]+") do
            local expected, path = line:match("^(%x+)%s+(.+)$")
            local bridge = false
            if not expected then
                expected, path = line:match("^bridge (%x+)%s+(.+)$")
                bridge = expected ~= nil
            end
            if expected and #expected == 64 then
                local bytes = file.Read(path, "GAME")
                if not bytes then identity.missing = identity.missing + 1
                else
                    local key = bridge and "bridge_checked" or "checked"
                    identity[key] = identity[key] + 1
                    if util.SHA256(bytes) ~= expected then identity.mismatches = identity.mismatches + 1 end
                end
            end
        end
        identity.verified = runtime ~= nil and runtime.version == self.IdleRevision
            and version == self.IdleRevision and tonumber(count) == 139
            and identity.checked == 139 and identity.bridge_checked == 2
            and identity.missing == 0 and identity.mismatches == 0
        self.SourceIdentity = identity
    end
    out.source = self.SourceIdentity
    return out
end
function VR:PrintWorkState()
    local state = self:WorkState()
    print("[LOD VR] Work: idle=" .. tostring(state.idle) .. " players=" .. tostring(state.players or 0)
        .. " hooks=" .. tostring(state.runtime_hooks or "unknown")
        .. " repeating_timers=" .. tostring(state.recurring_timers or "unknown")
        .. " pending_once=" .. tostring(state.pending_once or "unknown")
        .. " method_overrides=" .. tostring(state.method_overrides or "unknown")
        .. " native_resources=" .. tostring(state.native_resources or "unknown")
        .. " source_verified=" .. tostring(state.source.verified))
end

function VR:ServerReady()
    for _, name in ipairs(self.Channels) do
        if util.NetworkStringToID(name) == 0 then return false, "missing network channel " .. name end
    end
    if SERVER then
        if not vrmod or not vrmod.LODIdle or vrmod.LODIdle.version ~= self.IdleRevision then
            return false, "missing idle VR runtime " .. self.IdleRevision
        end
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
        VR:PrintWorkState()
    end)
end
