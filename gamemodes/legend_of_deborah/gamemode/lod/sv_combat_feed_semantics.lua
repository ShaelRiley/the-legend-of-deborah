LOD = LOD or {}

local Rolls = LOD.CombatRolls
if not Rolls then return end
if Rolls.LODSemanticCombatFeedFormatterInstalled then return end

local MESSAGE_LIMIT = 512

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
            return clean(progression:PlayerCharacterText(ent), 192)
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

local function damageText(amount)
    local value = math.max(0, tonumber(amount) or 0)
    if math.abs(value - math.floor(value + 0.5)) < 0.05 then
        return tostring(math.floor(value + 0.5))
    end
    return string.format("%.1f", value)
end

-- Combat feed presentation adapter. Preserve the full persistent player + Hero
-- identity and all semantic fields. If an unusually verbose diagnostic would push
-- the packet over the bounded feed budget, drop only that optional detail first.
function Rolls:_DamageEventText(source, formula, amount, target, detail, fallbackSource, fallbackTarget, damageSource)
    local prefix = string.format("%s dealt %s (%s)",
        entityDisplayName(source, fallbackSource), clean(formula, 48), damageText(amount))
    local suffix = string.format(" damage to %s, via %s",
        entityDisplayName(target, fallbackTarget), clean(damageSource or "unknown source", 96))
    local detailText = detail and detail ~= "" and (" " .. clean(detail, 192)) or ""
    local detailBudget = MESSAGE_LIMIT - #prefix - #suffix
    if #detailText > math.max(0, detailBudget) then detailText = "" end
    return prefix .. detailText .. suffix
end

-- The old 180-byte presentation cap could cut the character identity or source
-- even though net.WriteString itself is not the constraint. Keep a finite 512-byte
-- event packet while allowing the authored full semantic sentence to arrive.
function Rolls:_Send(ply, category, text)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    net.Start("LOD_CombatRoll")
    net.WriteUInt(math.Clamp(category or 0, 0, 3), 2)
    net.WriteString(string.sub(tostring(text or "ROLL"), 1, MESSAGE_LIMIT))
    net.Send(ply)
    self.Stats.feedMessages = (self.Stats.feedMessages or 0) + 1
end

Rolls.LODSemanticCombatFeedFormatterInstalled = true
