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

-- Include the actual arithmetic subtotal even when damage is scaled, resisted,
-- or clamped by the target's remaining HP. This does not reroll or resolve damage.
function Log:RollBreakdown(contract)
    local resolution = contract.feedResolution
    contract = resolution and resolution.resolvedContract or contract
    local subtotal = tonumber(contract.bonus) or 0
    for i, value in ipairs(contract.values or {}) do
        subtotal = subtotal + (tonumber(contract.contributions and contract.contributions[i]) or value)
    end
    local text = self:RollDetail(contract)
    local bonus = tonumber(contract.bonus) or 0
    if bonus ~= 0 then text = text .. string.format(" %s %g bonus", bonus < 0 and "-" or "+", math.abs(bonus)) end
    text = text .. string.format(" = %g rolled", subtotal)
    if contract.blastProofSuppressed then text = text .. "; BLAST-PROOF ended one chain" end
    if resolution and (resolution.resistance or 0) > 0 and resolution.reduced then
        local reduced, sum = {}, bonus
        for i, value in ipairs(resolution.reduced) do reduced[i] = tostring(value); sum = sum + value end
        text = text .. string.format("; CON -%g/die: %s = %g", resolution.resistance,
            table.concat(reduced, " + "), sum)
    end
    if resolution and math.abs(resolution.total - subtotal) > 0.001 then
        text = text .. string.format("; resolved %g", resolution.total)
    end
    return text
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
    pattern('%b[]','prose',1)
    local rollStart = text:find('[rolls ',1,true) or text:find('; rolls ',1,true)
        or text:find('; boom ',1,true)
    if rollStart then
        local rollEnd = text:find(';',rollStart+2,true) or text:find(']',rollStart,true) or #text
        mark(rollStart+7,rollEnd-1,'dice',3)
    end
    pattern('= [%d%.]+ rolled','total',4)
    pattern('resolved [%d%.]+','total',4)
    pattern('[><=]+','continuation',4)
    pattern('%f[%a]Magic%f[%A]','magic',3)
    for _, word in ipairs({'APPLIED','REFRESHED','EXTENDED','HELD','MUTED','IMMOLATED','POISONED','BLEEDING','CLUMSY','RECKLESS','INTIMIDATED'}) do pattern(word,'status',3) end
    for _, word in ipairs({'RESISTED','IMMUNE','RESISTANCE'}) do pattern(word,'resist',3) end
    for _, word in ipairs({'ENDED','RESTORED','GAINED'}) do pattern(word,'resource',3) end
    -- Longest full identity first, then standalone Steam names. Exact server names
    -- are persisted with the record; reconnects and renames cannot recolor history.
    for _, identity in ipairs(identities or {}) do
        local name, pos = identity.text, 1
        while name and name ~= '' and pos <= #text do
            local first,last = text:find(name,pos,true)
            if not first then break end
            -- Standalone nicknames must be whole names, not substrings of words
            -- or other users' longer identities.
            local before, after = text:sub(first-1,first-1), text:sub(last+1,last+1)
            local bounded = not identity.standalone or
                (not before:match('[%w_]') and not after:match('[%w_]'))
            if bounded and (priority[first] or 0) < 10 then
                mark(first,last,'identity',10)
                if identity.characterStart then
                    mark(first + identity.characterStart - 5, first + identity.characterStart - 2,'prose',11)
                    mark(first + identity.characterStart - 1,last,'character',11)
                end
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
