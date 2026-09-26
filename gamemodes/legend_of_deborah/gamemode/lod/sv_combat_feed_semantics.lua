LOD = LOD or {}

local Rolls = LOD.CombatRolls
if not Rolls then return end
if Rolls.LODSemanticCombatFeedFormatterInstalled then return end

local MESSAGE_LIMIT = LOD.DieLogger.MaxText
-- Match the information-system cell progression: max(1, WIS modifier) cells.
Rolls.InformationTuning={minimumCells=1,defaultCellSize=384}
function Rolls:InformationRadius(observer)
    local rules=LOD.RPGAbilityRules
    local state=rules and rules.ProgressionState and rules:ProgressionState(observer)
    local derived=state and state.derivedStats
    local modifier=derived and tonumber(derived.wisMod)
        or math.floor(((state and state.effectiveAbilities and state.effectiveAbilities.wis or 10)-10)/2)
    local cell=LOD.Config and LOD.Config.Maze and LOD.Config.Maze.CellSize or self.InformationTuning.defaultCellSize
    return math.max(self.InformationTuning.minimumCells,modifier)*cell
end


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
        local run = LOD.RunManager
        if run and run.IsSoldierControl and run:IsSoldierControl(ent) then
            return clean(ent:Nick(), 96) .. " as Soldier"
        end
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
    local prefix = string.format("(%s) DAMAGE — %s → %s, via %s; %s",
        damageText(amount), entityDisplayName(source, fallbackSource), entityDisplayName(target, fallbackTarget),
        clean(damageSource or "unknown source", 96), clean(formula, 48))
    local detailText = detail and detail ~= "" and (" " .. clean(detail, 3072)) or ""
    return prefix .. detailText
end

-- One synchronous canonical event, one serial and one frozen semantic sentence.
-- The first argument may be one actor or a dense list of participating actors.
-- Players in that list receive their outcome regardless of distance/alive state;
-- nearby living observers use their OWN WIS radius around the actual actors.
-- NPC-only resolutions therefore have a route, without scanning the world.
local publicFamilies = {routine=true, damage=true, roll=true, status=true,
    clear=true, resist=true, weakness=true, proc=true}
local function send(self, actors, category, text, family, fields)
    if IsValid(actors) then actors = {actors} end
    if type(actors) ~= "table" then return end
    local origins, direct = {}, {}
    for _, actor in ipairs(actors) do
        if IsValid(actor) then
            origins[#origins + 1] = actor
            if actor:IsPlayer() then direct[actor] = true end
        end
    end
    if #origins == 0 then return end
    local all = player.GetAll()
    local recipients, seen = {}, {}
    local function admit(who, primary)
        if not seen[who] then
            seen[who] = true
            recipients[#recipients + 1] = {actor=who, primary=primary}
        end
    end
    -- Preserve participant order; each primary owns its diagnostic ACK/cue.
    for _, actor in ipairs(origins) do if direct[actor] then admit(actor, true) end end
    family = LOD.FeedbackLanguage and LOD.FeedbackLanguage[family] and family or "routine"
    if publicFamilies[family] then
        for _, observer in ipairs(all) do
            if IsValid(observer) and not seen[observer] and observer:Alive() then
                local radius = self:InformationRadius(observer)
                for _, origin in ipairs(origins) do
                    if observer:GetPos():DistToSqr(origin:GetPos()) <= radius * radius then
                        admit(observer, false); break
                    end
                end
            end
        end
    end
    if #recipients == 0 then return end
    text = string.sub(tostring(text or "ROLL"), 1, MESSAGE_LIMIT)
    self.FeedbackSerial = ((self.FeedbackSerial or 0) + 1) % 4294967296
    local serial = self.FeedbackSerial
    local identities = {}
    for _, who in ipairs(all) do
        local full = entityDisplayName(who)
        local nick = clean(who:Nick(), 192)
        local connector = nick .. " as "
        identities[#identities + 1] = {text = full,
            characterStart = full:sub(1, #connector) == connector and #connector + 1 or nil}
    end
    table.sort(identities, function(a,b) return #a.text > #b.text end)
    for _, who in ipairs(all) do
        identities[#identities + 1] = {text = clean(who:Nick(), 96), standalone = true}
    end
    local segments = LOD.DieLogger:Segments(text, family, identities)
    local encoded = util.TableToJSON(segments)
    fields = table.Copy(fields or {})
    fields.segments = segments
    fields.cue = LOD.AdventureCueForEvent and LOD.AdventureCueForEvent(fields) or 0
    fields.cueVariant = math.Clamp(tonumber(fields.cardIndex) or 0, 0, 3)
    local presentation = LOD.RPGPresentation
    for _, recipient in ipairs(recipients) do
        local ply, tracked = recipient.actor, false
        if recipient.primary and presentation and presentation.TrackFeedback then
            local ok, result = pcall(presentation.TrackFeedback, presentation, ply, serial, family, text, fields)
            tracked = ok and result == true
            if not ok then ErrorNoHalt("[LOD:FEEDBACK] " .. tostring(result) .. "\n") end
        end
        net.Start("LOD_CombatRoll")
        net.WriteUInt(math.Clamp(category or 0, 0, 3), 2)
        net.WriteString(text); net.WriteUInt(serial,32); net.WriteString(family)
        net.WriteBool(tracked); net.WriteString(encoded)
        net.WriteUInt(recipient.primary and fields.cue or 0,4); net.WriteUInt(fields.cueVariant,2)
        if family=="awareness" then net.WriteVector(fields.position or origins[1]:GetPos()) end
        net.Send(ply)
    end
    self.Stats.feedMessages = (self.Stats.feedMessages or 0) + 1
    return serial
end

function Rolls:_Send(...)
    local ok, result = pcall(send, self, ...)
    if not ok then ErrorNoHalt("[LOD:DIE-LOGGER] " .. tostring(result) .. "\n"); return end
    return result
end

Rolls.LODSemanticCombatFeedFormatterInstalled = true
