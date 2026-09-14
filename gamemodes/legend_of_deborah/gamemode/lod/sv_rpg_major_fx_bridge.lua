if CLIENT then return end

LOD = LOD or {}
LOD.RPGMajorFXBridge = LOD.RPGMajorFXBridge or {}

local Bridge = LOD.RPGMajorFXBridge
local NET_NAME = "LOD_RPGMajorFX"
local ACK_NAME = "LOD_RPGMajorFXAck"
local diversionNext = setmetatable({}, {__mode = "k"})
local pending = setmetatable({}, {__mode = "k"})

util.AddNetworkString(NET_NAME)
util.AddNetworkString(ACK_NAME)

local function logEvent(name, fields)
    local log = LOD.RPGTestLog
    if log and log.Write then log:Write(name, fields or {}) end
end

local function install()
    local presentation = LOD.RPGPresentation
    if not presentation then return false end
    if presentation.MajorFXTransportInstalled then return true end

    presentation.MajorFXTransportInstalled = true

    -- Use a dedicated transport for major RPG presentation. The previous server
    -- events were firing correctly, as confirmed by RPG_LEVEL_UP_PRESENTATION and
    -- WIZARD_FEEDBACK_PROC logs, but the shared combat-feed receiver was not
    -- producing a reliably visible overlay. This transport has one client owner.
    local function sendFX(self, ply, kind, primary, secondary, origin, target)
        if not IsValid(ply) or not ply:IsPlayer() then return false end
        -- Continuous damage keeps its complete logger record; cap cosmetic shield
        -- packets at ten per second instead of amplifying reliable-channel bursts.
        if kind == 4 then
            if CurTime() < (diversionNext[ply] or 0) then return false end
            diversionNext[ply] = CurTime() + 0.10
        end

        self.MajorFXSerial = ((tonumber(self.MajorFXSerial) or 0) + 1) % 65536
        local serial = self.MajorFXSerial

        local records = pending[ply] or {}
        local count = 0
        for id, record in pairs(records) do
            if CurTime() - record.at > 15 then records[id] = nil else count = count + 1 end
        end
        if count >= 64 then records = {} end
        pending[ply] = records

        net.Start(NET_NAME)
        net.WriteUInt(serial, 16)
        net.WriteUInt(math.Clamp(math.floor(tonumber(kind) or 0), 0, 7), 3)
        net.WriteString(tostring(primary or ""))
        net.WriteString(tostring(secondary or ""))
        if kind == 1 or kind == 4 then
            net.WriteVector(origin or ply:GetShootPos())
            net.WriteVector(target or origin or ply:GetShootPos())
        end
        net.Send(ply)
        records[serial] = {kind=kind, at=CurTime()}

        logEvent("RPG_MAJOR_FX_DISPATCH", {player = string.format("player:%s#%d", tostring(ply:Nick()), ply:EntIndex()),
            serial = serial, kind = kind, primary = tostring(primary or ""), secondary = tostring(secondary or "")})

        return true
    end

    function presentation:SendFX(...)
        local ok, result = pcall(sendFX, self, ...)
        if not ok then ErrorNoHalt("[LOD:RPG-MAJOR-FX] " .. tostring(result) .. "\n") end
        return ok and result or false
    end

    return true
end

net.Receive(ACK_NAME, function(_, ply)
    if not IsValid(ply) then return end
    local serial = net.ReadUInt(16)
    local kind = net.ReadUInt(3)
    local triggered = net.ReadBool()
    local records = pending[ply]
    local record = records and records[serial]
    if not record or record.kind ~= kind or CurTime() - record.at > 15 then return end
    records[serial] = nil
    logEvent("RPG_MAJOR_FX_CLIENT_ACK", {
        player = string.format("player:%s#%d", tostring(ply:Nick()), ply:EntIndex()),
        serial = serial,
        kind = kind,
        triggered = triggered
    })
end)
hook.Add("PlayerDisconnected", "LOD_RPGMajorFXCleanup", function(ply)
    pending[ply], diversionNext[ply] = nil, nil
end)

install()
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
