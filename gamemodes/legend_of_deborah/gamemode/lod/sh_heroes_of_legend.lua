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
        membersStr = tostring(entry.partyMembers or "Unknown Heroes")
    end
    local count = tonumber(entry.rescueCount) or 0
    local unitStr = (count == 1) and "time" or "times"
    return string.format("%s — Rescued Deborah %d %s", membersStr, count, unitStr)
end

function Heroes:CompareEntries(a, b)
    local rA = tonumber(a and a.rescueCount) or 0
    local rB = tonumber(b and b.rescueCount) or 0
    if rA ~= rB then
        return rA > rB
    end
    local cA = tonumber(a and a.completionOrder) or 0
    local cB = tonumber(b and b.completionOrder) or 0
    return cA < cB
end

function Heroes:SortEntries(entries)
    if not entries then return {} end
    table.sort(entries, function(a, b)
        return self:CompareEntries(a, b)
    end)
    return entries
end
