LOD = LOD or {}
LOD.HeroesOfLegend = LOD.HeroesOfLegend or {}

local Heroes = LOD.HeroesOfLegend
Heroes.MAX_ENTRIES = 10

function Heroes:FormatEntry(entry)
    if not entry then return "" end
    local membersStr = ""
    if type(entry.partyMembers) == "table" then
        membersStr = table.concat(entry.partyMembers, ", ")
    else
        membersStr = tostring(entry.partyMembers or "")
    end
    local count = tonumber(entry.rescueCount) or 0
    return string.format("%s rescued Deborah %d times", membersStr, count)
end

function Heroes:IsValidEntry(entry)
    if type(entry) ~= "table" then return false end
    if type(entry.runId) ~= "string" or entry.runId == "" then return false end
    local rescues = tonumber(entry.rescueCount)
    if not rescues or rescues < 0 or math.floor(rescues) ~= rescues then return false end
    local seq = tonumber(entry.completionOrder)
    if not seq or seq < 1 or math.floor(seq) ~= seq then return false end
    if type(entry.partyMembers) ~= "table" or #entry.partyMembers == 0 then return false end
    for _, member in ipairs(entry.partyMembers) do
        if type(member) ~= "string" or member == "" then return false end
    end
    return true
end

function Heroes:CompareEntries(a, b)
    local validA = self:IsValidEntry(a)
    local validB = self:IsValidEntry(b)
    if validA ~= validB then
        return validA
    end
    if not validA then return false end

    local rA = tonumber(a.rescueCount) or 0
    local rB = tonumber(b.rescueCount) or 0
    if rA ~= rB then
        return rA > rB
    end
    local cA = tonumber(a.completionOrder) or 0
    local cB = tonumber(b.completionOrder) or 0
    return cA < cB
end

function Heroes:SortEntries(entries)
    if not entries then return {} end
    table.sort(entries, function(a, b)
        return self:CompareEntries(a, b)
    end)
    return entries
end
