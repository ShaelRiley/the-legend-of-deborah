LOD = LOD or {}

local Rolls = LOD.CombatRolls
if not Rolls then return end
if Rolls.LODSemanticCombatFeedFormatterInstalled then return end

local MESSAGE_LIMIT = LOD.DieLogger.MaxText

local function clean(value, limit)
    local text = tostring(value or "Unknown")
    text = string.gsub(text, "[%c]", "")
    text = string.Trim(text)
    if text == "" then text = "Unknown" end
    if limit and #text > limit then text = string.sub(text, 1, limit) end
    return text
end

local function titleName(value)
    local text = string.lower(clean(value, 96))
    return (string.gsub(text, "(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. rest
    end))
end

local function entityDisplayName(ent, fallback)
    if IsValid(ent) and ent:IsPlayer() then
        local progression = LOD.CharacterProgressionSystem
        if progression and progression.PlayerCharacterText then
            local ok, name = pcall(progression.PlayerCharacterText, progression, ent)
            if ok then return clean(name, 192) end
        end
        return clean(ent:Nick(), 96)
    end
    if IsValid(ent) and ent.LODHostile then
        local configured = ent.LODConfig and (ent.LODConfig.name or ent.LODConfig.label)
        return titleName(configured or ent.LODArchetypeId or fallback or "Hostile")
    end
    if IsValid(ent) then return titleName(ent:GetClass()) end
    return titleName(fallback or "Unknown")
end

function Rolls:EntityDisplayName(ent, fallback)
    return entityDisplayName(ent, fallback)
end

local function damageText(amount)
    local value = math.max(0, tonumber(amount) or 0)
    if math.abs(value - math.floor(value + 0.5)) < 0.05 then
        return tostring(math.floor(value + 0.5))
    end
    return string.format("%.1f", value)
end

-- DIE-LOGGER sentence authority. Roll detail is mandatory, including long chains.
-- Name/source budgets plus 3 KiB of dice detail fit inside the 4 KiB transport.
function Rolls:_DamageEventText(source, formula, amount, target, detail, fallbackSource, fallbackTarget, damageSource)
    local prefix = string.format("%s dealt %s (%s)",
        entityDisplayName(source, fallbackSource), clean(formula, 48), damageText(amount))
    local suffix = string.format(" damage to %s, via %s",
        entityDisplayName(target, fallbackTarget), clean(damageSource or "unknown source", 96))
    local detailText = detail and detail ~= "" and (" " .. clean(detail, 3072)) or ""
    return prefix .. detailText .. suffix
end

-- One bounded text + semantic-span record for live HUD, history and telemetry.
local function send(self, ply, category, text, family, fields)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    text = string.sub(tostring(text or "ROLL"), 1, MESSAGE_LIMIT)
    family = LOD.FeedbackLanguage and LOD.FeedbackLanguage[family] and family or "routine"
    self.FeedbackSerial = ((self.FeedbackSerial or 0) + 1) % 4294967296
    local serial = self.FeedbackSerial
    local identities = {}
    for _, who in ipairs(player.GetAll()) do
        local full = entityDisplayName(who)
        local nick = clean(who:Nick(), 192)
        local connector = nick .. " as "
        identities[#identities + 1] = {text = full,
            characterStart = full:sub(1, #connector) == connector and #connector + 1 or nil}
    end
    table.sort(identities, function(a,b) return #a.text > #b.text end)
    for _, who in ipairs(player.GetAll()) do
        identities[#identities + 1] = {text = clean(who:Nick(), 96), standalone = true}
    end
    local segments = LOD.DieLogger:Segments(text, family, identities)
    fields = table.Copy(fields or {})
    fields.segments = segments
    fields.cue = LOD.AdventureCueForEvent and LOD.AdventureCueForEvent(fields) or 0
    fields.cueVariant = math.Clamp(tonumber(fields.cardIndex) or 0, 0, 3)
    local presentation = LOD.RPGPresentation
    local tracked = false
    if presentation and presentation.TrackFeedback then
        local ok, result = pcall(presentation.TrackFeedback, presentation, ply, serial, family, text, fields)
        tracked = ok and result == true
        if not ok then ErrorNoHalt("[LOD:FEEDBACK] " .. tostring(result) .. "\n") end
    end
    net.Start("LOD_CombatRoll")
    net.WriteUInt(math.Clamp(category or 0, 0, 3), 2)
    net.WriteString(text)
    net.WriteUInt(serial, 32)
    net.WriteString(family)
    net.WriteBool(tracked)
    net.WriteString(util.TableToJSON(segments))
    net.WriteUInt(fields.cue, 4)
    net.WriteUInt(fields.cueVariant, 2)
    if family=="awareness" then net.WriteVector(fields.position or ply:GetPos()) end
    net.Send(ply)
    self.Stats.feedMessages = (self.Stats.feedMessages or 0) + 1
end

function Rolls:_Send(...)
    local ok, err = pcall(send, self, ...)
    if not ok then ErrorNoHalt("[LOD:DIE-LOGGER] " .. tostring(err) .. "\n") end
end

Rolls.LODSemanticCombatFeedFormatterInstalled = true
