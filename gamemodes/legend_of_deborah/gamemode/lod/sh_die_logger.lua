LOD = LOD or {}
LOD.DieLogger = LOD.DieLogger or {}
local Log = LOD.DieLogger
Log.MaxText = 4096

-- Formatting observes actual sampled values. '+' starts another base die;
-- '>' exclusively means a continuation when the contract carries chain starts.
function Log:RollDetail(contract)
    local out, starts = {}, {}
    for _, i in ipairs(contract.chainStarts or {}) do starts[i] = true end
    for i, value in ipairs(contract.values or {}) do
        if i > 1 then out[#out + 1] = starts[i] and " + " or
            (contract.chainStarts or (contract.baseDice or 1) == 1) and " > " or ", " end
        out[#out + 1] = tostring(value)
        local threshold = contract.thresholds and contract.thresholds[i]
        if threshold then out[#out + 1] = "@" .. tostring(threshold) .. "+" end
        local contribution = contract.contributions and contract.contributions[i]
        if contribution and contribution ~= value then out[#out + 1] = "=>" .. tostring(contribution) end
    end
    return table.concat(out)
end

-- One server-authored span record is used by the live tail and persisted history.
-- Identity ranges have precedence over punctuation/number grammar: a numeric name
-- or a name containing ' as ' cannot become a die or an event accidentally.
function Log:Segments(text, family, identities)
    text = tostring(text or "")
    local roles, priority = {}, {}
    local function mark(a, b, role, rank)
        if not a or not b then return end
        for i = a, b do
            if (priority[i] or 0) < rank then roles[i], priority[i] = role, rank end
        end
    end
    local function pattern(p, role, rank)
        local pos = 1
        while pos <= #text do
            local a, b = text:find(p, pos)
            if not a then break end
            mark(a,b,role,rank); pos = b + 1
        end
    end
    pattern('^%b[]', family or 'routine', 2)
    local a,b = text:find(' dealt ',1,true)
    if a then
        mark(1,a-1,'identity',1)
        local c,d = text:find(' damage to ',b+1,true)
        local e,f
        if c then e,f = text:find(', via ',d+1,true) end
        if e then mark(d+1,e-1,'recipient',1); mark(f+1,#text,'source',1) end
    else
        local colon = text:find(': ',1,true)
        if colon then
            local start = text:find('] ',1,true)
            mark(start and start+2 or 1,colon-1,'identity',1)
        end
    end
    pattern('%d+d%d+!?[%+%-]?%d*','dice',3)
    pattern('[%+%-]?%d+%.?%d*','total',2)
    pattern('[><=]+','continuation',3)
    pattern('%f[%a]Magic%f[%A]','magic',3)
    for _, word in ipairs({'APPLIED','REFRESHED','EXTENDED','HELD','MUTED','IMMOLATED','POISONED'}) do pattern(word,'status',3) end
    for _, word in ipairs({'RESISTED','IMMUNE','RESISTANCE'}) do pattern(word,'resist',3) end
    for _, word in ipairs({'ENDED','RESTORED','GAINED'}) do pattern(word,'resource',3) end
    -- Longest full identity first, then standalone Steam names. Exact server names
    -- are persisted with the record; reconnects and renames cannot recolor history.
    for _, identity in ipairs(identities or {}) do
        local name, pos = identity.text, 1
        while name and name ~= '' and pos <= #text do
            local first,last = text:find(name,pos,true)
            if not first then break end
            mark(first,last,'identity',10)
            if identity.characterStart then
                mark(first + identity.characterStart - 5, first + identity.characterStart - 2,'prose',11)
                mark(first + identity.characterStart - 1,last,'character',11)
            end
            pos = last + 1
        end
    end
    local result, start, role = {}, 1, roles[1] or 'prose'
    for i = 2, #text + 1 do
        local nextRole = roles[i] or 'prose'
        if nextRole ~= role or i > #text then
            result[#result + 1] = {text = text:sub(start,i-1),role = role}
            start,role = i,nextRole
        end
    end
    return result
end
function Log:ValidSegments(segments, text)
    if type(segments) ~= 'table' or #segments > self.MaxText then return false end
    local parts = {}
    for _, span in ipairs(segments) do
        if type(span) ~= 'table' or type(span.text) ~= 'string' or type(span.role) ~= 'string' then return false end
        parts[#parts + 1] = span.text
    end
    return table.concat(parts) == text
end
