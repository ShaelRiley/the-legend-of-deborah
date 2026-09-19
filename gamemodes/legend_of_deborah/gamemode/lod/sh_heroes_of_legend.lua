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
    if entry.highestLevel then
        return string.format("%s reached Level %d — %d damsels, %d cash bags",membersStr,entry.highestLevel,count,entry.cashRecovered or 0)
    end
    return string.format("%s cleared %d dungeons", membersStr, count)
end

function Heroes:IsValidEntry(entry)
    if type(entry) ~= "table" then return false end
    if type(entry.runId) ~= "string" or entry.runId == "" then return false end
    local rescues = tonumber(entry.rescueCount)
    if not rescues or rescues < 0 or math.floor(rescues) ~= rescues then return false end
    for _,field in ipairs({"highestLevel","cashRecovered"}) do
        local v=entry[field]
        if v~=nil and (type(v)~="number" or v~=v or v==math.huge or v%1~=0 or v<(field=="highestLevel" and 1 or 0)) then return false end
    end
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

    local rA = tonumber(a.highestLevel) or (tonumber(a.rescueCount) or 0)+1
    local rB = tonumber(b.highestLevel) or (tonumber(b.rescueCount) or 0)+1
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
