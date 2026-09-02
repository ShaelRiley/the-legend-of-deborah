if CLIENT then return end

LOD = LOD or {}
LOD.RPGMajorFXBridge = LOD.RPGMajorFXBridge or {}

local Bridge = LOD.RPGMajorFXBridge
local NET_NAME = "LOD_RPGMajorFX"
local ACK_NAME = "LOD_RPGMajorFXAck"

util.AddNetworkString(NET_NAME)
util.AddNetworkString(ACK_NAME)

local function logEvent(name, fields)
    local log = LOD.RPGTestLog
    if log and log.Write then log:Write(name, fields or {}) end
end

local function install()
    local presentation = LOD.RPGPresentation
    if not presentation or not presentation.SendFX then return false end
    if presentation.MajorFXTransportInstalled then return true end

    presentation.MajorFXTransportInstalled = true
    Bridge.LegacySendFX = presentation.SendFX

    -- Use a dedicated transport for major RPG presentation. The previous server
    -- events were firing correctly, as confirmed by RPG_LEVEL_UP_PRESENTATION and
    -- WIZARD_FEEDBACK_PROC logs, but the shared combat-feed receiver was not
    -- producing a reliably visible overlay. This transport has one client owner.
    function presentation:SendFX(ply, kind, primary, secondary)
        if not IsValid(ply) or not ply:IsPlayer() then return false end

        self.MajorFXSerial = ((tonumber(self.MajorFXSerial) or 0) + 1) % 65536
        local serial = self.MajorFXSerial

        net.Start(NET_NAME)
        net.WriteUInt(serial, 16)
        net.WriteUInt(math.Clamp(math.floor(tonumber(kind) or 0), 0, 7), 3)
        net.WriteString(tostring(primary or ""))
        net.WriteString(tostring(secondary or ""))
        net.Send(ply)

        return true
    end

    return true
end

net.Receive(ACK_NAME, function(_, ply)
    if not IsValid(ply) then return end
    local serial = net.ReadUInt(16)
    local kind = net.ReadUInt(3)
    logEvent("RPG_MAJOR_FX_CLIENT_ACK", {
        player = string.format("player:%s#%d", tostring(ply:Nick()), ply:EntIndex()),
        serial = serial,
        kind = kind
    })
end)

timer.Simple(0, install)
hook.Add("InitPostEntity", "LOD_RPGMajorFXBridgeInstall", install)

concommand.Add("lod_rpg_major_fx_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local ok = install() and LOD.RPGPresentation
        and LOD.RPGPresentation.MajorFXTransportInstalled == true
    local line = "RPG major FX transport " .. (ok and "PASS" or "FAILED")
    print("[LOD:RPG-MAJOR-FX] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
