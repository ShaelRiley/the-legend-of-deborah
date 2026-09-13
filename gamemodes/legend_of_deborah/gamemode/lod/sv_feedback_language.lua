LOD = LOD or {}
local P = LOD.RPGPresentation
local ACK = "LOD_FeedbackAck"
util.AddNetworkString(ACK)
P.FeedbackPending = P.FeedbackPending or setmetatable({}, {__mode = "k"})
P.FeedbackLimits = P.FeedbackLimits or setmetatable({}, {__mode = "k"})

function P:FeedbackLog(event, fields)
    local log = LOD.RPGTestLog
    if log and log.Write then log:Write(event, fields) end
end

function P:FeedbackPlayer(actor)
    if IsValid(actor) and actor:IsPlayer() then return actor end
    if isstring(actor) then
        for _, ply in ipairs(player.GetAll()) do
            if LOD.RunManager:IdentityOf(ply) == actor then return ply end
        end
    end
end

function P:FeedbackName(actor)
    if IsValid(actor) then
        if actor:IsPlayer() then return actor:Nick() end
        return tostring(actor.LODConfig and actor.LODConfig.name or actor.LODArchetypeId or actor:GetClass())
    end
    return "actor"
end

-- Called only after an authoritative outcome. Duplicate notices can be restrained
-- without suppressing the corresponding diagnostic outcome.
function P:_Event(actor, family, text, fields, cooldownKey)
    local ply = self:FeedbackPlayer(actor)
    if not ply then return end
    fields = table.Copy(fields or {})
    fields.event = fields.event or family
    fields.player = ply:EntIndex()
    if cooldownKey then
        local limits = self.FeedbackLimits[ply] or {}
        self.FeedbackLimits[ply] = limits
        local now = CurTime()
        if (limits[cooldownKey] or 0) > now then
            fields.reason = "notice_throttled"
            self:FeedbackLog("FEEDBACK_SUPPRESSED", fields)
            return
        end
        -- Expire keys on event traffic; never grow a target/status cache forever.
        for key, untilAt in pairs(limits) do if untilAt <= now then limits[key] = nil end end
        limits[cooldownKey] = now + 1.5
    end
    local grammar = LOD.FeedbackLanguage[family] or LOD.FeedbackLanguage.routine
    local prefix = grammar.label ~= "" and ("[" .. grammar.label .. "] ") or ""
    if LOD.CombatRolls then LOD.CombatRolls:_Send(ply, 3, prefix .. text, family, fields) end
end

function P:Event(...)
    local ok, err = pcall(self._Event, self, ...)
    if not ok then ErrorNoHalt("[LOD:FEEDBACK] " .. tostring(err) .. "\n") end
end

function P:TrackFeedback(ply, serial, family, text, fields)
    local cv = GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() then return false end
    local pending = self.FeedbackPending[ply] or {}
    self.FeedbackPending[ply] = pending
    local count = 0
    for id, entry in pairs(pending) do
        if CurTime() - entry.at > 15 then pending[id] = nil else count = count + 1 end
    end
    -- Bound outstanding diagnostics even if a client never acknowledges.
    if count >= 512 then self.FeedbackPending[ply] = {}; pending = self.FeedbackPending[ply] end
    pending[serial] = {at = CurTime(), family = family, received = false, drawn = false}
    local event = table.Copy(fields or {})
    event.serial, event.family, event.text, event.player = serial, family, text, ply:EntIndex()
    self:FeedbackLog("FEEDBACK_DISPATCH", event)
    return true
end

net.Receive(ACK, function(_, ply)
    local serial, stage, sound = net.ReadUInt(32), net.ReadUInt(2), net.ReadBool()
    local entry = P.FeedbackPending[ply] and P.FeedbackPending[ply][serial]
    if not entry or CurTime() - entry.at > 15 or stage > 1 then return end
    local key = stage == 0 and "received" or "drawn"
    if entry[key] then return end
    entry[key] = true
    P:FeedbackLog("FEEDBACK_CLIENT_ACK", {player = ply:EntIndex(), serial = serial,
        family = entry.family, stage = key, sound_requested = sound,
        history_retained = stage == 0, latency = CurTime() - entry.at})
    if entry.received and entry.drawn then P.FeedbackPending[ply][serial] = nil end
end)
